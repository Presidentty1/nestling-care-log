import Foundation
import CoreData

@objc(BabyMO)
public class BabyMO: NSManagedObject {
    func configure(with baby: Baby) {
        id = baby.id
        name = baby.name
        dateOfBirth = baby.dateOfBirth
        sex = baby.sex?.rawValue
        timezone = baby.timezone
        primaryFeedingStyle = baby.primaryFeedingStyle?.rawValue
        createdAt = baby.createdAt
        updatedAt = baby.updatedAt
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

