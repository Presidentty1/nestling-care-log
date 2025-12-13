import SwiftUI
import Combine

enum OnboardingStep {
    case welcome              // Value framing
    case babySetup            // Name + DOB/EDD + optional last wake → show first nap window
    case goalSelection        // Personalize home priorities
    case aiConsent            // Smart predictions consent/preferences
    case firstLog             // First value moment (log something) BEFORE paywall
    case notificationsPrimer  // Primer only (no OS permission prompt in Session 1)
    case paywall              // Soft paywall (optional)
    case complete             // Transition
}

// Focus areas for personalization
enum FocusArea: String, CaseIterable, Codable {
    case napsAndNights = "Naps & nights"
    case feedsAndDiapers = "Keeping track of feeds/diapers"
    case cries = "Understanding cries"
    case all = "All of the above"
    
    var displayName: String { rawValue }
}

// Birth/Due date selection
enum BirthDueSelection: String, CaseIterable {
    case dateOfBirth = "Date of Birth"
    case dueDate = "Due Date"
}

@MainActor
class OnboardingCoordinator: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    
    // Baby basics
    @Published var babyName: String = ""
    @Published var birthDueSelection: BirthDueSelection = .dateOfBirth
    @Published var dateOfBirth: Date = Date().addingTimeInterval(-60 * 24 * 60 * 60) // Default to 60 days ago
    @Published var dueDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @Published var sex: Sex?
    @Published var showAgeWarning: Bool = false
    
    // Focus areas
    @Published var selectedFocusAreas: Set<FocusArea> = []
    @Published var selectedGoal: String? // Legacy compatibility
    
    // Last wake & nap prediction
    @Published var lastWakeTime: Date?
    @Published var firstNapWindow: NapWindow?
    @Published var isSleepingNow: Bool = false
    
    // Notifications
    @Published var wantsNapNotifications: Bool = true
    
    // Legacy property for deprecated InitialStateView
    @Published var initialBabyState: String? = nil

    // Settings
    @Published var preferredUnit: String = detectSmartDefaultUnit()
    @Published var timeFormat24Hour: Bool = detectSmartDefaultTimeFormat()
    @Published var aiDataSharingEnabled: Bool = true
    
    // State
    @Published var isCompleted: Bool = false

    // Draft baby created during onboarding so IDs stay stable across steps.
    @Published private(set) var draftBaby: Baby?
    private var hasPersistedDraftBaby: Bool = false

    // Notification permission timing: we show a primer during onboarding,
    // then request OS permission on/after Session 2 (or when user explicitly turns it on in Settings).
    private let notificationPrimerSeenKey = "onboarding_notifications_primer_seen"
    private let launchCountKey = "app_launch_count"
    
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
        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case .welcome:
                currentStep = .babySetup
            case .babySetup:
                // Persist baby early so first log can succeed.
                Task { await persistDraftBabyIfNeeded() }
                currentStep = .goalSelection
            case .goalSelection:
                currentStep = .aiConsent
            case .aiConsent:
                // Ensure baby exists before first log step.
                Task { await persistDraftBabyIfNeeded() }
                currentStep = .firstLog
            case .firstLog:
                currentStep = .notificationsPrimer
            case .notificationsPrimer:
                currentStep = .paywall
            case .paywall:
                currentStep = .complete
            case .complete:
                completeOnboarding()
            }
        }
    }
    
    func skipToPaywall() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = .paywall
        }
    }
    
    func skipPaywall() {
        // Skip paywall and go directly to complete
        currentStep = .complete
    }
    
    func updateNapPrediction() {
        guard let baby = createBabyFromCurrentData() else { return }
        
        let wakeTime = lastWakeTime ?? Date()
        firstNapWindow = NapPredictorService.predictNextNapWindow(for: baby, lastWakeTime: wakeTime)
    }
    
    /// Creates (or returns) the stable draft baby for onboarding.
    /// This avoids generating a new UUID every time the baby is referenced.
    func createBabyFromCurrentData() -> Baby? {
        if let existing = draftBaby {
            return existing
        }

        let finalName = babyName.trimmingCharacters(in: .whitespaces).isEmpty ? "Baby" : babyName
        let birthDate = birthDueSelection == .dateOfBirth ? dateOfBirth : dueDate

        let baby = Baby(
            name: finalName,
            dateOfBirth: birthDate,
            sex: sex,
            timezone: TimeZone.current.identifier
        )
        draftBaby = baby
        return baby
    }

    private func persistDraftBabyIfNeeded() async {
        guard !hasPersistedDraftBaby else { return }
        guard let baby = createBabyFromCurrentData() else { return }

        do {
            try await dataStore.addBaby(baby)
            hasPersistedDraftBaby = true
        } catch {
            // If this fails, we still allow onboarding to continue, but first log may fallback.
            logger.debug("Error persisting draft baby during onboarding: \(error)")
        }
    }
    
    func skip() {
        // Log skip event
        Task {
            let stepName = stepNameForAnalytics(currentStep)
            await Analytics.shared.logOnboardingStepSkipped(step: stepName)
        }
        // Allow skipping any step - go straight to app
        completeOnboarding()
    }
    
    private func stepNameForAnalytics(_ step: OnboardingStep) -> String {
        switch step {
        case .welcome: return "welcome"
        case .babySetup: return "baby_setup"
        case .goalSelection: return "goal_selection"
        case .aiConsent: return "ai_consent"
        case .firstLog: return "first_log"
        case .notificationsPrimer: return "notifications_primer"
        case .paywall: return "paywall"
        case .complete: return "complete"
        }
    }
    
    func completeOnboarding() {
        Task {
            do {
                // TODO: Analytics.track(.onboardingCompleted)
                
                // Ensure draft baby is persisted (needed if user skipped earlier steps)
                await persistDraftBabyIfNeeded()
                guard let baby = createBabyFromCurrentData() else {
                    throw NSError(domain: "Onboarding", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing baby data"])
                }

                // Analytics: onboarding completed
                await Analytics.shared.logOnboardingCompleted(babyId: baby.id.uuidString)

                // Save preferences
                var settings = try await dataStore.fetchAppSettings()
                settings.preferredUnit = preferredUnit
                settings.timeFormat24Hour = timeFormat24Hour
                settings.aiDataSharingEnabled = aiDataSharingEnabled
                settings.onboardingCompleted = true
                settings.napWindowAlertEnabled = wantsNapNotifications

                // Record primer seen; OS prompt is deferred until later session.
                UserDefaults.standard.set(true, forKey: notificationPrimerSeenKey)
                
                // Save focus areas as userGoal
                if !selectedFocusAreas.isEmpty {
                    let focusString = selectedFocusAreas.map { $0.rawValue }.joined(separator: ", ")
                    settings.userGoal = focusString
                } else if let goal = selectedGoal {
                    settings.userGoal = goal
                }
                
                try await dataStore.saveAppSettings(settings)
                
                await MainActor.run {
                    // Mark as completed so parent view can react
                    isCompleted = true
                }

                // Start the first 72 hours activation journey
                if PolishFeatureFlags.shared.first72hJourneyEnabled {
                    FirstThreeDaysJourneyService.shared.startJourney(onboardingCompleteDate: Date())
                }
            } catch {
                logger.debug("Error completing onboarding: \(error)")
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
                logger.debug("Error loading sample data: \(error)")
            }
        }
    }
}

