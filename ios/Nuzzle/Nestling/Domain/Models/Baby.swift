import Foundation

struct Baby: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    let dateOfBirth: Date
    let sex: Sex?
    let timezone: String
    let primaryFeedingStyle: FeedingStyle?
    let createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        dateOfBirth: Date,
        sex: Sex? = nil,
        timezone: String = TimeZone.current.identifier,
        primaryFeedingStyle: FeedingStyle? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.dateOfBirth = dateOfBirth
        self.sex = sex
        self.timezone = timezone
        self.primaryFeedingStyle = primaryFeedingStyle
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Mock Data
    
    static func mock() -> Baby {
        Baby(
            name: "Emma",
            dateOfBirth: Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date(),
            sex: .female,
            primaryFeedingStyle: .both
        )
    }
    
    static func mock2() -> Baby {
        Baby(
            name: "Lucas",
            dateOfBirth: Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date(),
            sex: .male,
            primaryFeedingStyle: .bottle
        )
    }
    
    static func mock3() -> Baby {
        Baby(
            name: "Sophia",
            dateOfBirth: Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date(),
            sex: .female,
            primaryFeedingStyle: .breast
        )
    }
}

enum Sex: String, Codable, CaseIterable {
    case male = "m"
    case female = "f"
    case intersex = "i"
    case preferNotToSay = "pns"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .male: return "Boy"
        case .female: return "Girl"
        case .intersex: return "Intersex"
        case .preferNotToSay: return "Prefer not to say"
        case .other: return "Other"
        }
    }
}

enum FeedingStyle: String, Codable, CaseIterable {
    case breast
    case bottle
    case both
    
    var displayName: String {
        switch self {
        case .breast: return "Breast"
        case .bottle: return "Bottle"
        case .both: return "Both"
        }
    }
}

