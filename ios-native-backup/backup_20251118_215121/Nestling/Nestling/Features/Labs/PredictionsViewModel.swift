import Foundation

@MainActor
class PredictionsViewModel: ObservableObject {
    @Published var nextFeedPrediction: Prediction?
    @Published var nextNapPrediction: Prediction?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let dataStore: DataStore
    private let baby: Baby
    let aiEnabled: Bool
    
    init(dataStore: DataStore, baby: Baby, aiEnabled: Bool) {
        self.dataStore = dataStore
        self.baby = baby
        self.aiEnabled = aiEnabled
        
        if aiEnabled {
            loadPredictions()
        }
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
            } catch {
                self.errorMessage = "Failed to load predictions: \(error.localizedDescription)"
            }
        }
    }
    
    func generatePrediction(type: PredictionType) {
        guard aiEnabled else { return }
        
        isLoading = true
        errorMessage = nil
        
        // Analytics
        Task {
            let babyAgeDays = Calendar.current.dateComponents([.day], from: baby.dateOfBirth, to: Date()).day ?? 0
            await Analytics.shared.log("prediction_requested", parameters: [
                "prediction_type": type.rawValue,
                "ai_enabled": aiEnabled,
                "baby_age_days": babyAgeDays
            ])
        }
        
        Task {
            do {
                let prediction = try await dataStore.generatePrediction(for: baby, type: type)
                
                switch type {
                case .nextFeed:
                    self.nextFeedPrediction = prediction
                case .nextNap:
                    self.nextNapPrediction = prediction
                }
                
                self.isLoading = false
                
                // Analytics
                Task {
                    await Analytics.shared.log("prediction_generated", parameters: [
                        "prediction_type": type.rawValue,
                        "confidence": prediction.confidence.rawValue
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

