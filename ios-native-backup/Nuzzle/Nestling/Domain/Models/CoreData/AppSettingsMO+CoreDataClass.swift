import Foundation
import CoreData

@objc(AppSettingsMO)
public class AppSettingsMO: NSManagedObject {
    func configure(with settings: AppSettings) {
        aiDataSharingEnabled = settings.aiDataSharingEnabled
        feedReminderEnabled = settings.feedReminderEnabled
        feedReminderHours = Int32(settings.feedReminderHours)
        napWindowAlertEnabled = settings.napWindowAlertEnabled
        diaperReminderEnabled = settings.diaperReminderEnabled
        diaperReminderHours = Int32(settings.diaperReminderHours)
        quietHoursStart = settings.quietHoursStart
        quietHoursEnd = settings.quietHoursEnd
        cryInsightsNotifyMe = settings.cryInsightsNotifyMe
        onboardingCompleted = settings.onboardingCompleted
        preferredUnit = settings.preferredUnit
        timeFormat24Hour = settings.timeFormat24Hour
        preferMediumSheet = settings.preferMediumSheet
        spotlightIndexingEnabled = settings.spotlightIndexingEnabled
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
            preferMediumSheet: preferMediumSheet,
            spotlightIndexingEnabled: spotlightIndexingEnabled
        )
    }
}

