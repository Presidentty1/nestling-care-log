import SwiftUI

enum OnboardingStep {
    case welcome
    case babySetup
    case preferences
    case aiConsent
    case notificationsIntro
}

@MainActor
class OnboardingCoordinator: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var babyName: String = ""
    @Published var dateOfBirth: Date = Date()
    @Published var sex: Sex?
    @Published var preferredUnit: String = "ml"
    @Published var timeFormat24Hour: Bool = false
    @Published var aiDataSharingEnabled: Bool = true
    
    private let dataStore: DataStore
    private let onboardingService: OnboardingService
    
    init(dataStore: DataStore) {
        self.dataStore = dataStore
        self.onboardingService = OnboardingService(dataStore: dataStore)
    }
    
    func next() {
        switch currentStep {
        case .welcome:
            currentStep = .babySetup
        case .babySetup:
            currentStep = .preferences
        case .preferences:
            currentStep = .aiConsent
        case .aiConsent:
            currentStep = .notificationsIntro
        case .notificationsIntro:
            completeOnboarding()
        }
    }
    
    func skip() {
        if currentStep == .aiConsent || currentStep == .notificationsIntro {
            completeOnboarding()
        } else {
            next()
        }
    }
    
    private func completeOnboarding() {
        Task {
            do {
                // Create baby
                let baby = Baby(
                    name: babyName,
                    dateOfBirth: dateOfBirth,
                    sex: sex,
                    timezone: TimeZone.current.identifier
                )
                try await dataStore.addBaby(baby)
                
                // Save preferences
                var settings = try await dataStore.fetchAppSettings()
                settings.preferredUnit = preferredUnit
                settings.timeFormat24Hour = timeFormat24Hour
                settings.aiDataSharingEnabled = aiDataSharingEnabled
                settings.onboardingCompleted = true
                try await dataStore.saveAppSettings(settings)
                
                await MainActor.run {
                    // Onboarding completion will be handled by parent view
                }
            } catch {
                print("Error completing onboarding: \(error)")
            }
        }
    }
}

