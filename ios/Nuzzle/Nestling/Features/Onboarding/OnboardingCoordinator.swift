import SwiftUI
import Combine

enum OnboardingStep {
    case welcome
    case babySetup
    case preferences
    case aiConsent
    case notificationsIntro
    case proTrial
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
    @Published var isCompleted: Bool = false
    
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
            currentStep = .proTrial
        case .proTrial:
            completeOnboarding()
        }
    }
    
    func skip() {
        if currentStep == .aiConsent || currentStep == .notificationsIntro || currentStep == .proTrial {
            completeOnboarding()
        } else {
            next()
        }
    }
    
    func completeOnboarding() {
        Task {
            do {
                // Create baby - use default name if empty (user skipped setup)
                let finalBabyName = babyName.trimmingCharacters(in: .whitespaces).isEmpty ? "Baby" : babyName
                let baby = Baby(
                    name: finalBabyName,
                    dateOfBirth: dateOfBirth,
                    sex: sex,
                    timezone: TimeZone.current.identifier
                )
                try await dataStore.addBaby(baby)

                // Analytics: onboarding completed
                await Analytics.shared.logOnboardingCompleted(babyId: baby.id.uuidString)

                // Save preferences
                var settings = try await dataStore.fetchAppSettings()
                settings.preferredUnit = preferredUnit
                settings.timeFormat24Hour = timeFormat24Hour
                settings.aiDataSharingEnabled = aiDataSharingEnabled
                settings.onboardingCompleted = true
                try await dataStore.saveAppSettings(settings)
                
                await MainActor.run {
                    // Mark as completed so parent view can react
                    isCompleted = true
                }
            } catch {
                print("Error completing onboarding: \(error)")
            }
        }
    }
}

