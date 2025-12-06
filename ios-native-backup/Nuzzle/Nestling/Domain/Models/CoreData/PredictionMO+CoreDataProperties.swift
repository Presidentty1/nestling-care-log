import Foundation
import CoreData

extension PredictionMO {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<PredictionMO> {
        return NSFetchRequest<PredictionMO>(entityName: "PredictionMO")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var babyId: UUID?
    @NSManaged public var type: String?
    @NSManaged public var predictedTime: Date?
    @NSManaged public var confidence: Double
    @NSManaged public var explanation: String?
    @NSManaged public var createdAt: Date?
}

