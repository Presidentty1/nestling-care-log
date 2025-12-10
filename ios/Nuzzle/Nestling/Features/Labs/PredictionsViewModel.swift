import Foundation
import Combine

@MainActor
class PredictionsViewModel: ObservableObject {
    @Published var nextFeedPrediction: Prediction?
    @Published var nextNapPrediction: Prediction?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showUpgradePrompt = false
    @Published var dailyPredictionCount: Int = 0
    
    private let dataStore: DataStore
    private let baby: Baby
    let aiEnabled: Bool
    private let proService = ProSubscriptionService.shared
    
    // Free tier: 3 predictions per day
    private let freeDailyLimit = 3
    
    init(dataStore: DataStore, baby: Baby, aiEnabled: Bool) {
        self.dataStore = dataStore
        self.baby = baby
        self.aiEnabled = aiEnabled
        
        loadDailyPredictionCount()
        
        if aiEnabled {
            loadPredictions()
        }
    }
    
    private func loadDailyPredictionCount() {
        // Load today's prediction count from UserDefaults
        let today = Calendar.current.startOfDay(for: Date())
        let key = "prediction_count_\(baby.id)_\(today.timeIntervalSince1970)"
        dailyPredictionCount = UserDefaults.standard.integer(forKey: key)
    }
    
    private func incrementDailyPredictionCount() {
        let today = Calendar.current.startOfDay(for: Date())
        let key = "prediction_count_\(baby.id)_\(today.timeIntervalSince1970)"
        dailyPredictionCount += 1
        UserDefaults.standard.set(dailyPredictionCount, forKey: key)
    }
    
    private func canGeneratePrediction() -> Bool {
        // Pro users have unlimited predictions
        if proService.isProUser {
            return true
        }
        
        // Free users get 3 per day
        return dailyPredictionCount < freeDailyLimit
    }
    
    func loadPredictions() {
        guard aiEnabled else { return }
        
        Task {
            do {
                async let feedPrediction = dataStore.fetchPredictions(for: baby, type: .nextFeed)
                async let napPrediction = dataStore.fetchPredictions(for: baby, type: .nextNap)
                
                let (feed, nap) = try await (feedPrediction, napPrediction)
                self.nextFeedPrediction = feed
                self.nextNapPrediction = nap
                
                if let nap = nap {
                    await Analytics.shared.logPredictionShown(
                        type: PredictionType.nextNap.rawValue,
                        isPro: proService.isProUser,
                        babyId: baby.id.uuidString
                    )
                    await Analytics.shared.log("prediction_loaded", parameters: [
                        "type": PredictionType.nextNap.rawValue,
                        "confidence": nap.confidence,
                        "source": "cache"
                    ])
                }
            } catch {
                self.errorMessage = "Failed to load predictions: \(error.localizedDescription)"
            }
        }
    }
    
    func generatePrediction(type: PredictionType) {
        guard aiEnabled else { return }
        
        // Check if user can generate prediction (Pro or within free limit)
        if !canGeneratePrediction() {
            showUpgradePrompt = true
            
            // Analytics: Hit paywall
            Task {
                await Analytics.shared.log("paywall_shown", parameters: [
                    "feature": "predictions",
                    "trigger": "daily_limit_reached",
                    "daily_count": dailyPredictionCount
                ])
            }
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Analytics
        Task {
            let babyAgeDays = Calendar.current.dateComponents([.day], from: baby.dateOfBirth, to: Date()).day ?? 0
            await Analytics.shared.log("prediction_requested", parameters: [
                "prediction_type": type.rawValue,
                "ai_enabled": aiEnabled,
                "baby_age_days": babyAgeDays,
                "is_pro": proService.isProUser,
                "daily_count": dailyPredictionCount
            ])
        }
        
        Task {
            do {
                let prediction = try await dataStore.generatePrediction(for: baby, type: type)
                
                // Increment daily count for free users
                if !proService.isProUser {
                    incrementDailyPredictionCount()
                }
                
                switch type {
                case .nextFeed:
                    self.nextFeedPrediction = prediction
                case .nextNap:
                    self.nextNapPrediction = prediction
                    await Analytics.shared.logPredictionShown(
                        type: type.rawValue,
                        isPro: proService.isProUser,
                        babyId: baby.id.uuidString
                    )
                }
                
                self.isLoading = false
                
                // Analytics
                Task {
                    await Analytics.shared.log("prediction_generated", parameters: [
                        "prediction_type": type.rawValue,
                        "confidence": prediction.confidence,
                        "is_pro": proService.isProUser
                    ])
                }
            } catch {
                self.errorMessage = "Failed to generate prediction: \(error.localizedDescription)"
                self.isLoading = false
                
                // Analytics
                Task {
                    await Analytics.shared.log("error_occurred", parameters: [
                        "error_type": "prediction",
                        "context": "PredictionsViewModel"
                    ])
                }
            }
        }
    }
    
    private var babyAgeDays: Int {
        Calendar.current.dateComponents([.day], from: baby.dateOfBirth, to: Date()).day ?? 0
    }
}

