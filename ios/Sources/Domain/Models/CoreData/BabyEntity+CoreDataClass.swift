import Foundation
import CoreData

@objc(BabyEntity)
public class BabyEntity: NSManagedObject {
    func update(from baby: Baby) {
        self.id = baby.id
        self.name = baby.name
        self.dateOfBirth = baby.dateOfBirth
        self.sex = baby.sex?.rawValue
        self.timezone = baby.timezone
        self.primaryFeedingStyle = baby.primaryFeedingStyle?.rawValue
        self.createdAt = baby.createdAt
        self.updatedAt = baby.updatedAt
    }
    
    func toBaby() -> Baby {
        Baby(
            id: id ?? UUID(),
            name: name ?? "",
            dateOfBirth: dateOfBirth ?? Date(),
            sex: sex.flatMap { Sex(rawValue: $0) },
            timezone: timezone ?? TimeZone.current.identifier,
            primaryFeedingStyle: primaryFeedingStyle.flatMap { FeedingStyle(rawValue: $0) },
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date()
        )
    }
}


