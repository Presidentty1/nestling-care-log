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
    private let appSettings: AppSettings
    
    init(dataStore: DataStore, baby: Baby, aiEnabled: Bool, appSettings: AppSettings) {
        self.dataStore = dataStore
        self.baby = baby
        self.aiEnabled = aiEnabled
        self.appSettings = appSettings
        
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
                    // Schedule nap window alert if enabled
                    await self.scheduleNapWindowAlertIfNeeded(prediction: prediction)
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
    
    /// Schedule nap window alert if enabled and permission granted
    private func scheduleNapWindowAlertIfNeeded(prediction: Prediction) async {
        guard appSettings.napWindowAlertEnabled else { return }
        
        // Check notification permission
        let permissionStatus = await NotificationPermissionManager.shared.checkPermissionStatus()
        guard permissionStatus == .authorized else { return }
        
        // Check quiet hours
        let quietHoursStart = appSettings.quietHoursStart
        let quietHoursEnd = appSettings.quietHoursEnd
        
        // Schedule the alert (15 minutes before predicted time)
        NotificationScheduler.shared.scheduleNapWindowAlert(
            predictedTime: prediction.predictedTime,
            enabled: true
        )
    }
}

