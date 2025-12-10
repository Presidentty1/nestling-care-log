import SwiftUI
import Combine

enum OnboardingStep {
    case welcome
    case babyEssentials // Combines name + DOB + sex in one screen
    case goalSelection // New: "What's your biggest challenge?" - drives personalization
    case complete // Final step with quick demo
}

@MainActor
class OnboardingCoordinator: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var babyName: String = ""
    @Published var dateOfBirth: Date = Date().addingTimeInterval(-60 * 24 * 60 * 60) // Default to 60 days ago (typical newborn age)
    @Published var sex: Sex?
    @Published var selectedGoal: String? // Epic 1 AC1.2
    @Published var preferredUnit: String = detectSmartDefaultUnit()
    @Published var timeFormat24Hour: Bool = detectSmartDefaultTimeFormat()
    @Published var aiDataSharingEnabled: Bool = true
    @Published var isCompleted: Bool = false
    @Published var initialBabyState: String? = nil // "asleep" or "awake"
    @Published var showAgeWarning: Bool = false // Epic 1 AC4: Show warning for >6mo babies
    
    // Smart defaults based on locale
    private static func detectSmartDefaultUnit() -> String {
        let locale = Locale.current
        let usesMetric = locale.measurementSystem == .metric
        return usesMetric ? "ml" : "oz"
    }
    
    private static func detectSmartDefaultTimeFormat() -> Bool {
        let locale = Locale.current
        let dateFormatter = DateFormatter()
        dateFormatter.locale = locale
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        let timeString = dateFormatter.string(from: Date())
        // If time string contains AM/PM, user's locale uses 12-hour format
        return !timeString.contains("AM") && !timeString.contains("PM")
    }
    
    private let dataStore: DataStore
    private let onboardingService: OnboardingService
    
    init(dataStore: DataStore) {
        self.dataStore = dataStore
        self.onboardingService = OnboardingService(dataStore: dataStore)
    }
    
    func next() {
        switch currentStep {
        case .welcome:
            currentStep = .babyEssentials
        case .babyEssentials:
            currentStep = .goalSelection
        case .goalSelection:
            // Skip the "complete" screen - go straight to app (Epic 1 AC1: ≤3 screens)
            completeOnboarding()
        case .complete:
            completeOnboarding()
        }
    }
    
    func skip() {
        // Log skip event
        Task {
            let stepName = currentStep == .welcome ? "welcome" :
                          currentStep == .babyEssentials ? "baby_setup" :
                          currentStep == .goalSelection ? "goal_selection" : "unknown"
            await Analytics.shared.logOnboardingStepSkipped(step: stepName)
        }
        // Allow skipping any step - go straight to app
        completeOnboarding()
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

                // Save preferences (moved to post-onboarding, use smart defaults)
                var settings = try await dataStore.fetchAppSettings()
                // Auto-detect unit based on locale
                let locale = Locale.current
                let usesMetric = locale.usesMetricSystem
                settings.preferredUnit = usesMetric ? "ml" : "oz"
                settings.timeFormat24Hour = locale.identifier.contains("_US") ? false : true
                settings.aiDataSharingEnabled = aiDataSharingEnabled // Keep AI consent in onboarding
                settings.onboardingCompleted = true
                // Save user goal for personalization
                if let goal = selectedGoal {
                    settings.userGoal = goal
                }
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
    
    // Epic 2 AC2.2: Sample Data
    func loadSampleData() {
        Task {
            do {
                let sampleBaby = Baby(
                    name: "Sample Baby",
                    dateOfBirth: Date().addingTimeInterval(-86400 * 60), // 2 months old
                    sex: .female,
                    timezone: TimeZone.current.identifier
                )
                try await dataStore.addBaby(sampleBaby)
                
                // Add some sample events for today
                let now = Date()
                let events = [
                    Event(babyId: sampleBaby.id, type: .sleep, subtype: "nap", startTime: now.addingTimeInterval(-3600 * 2), endTime: now.addingTimeInterval(-3600 * 1), note: "Good nap"),
                    Event(babyId: sampleBaby.id, type: .feed, subtype: "bottle", startTime: now.addingTimeInterval(-3600 * 0.5), amount: 120, unit: "ml"),
                    Event(babyId: sampleBaby.id, type: .diaper, subtype: "wet", startTime: now.addingTimeInterval(-3600 * 3))
                ]
                
                for event in events {
                    try await dataStore.addEvent(event)
                }
                
                await MainActor.run {
                    isCompleted = true
                }
            } catch {
                print("Error loading sample data: \(error)")
            }
        }
    }
}

