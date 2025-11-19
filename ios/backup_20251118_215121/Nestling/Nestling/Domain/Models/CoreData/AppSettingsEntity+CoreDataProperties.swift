import Foundation
import CoreData

extension AppSettingsEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<AppSettingsEntity> {
        return NSFetchRequest<AppSettingsEntity>(entityName: "AppSettingsEntity")
    }
    
    @NSManaged public var aiDataSharingEnabled: Bool
    @NSManaged public var feedReminderEnabled: Bool
    @NSManaged public var feedReminderHours: Int16
    @NSManaged public var napWindowAlertEnabled: Bool
    @NSManaged public var diaperReminderEnabled: Bool
    @NSManaged public var diaperReminderHours: Int16
    @NSManaged public var quietHoursStart: Date?
    @NSManaged public var quietHoursEnd: Date?
    @NSManaged public var cryInsightsNotifyMe: Bool
    @NSManaged public var onboardingCompleted: Bool
    @NSManaged public var preferredUnit: String?
    @NSManaged public var timeFormat24Hour: Bool
    @NSManaged public var preferMediumSheet: Bool
    @NSManaged public var version: Int16
}

extension AppSettingsEntity : Identifiable {
}

