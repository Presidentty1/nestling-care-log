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
    var userGoal: String? // User's primary goal: "Track Sleep", "Monitor Feeding", "Just Survive", "All of the Above"
    var celebrationsEnabled: Bool // Enable confetti / celebratory effects
    var analyticsEnabled: Bool // Allow analytics events

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
        case userGoal
        case celebrationsEnabled
        case analyticsEnabled
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
        remindersPaused: Bool = false,
        userGoal: String? = nil,
        celebrationsEnabled: Bool = true,
        analyticsEnabled: Bool = true
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
        self.userGoal = userGoal
        self.celebrationsEnabled = celebrationsEnabled
        self.analyticsEnabled = analyticsEnabled
    }

    // MARK: - Default Settings

    static func `default`() -> AppSettings {
        AppSettings()
    }
    
    // MARK: - Codable with backwards-compatible defaults
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        aiDataSharingEnabled = try container.decodeIfPresent(Bool.self, forKey: .aiDataSharingEnabled) ?? true
        feedReminderEnabled = try container.decodeIfPresent(Bool.self, forKey: .feedReminderEnabled) ?? true
        feedReminderHours = try container.decodeIfPresent(Int.self, forKey: .feedReminderHours) ?? 3
        napWindowAlertEnabled = try container.decodeIfPresent(Bool.self, forKey: .napWindowAlertEnabled) ?? true
        diaperReminderEnabled = try container.decodeIfPresent(Bool.self, forKey: .diaperReminderEnabled) ?? true
        diaperReminderHours = try container.decodeIfPresent(Int.self, forKey: .diaperReminderHours) ?? 2
        quietHoursStart = try container.decodeIfPresent(Date.self, forKey: .quietHoursStart)
        quietHoursEnd = try container.decodeIfPresent(Date.self, forKey: .quietHoursEnd)
        cryInsightsNotifyMe = try container.decodeIfPresent(Bool.self, forKey: .cryInsightsNotifyMe) ?? false
        onboardingCompleted = try container.decodeIfPresent(Bool.self, forKey: .onboardingCompleted) ?? false
        preferredUnit = try container.decodeIfPresent(String.self, forKey: .preferredUnit) ?? "ml"
        timeFormat24Hour = try container.decodeIfPresent(Bool.self, forKey: .timeFormat24Hour) ?? false
        preferMediumSheet = try container.decodeIfPresent(Bool.self, forKey: .preferMediumSheet) ?? true
        spotlightIndexingEnabled = try container.decodeIfPresent(Bool.self, forKey: .spotlightIndexingEnabled) ?? true
        cryInsightsWeeklyCount = try container.decodeIfPresent(Int.self, forKey: .cryInsightsWeeklyCount) ?? 0
        cryInsightsWeekStart = try container.decodeIfPresent(Date.self, forKey: .cryInsightsWeekStart)
        remindersPaused = try container.decodeIfPresent(Bool.self, forKey: .remindersPaused) ?? false
        userGoal = try container.decodeIfPresent(String.self, forKey: .userGoal)
        celebrationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .celebrationsEnabled) ?? true
        analyticsEnabled = try container.decodeIfPresent(Bool.self, forKey: .analyticsEnabled) ?? true
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(aiDataSharingEnabled, forKey: .aiDataSharingEnabled)
        try container.encode(feedReminderEnabled, forKey: .feedReminderEnabled)
        try container.encode(feedReminderHours, forKey: .feedReminderHours)
        try container.encode(napWindowAlertEnabled, forKey: .napWindowAlertEnabled)
        try container.encode(diaperReminderEnabled, forKey: .diaperReminderEnabled)
        try container.encode(diaperReminderHours, forKey: .diaperReminderHours)
        try container.encodeIfPresent(quietHoursStart, forKey: .quietHoursStart)
        try container.encodeIfPresent(quietHoursEnd, forKey: .quietHoursEnd)
        try container.encode(cryInsightsNotifyMe, forKey: .cryInsightsNotifyMe)
        try container.encode(onboardingCompleted, forKey: .onboardingCompleted)
        try container.encode(preferredUnit, forKey: .preferredUnit)
        try container.encode(timeFormat24Hour, forKey: .timeFormat24Hour)
        try container.encode(preferMediumSheet, forKey: .preferMediumSheet)
        try container.encode(spotlightIndexingEnabled, forKey: .spotlightIndexingEnabled)
        try container.encode(cryInsightsWeeklyCount, forKey: .cryInsightsWeeklyCount)
        try container.encodeIfPresent(cryInsightsWeekStart, forKey: .cryInsightsWeekStart)
        try container.encode(remindersPaused, forKey: .remindersPaused)
        try container.encodeIfPresent(userGoal, forKey: .userGoal)
        try container.encode(celebrationsEnabled, forKey: .celebrationsEnabled)
        try container.encode(analyticsEnabled, forKey: .analyticsEnabled)
    }
}