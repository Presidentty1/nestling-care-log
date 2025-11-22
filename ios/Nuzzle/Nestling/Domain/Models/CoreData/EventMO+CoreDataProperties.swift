import Foundation
import CoreData

extension EventMO {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<EventMO> {
        return NSFetchRequest<EventMO>(entityName: "EventMO")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var babyId: UUID?
    @NSManaged public var type: String?
    @NSManaged public var subtype: String?
    @NSManaged public var startTime: Date?
    @NSManaged public var endTime: Date?
    @NSManaged public var amount: NSNumber?
    @NSManaged public var unit: String?
    @NSManaged public var side: String?
    @NSManaged public var note: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
}

