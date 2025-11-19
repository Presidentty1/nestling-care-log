import Foundation
import CoreData

extension BabyEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<BabyEntity> {
        return NSFetchRequest<BabyEntity>(entityName: "BabyEntity")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var dateOfBirth: Date?
    @NSManaged public var sex: String?
    @NSManaged public var timezone: String?
    @NSManaged public var primaryFeedingStyle: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var events: NSSet?
}

extension BabyEntity : Identifiable {
}

