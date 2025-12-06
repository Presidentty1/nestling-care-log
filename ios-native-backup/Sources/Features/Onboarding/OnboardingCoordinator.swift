import SwiftUI

enum OnboardingStep {
    case babyInfo
    case goalSelection
    case initialState
}

@MainActor
class OnboardingCoordinator: ObservableObject {
    @Published var currentStep: OnboardingStep = .babyInfo
    @Published var babyName: String = ""
    @Published var dateOfBirth: Date = Calendar.current.startOfDay(for: Date())
    @Published var sex: Sex?
    @Published var primaryGoal: String = ""
    @Published var loadSampleData: Bool = false
    @Published var initialBabyState: String? = nil // "asleep" or "awake"
    @Published var showAgeWarning: Bool = false

    // Private properties for preferences (can be set later if needed)
    private var preferredUnit: String = "ml"
    private var timeFormat24Hour: Bool = false
    private var aiDataSharingEnabled: Bool = true

    private let dataStore: DataStore
    private let onboardingService: OnboardingService
    private let onComplete: () -> Void
    
    init(dataStore: DataStore, onComplete: @escaping () -> Void) {
        self.dataStore = dataStore
        self.onboardingService = OnboardingService(dataStore: dataStore)
        self.onComplete = onComplete
    }
    
    func next() {
        switch currentStep {
        case .babyInfo:
            currentStep = .goalSelection
        case .goalSelection:
            currentStep = .initialState
        case .initialState:
            completeOnboarding()
        }
    }
    
    func skip() {
        // Skip from any step completes onboarding
        let stepNumber: Int
        switch currentStep {
        case .babyInfo: stepNumber = 1
        case .goalSelection: stepNumber = 2
        case .initialState: stepNumber = 3
        }
        Task {
            await Analytics.shared.log("onboarding_completed", parameters: [
                "skipped": true,
                "steps_completed": stepNumber
            ])
        }
        completeOnboarding()
    }
    
    private func completeOnboarding() {
        Task {
            do {
                // Create baby with sensible defaults if fields are empty
                // Name and dateOfBirth are independent - don't use name to determine dateOfBirth
                let finalBabyName = babyName.trimmingCharacters(in: .whitespaces).isEmpty ? "Baby" : babyName
                // Always use dateOfBirth (which defaults to today if user didn't change it)
                // This ensures if user sets a date but skips name, the date is still used
                let finalDateOfBirth = dateOfBirth

                // Create baby
                let baby = Baby(
                    name: finalBabyName,
                    dateOfBirth: finalDateOfBirth,
                    sex: sex,
                    timezone: TimeZone.current.identifier
                )
                try await dataStore.addBaby(baby)
                
                // Set initial state if provided (Epic 1 AC5)
                if let initialState = initialBabyState {
                    if initialState == "asleep" {
                        // Create an active sleep event (no end time)
                        let sleepEvent = Event(
                            babyId: baby.id,
                            type: .sleep,
                            startTime: Date(),
                            endTime: nil,
                            subtype: "nap",
                            note: "Initial state from onboarding"
                        )
                        try await dataStore.addEvent(sleepEvent)
                        Logger.info("Created initial asleep state for baby \(baby.name)")
                    }
                    // If awake, no event needed - baby is awake by default
                }
                
                // Save preferences and goal
                var settings = try await dataStore.fetchAppSettings()
                settings.preferredUnit = preferredUnit
                settings.timeFormat24Hour = timeFormat24Hour
                settings.aiDataSharingEnabled = aiDataSharingEnabled
                settings.primaryGoal = primaryGoal.isEmpty ? nil : primaryGoal
                settings.onboardingCompleted = true
                try await dataStore.saveAppSettings(settings)

                await MainActor.run {
                    // Analytics for onboarding completion
                    Task {
                        await Analytics.shared.log("onboarding_completed", parameters: [
                            "skipped": false,
                            "steps_completed": 3,
                            "goal_selected": primaryGoal,
                            "initial_state": initialBabyState ?? "skipped",
                            "sample_data_requested": loadSampleData
                        ])
                    }
                    onComplete()
                }

                // Load sample data if requested - do this after onboarding completion
                // so that failures don't prevent the user from proceeding
                if loadSampleData {
                    Task {
                        do {
                            try await loadSampleDataForBaby(baby)
                            Logger.info("Successfully loaded sample data for baby \(baby.name)")
                        } catch {
                            Logger.dataError("Failed to load sample data for baby \(baby.name): \(error.localizedDescription)")
                            // Don't show error to user - sample data is optional and failure shouldn't block onboarding
                        }
                    }
                }
            } catch {
                Logger.dataError("Error completing onboarding: \(error.localizedDescription)")
            }
        }
    }

