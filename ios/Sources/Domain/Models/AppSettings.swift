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
        trialOffersDismissed: Bool = false
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
    }
    
    // MARK: - Default Settings
    
    static func `default`() -> AppSettings {
        AppSettings()
    }
}

