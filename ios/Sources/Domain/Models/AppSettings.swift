import Foundation

struct AppSettings: Codable, Equatable {
    var aiDataSharingEnabled: Bool
    var feedReminderEnabled: Bool
    var feedReminderHours: Int
    var napWindowAlertEnabled: Bool
    var diaperReminderEnabled: Bool
    var diaperReminderHours: Int
    var quietHoursStart: Date?
    var quietHoursEnd: Date?
    var cryInsightsNotifyMe: Bool
    var onboardingCompleted: Bool
    var preferredUnit: String // "ml" or "oz"
    var timeFormat24Hour: Bool
    var preferMediumSheet: Bool // Prefer medium detent by default
    var spotlightIndexingEnabled: Bool // Index events in Spotlight
    var primaryGoal: String? // User's primary goal: "better_naps", "track_feeds", etc.
    var trialOffersDismissed: Bool // Whether user has dismissed trial offers
    var hasExploredPredictions: Bool? // Whether user has visited predictions view
    var hasDismissedFirstTasksChecklist: Bool? // Whether user dismissed first tasks checklist
    var hasSeenHomeTutorial: Bool? // Whether user has seen the home screen tutorial
    
    init(
        aiDataSharingEnabled: Bool = true,
        feedReminderEnabled: Bool = true,
        feedReminderHours: Int = 3,
        napWindowAlertEnabled: Bool = true,
        diaperReminderEnabled: Bool = true,
        diaperReminderHours: Int = 2,
        quietHoursStart: Date? = nil,
        quietHoursEnd: Date? = nil,
        cryInsightsNotifyMe: Bool = false,
        onboardingCompleted: Bool = false,
        preferredUnit: String = "ml",
        timeFormat24Hour: Bool = false,
        preferMediumSheet: Bool = true,
        spotlightIndexingEnabled: Bool = true,
        primaryGoal: String? = nil,
        trialOffersDismissed: Bool = false,
        hasExploredPredictions: Bool? = nil,
        hasDismissedFirstTasksChecklist: Bool? = nil,
        hasSeenHomeTutorial: Bool? = nil
    ) {
        self.aiDataSharingEnabled = aiDataSharingEnabled
        self.feedReminderEnabled = feedReminderEnabled
        self.feedReminderHours = feedReminderHours
        self.napWindowAlertEnabled = napWindowAlertEnabled
        self.diaperReminderEnabled = diaperReminderEnabled
        self.diaperReminderHours = diaperReminderHours
        self.quietHoursStart = quietHoursStart
        self.quietHoursEnd = quietHoursEnd
        self.cryInsightsNotifyMe = cryInsightsNotifyMe
        self.onboardingCompleted = onboardingCompleted
        self.preferredUnit = preferredUnit
        self.timeFormat24Hour = timeFormat24Hour
        self.preferMediumSheet = preferMediumSheet
        self.spotlightIndexingEnabled = spotlightIndexingEnabled
        self.primaryGoal = primaryGoal
        self.trialOffersDismissed = trialOffersDismissed
        self.hasExploredPredictions = hasExploredPredictions
        self.hasDismissedFirstTasksChecklist = hasDismissedFirstTasksChecklist
        self.hasSeenHomeTutorial = hasSeenHomeTutorial
    }
    
    // MARK: - Default Settings
    
    static func `default`() -> AppSettings {
        AppSettings()
    }
}