    /// Load sample data for the newly created baby to demonstrate app functionality
    private func loadSampleDataForBaby(_ baby: Baby) async throws {
        let now = Date()
        let calendar = Calendar.current

        // Create realistic 24-hour pattern for a 3-month-old baby
        // Mark all sample events with a special note to identify them as examples
        let sampleEvents: [Event] = [
            // Last night: 8 PM bedtime, slept until 7 AM (11 hours)
            Event(
                babyId: baby.id,
                type: .sleep,
                startTime: calendar.date(byAdding: .hour, value: -16, to: now)!, // 8 hours ago
                endTime: calendar.date(byAdding: .hour, value: -5, to: now)!,   // 5 hours ago
                note: "[EXAMPLE] Night sleep"
            ),

            // Morning routine: 7 AM wake, 7:30 AM feed
            Event(
                babyId: baby.id,
                type: .feed,
                startTime: calendar.date(byAdding: .hour, value: -5, to: now)!,
                amount: 150,
                unit: preferredUnit,
                subtype: "bottle"
            ),

            // 8:30 AM diaper change
            Event(
                babyId: baby.id,
                type: .diaper,
                startTime: calendar.date(byAdding: .hour, value: -4, to: now)!,
                subtype: "wet"
            ),

            // 9 AM morning nap (45 minutes)
            Event(
                babyId: baby.id,
                type: .sleep,
                startTime: calendar.date(byAdding: .hour, value: -3, to: now)!,
                endTime: calendar.date(byAdding: .minute, value: -75, to: now)!,
                subtype: "nap"
            ),

            // 11 AM feed
            Event(
                babyId: baby.id,
                type: .feed,
                startTime: calendar.date(byAdding: .hour, value: -1, to: now)!,
                amount: 160,
                unit: preferredUnit,
                subtype: "bottle"
            ),

            // 12 PM diaper + tummy time
            Event(
                babyId: baby.id,
                type: .diaper,
                startTime: calendar.date(byAdding: .hour, value: 0, to: now)!,
                subtype: "both"
            ),

            Event(
                babyId: baby.id,
                type: .tummyTime,
                startTime: calendar.date(byAdding: .hour, value: 0, to: now)!,
                endTime: calendar.date(byAdding: .minute, value: 10, to: now)!,
                note: "[EXAMPLE] Played with soft toys"
            ),

            // 2 PM afternoon feed
            Event(
                babyId: baby.id,
                type: .feed,
                startTime: calendar.date(byAdding: .hour, value: 2, to: now)!,
                amount: 140,
                unit: preferredUnit,
                subtype: "bottle"
            ),

            // 3:30 PM afternoon nap (1.5 hours)
            Event(
                babyId: baby.id,
                type: .sleep,
                startTime: calendar.date(byAdding: .hour, value: 4, to: now)!,
                endTime: calendar.date(byAdding: .hour, value: 5, to: now)!,
                subtype: "nap"
            ),

            // 6 PM dinner feed
            Event(
                babyId: baby.id,
                type: .feed,
                startTime: calendar.date(byAdding: .hour, value: 6, to: now)!,
                amount: 170,
                unit: preferredUnit,
                subtype: "bottle"
            ),

            // 7 PM diaper before bed
            Event(
                babyId: baby.id,
                type: .diaper,
                startTime: calendar.date(byAdding: .hour, value: 7, to: now)!,
                subtype: "wet"
            )
        ]

        // Add all sample events
        for event in sampleEvents {
            try await dataStore.addEvent(event)
        }

        Logger.info("Loaded \(sampleEvents.count) sample events for baby \(baby.name)")
    }
}


