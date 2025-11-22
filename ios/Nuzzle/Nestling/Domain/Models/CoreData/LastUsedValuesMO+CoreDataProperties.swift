import Foundation
import CoreData

extension LastUsedValuesMO {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<LastUsedValuesMO> {
        return NSFetchRequest<LastUsedValuesMO>(entityName: "LastUsedValuesMO")
    }

    @NSManaged public var eventType: String?
    @NSManaged public var amount: NSNumber?
    @NSManaged public var unit: String?
    @NSManaged public var side: String?
    @NSManaged public var subtype: String?
    @NSManaged public var durationMinutes: NSNumber?
}

