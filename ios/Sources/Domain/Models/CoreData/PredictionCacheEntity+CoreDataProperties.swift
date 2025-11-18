import Foundation
import CoreData

extension PredictionCacheEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<PredictionCacheEntity> {
        return NSFetchRequest<PredictionCacheEntity>(entityName: "PredictionCacheEntity")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var babyId: UUID?
    @NSManaged public var type: String?
    @NSManaged public var predictedTime: Date?
    @NSManaged public var confidence: Double
    @NSManaged public var explanation: String?
    @NSManaged public var createdAt: Date?
}

extension PredictionCacheEntity : Identifiable {
}


