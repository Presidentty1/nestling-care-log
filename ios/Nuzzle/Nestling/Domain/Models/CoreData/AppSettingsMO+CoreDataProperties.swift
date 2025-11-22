import Foundation
import CoreData

extension AppSettingsMO {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<AppSettingsMO> {
        return NSFetchRequest<AppSettingsMO>(entityName: "AppSettingsMO")
    }

    @NSManaged public var aiDataSharingEnabled: Bool
    @NSManaged public var feedReminderEnabled: Bool
    @NSManaged public var feedReminderHours: Int32
    @NSManaged public var napWindowAlertEnabled: Bool
    @NSManaged public var diaperReminderEnabled: Bool
    @NSManaged public var diaperReminderHours: Int32
    @NSManaged public var quietHoursStart: Date?
    @NSManaged public var quietHoursEnd: Date?
    @NSManaged public var cryInsightsNotifyMe: Bool
    @NSManaged public var onboardingCompleted: Bool
    @NSManaged public var preferredUnit: String?
    @NSManaged public var timeFormat24Hour: Bool
    @NSManaged public var preferMediumSheet: Bool
    @NSManaged public var spotlightIndexingEnabled: Bool
}

