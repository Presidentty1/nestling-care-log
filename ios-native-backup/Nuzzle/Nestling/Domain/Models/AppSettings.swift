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
    var cryInsightsWeeklyCount: Int // Number of Cry Insights recordings this week
    var cryInsightsWeekStart: Date? // Start date of current week for quota tracking
    var remindersPaused: Bool // Whether all reminders are temporarily paused

    enum CodingKeys: String, CodingKey {
        case aiDataSharingEnabled
        case feedReminderEnabled
        case feedReminderHours
        case napWindowAlertEnabled
        case diaperReminderEnabled
        case diaperReminderHours
        case quietHoursStart
        case quietHoursEnd
        case cryInsightsNotifyMe
        case onboardingCompleted
        case preferredUnit
        case timeFormat24Hour
        case preferMediumSheet
        case spotlightIndexingEnabled
        case cryInsightsWeeklyCount
        case cryInsightsWeekStart
        case remindersPaused
    }

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
        cryInsightsWeeklyCount: Int = 0,
        cryInsightsWeekStart: Date? = nil,
        remindersPaused: Bool = false
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
        self.cryInsightsWeeklyCount = cryInsightsWeeklyCount
        self.cryInsightsWeekStart = cryInsightsWeekStart
        self.remindersPaused = remindersPaused
    }

    // MARK: - Default Settings

    static func `default`() -> AppSettings {
        AppSettings()
    }
}