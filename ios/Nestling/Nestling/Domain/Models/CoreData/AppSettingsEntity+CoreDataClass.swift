import Foundation
import CoreData

@objc(AppSettingsEntity)
public class AppSettingsEntity: NSManagedObject {
    func update(from settings: AppSettings) {
        self.aiDataSharingEnabled = settings.aiDataSharingEnabled
        self.feedReminderEnabled = settings.feedReminderEnabled
        self.feedReminderHours = Int16(settings.feedReminderHours)
        self.napWindowAlertEnabled = settings.napWindowAlertEnabled
        self.diaperReminderEnabled = settings.diaperReminderEnabled
        self.diaperReminderHours = Int16(settings.diaperReminderHours)
        self.quietHoursStart = settings.quietHoursStart
        self.quietHoursEnd = settings.quietHoursEnd
        self.cryInsightsNotifyMe = settings.cryInsightsNotifyMe
        self.onboardingCompleted = settings.onboardingCompleted
        self.preferredUnit = settings.preferredUnit
        self.timeFormat24Hour = settings.timeFormat24Hour
        self.preferMediumSheet = settings.preferMediumSheet
        self.spotlightIndexingEnabled = settings.spotlightIndexingEnabled
        self.cryInsightsWeeklyCount = Int16(settings.cryInsightsWeeklyCount)
        self.cryInsightsWeekStart = settings.cryInsightsWeekStart
        self.remindersPaused = settings.remindersPaused
        self.version = Int16(1) // Schema version
    }
    
    func toAppSettings() -> AppSettings {
        AppSettings(
            aiDataSharingEnabled: aiDataSharingEnabled,
            feedReminderEnabled: feedReminderEnabled,
            feedReminderHours: Int(feedReminderHours),
            napWindowAlertEnabled: napWindowAlertEnabled,
            diaperReminderEnabled: diaperReminderEnabled,
            diaperReminderHours: Int(diaperReminderHours),
            quietHoursStart: quietHoursStart,
            quietHoursEnd: quietHoursEnd,
            cryInsightsNotifyMe: cryInsightsNotifyMe,
            onboardingCompleted: onboardingCompleted,
            preferredUnit: preferredUnit ?? "ml",
            timeFormat24Hour: timeFormat24Hour,
            preferMediumSheet: (try? value(forKey: "preferMediumSheet") as? Bool) ?? true, // Default to true if missing (for migration)
            spotlightIndexingEnabled: (try? value(forKey: "spotlightIndexingEnabled") as? Bool) ?? true,
            cryInsightsWeeklyCount: Int(cryInsightsWeeklyCount),
            cryInsightsWeekStart: cryInsightsWeekStart,
            remindersPaused: (try? value(forKey: "remindersPaused") as? Bool) ?? false
        )
    }
}

