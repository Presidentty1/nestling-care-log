import Foundation

class OnboardingService {
    private let dataStore: DataStore
    
    init(dataStore: DataStore) {
        self.dataStore = dataStore
    }
    
    func isOnboardingCompleted() async -> Bool {
        do {
            let settings = try await dataStore.fetchAppSettings()
            return settings.onboardingCompleted
        } catch {
            return false
        }
    }
    
    func completeOnboarding() async throws {
        var settings = try await dataStore.fetchAppSettings()
        settings.onboardingCompleted = true
        try await dataStore.saveAppSettings(settings)
        
        // Analytics
        Task {
            await Analytics.shared.log("onboarding_completed", parameters: [
                "ai_data_sharing_enabled": settings.aiDataSharingEnabled,
                "notifications_enabled": settings.feedReminderEnabled || settings.diaperReminderEnabled
            ])
        }
    }
    
    func resetOnboarding() async throws {
        var settings = try await dataStore.fetchAppSettings()
        settings.onboardingCompleted = false
        try await dataStore.saveAppSettings(settings)
    }
}

