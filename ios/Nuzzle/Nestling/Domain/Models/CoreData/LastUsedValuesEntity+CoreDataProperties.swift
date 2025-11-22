import Foundation
import CoreData

extension LastUsedValuesEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<LastUsedValuesEntity> {
        return NSFetchRequest<LastUsedValuesEntity>(entityName: "LastUsedValuesEntity")
    }
    
    @NSManaged public var eventType: String?
    @NSManaged public var amount: NSDecimalNumber?
    @NSManaged public var unit: String?
    @NSManaged public var side: String?
    @NSManaged public var subtype: String?
    @NSManaged public var durationMinutes: Int16
}

extension LastUsedValuesEntity : Identifiable {
}

