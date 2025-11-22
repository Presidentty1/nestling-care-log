import Foundation
import CoreData

extension BabyMO {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<BabyMO> {
        return NSFetchRequest<BabyMO>(entityName: "BabyMO")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var dateOfBirth: Date?
    @NSManaged public var sex: String?
    @NSManaged public var timezone: String?
    @NSManaged public var primaryFeedingStyle: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
}

