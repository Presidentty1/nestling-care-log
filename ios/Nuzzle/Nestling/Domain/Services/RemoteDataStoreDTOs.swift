import Foundation

// MARK: - DTOs (Data Transfer Objects) for Supabase

/// Database representation of a Baby
struct BabyDTO: Codable {
    let id: UUID
    let familyId: UUID
    let name: String
    let dateOfBirth: Date
    let dueDate: Date?
    let sex: String?
    let timezone: String
    let primaryFeedingStyle: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case familyId = "family_id"
        case name
        case dateOfBirth = "date_of_birth"
        case dueDate = "due_date"
        case sex
        case timezone
        case primaryFeedingStyle = "primary_feeding_style"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    /// Convert DTO to domain model
    func toBaby() -> Baby {
        // Map database sex values ("male", "female") to Swift enum ("m", "f")
        let mappedSex: Sex? = sex.map { dbValue in
            switch dbValue.lowercased() {
            case "male", "m": return .male
            case "female", "f": return .female
            default: return .preferNotToSay
            }
        }
        
        // Map database feeding style ("breast", "formula", "combo") to Swift enum ("breast", "bottle", "both")
        let mappedFeedingStyle: FeedingStyle? = primaryFeedingStyle.map { dbValue in
            switch dbValue.lowercased() {
            case "breast": return .breast
            case "formula", "bottle": return .bottle
            case "combo", "both": return .both
            default: return .breast
            }
        }
        
        return Baby(
            id: id,
            name: name,
            dateOfBirth: dateOfBirth,
            sex: mappedSex,
            timezone: timezone,
            primaryFeedingStyle: mappedFeedingStyle,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    /// Convert domain model to DTO
    static func from(_ baby: Baby, familyId: UUID) -> BabyDTO {
        // Map Swift sex enum ("m", "f") to database values ("male", "female")
        let dbSex: String? = baby.sex.map { swiftValue in
            switch swiftValue {
            case .male: return "male"
            case .female: return "female"
            case .intersex: return "intersex"            case .preferNotToSay: return "prefer_not_to_say"
            }
        }
        
        // Map Swift feeding style ("breast", "bottle", "both") to database values ("breast", "formula", "combo")
        let dbFeedingStyle: String? = baby.primaryFeedingStyle.map { swiftValue in
            switch swiftValue {
            case .breast: return "breast"
            case .bottle: return "formula"
            case .both: return "combo"
            }
        }
        
        return BabyDTO(
            id: baby.id,
            familyId: familyId,
            name: baby.name,
            dateOfBirth: baby.dateOfBirth,
            dueDate: nil,
            sex: dbSex,
            timezone: baby.timezone,
            primaryFeedingStyle: dbFeedingStyle,
            createdAt: baby.createdAt,
            updatedAt: baby.updatedAt
        )
    }
}

/// Database representation of an Event
struct EventDTO: Codable {
    let id: UUID
    let familyId: UUID
    let babyId: UUID
    let type: String
    let subtype: String?
    let startTime: Date
    let endTime: Date?
    let amount: Double?
    let unit: String?
    let side: String?
    let note: String?
    let createdBy: UUID?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case familyId = "family_id"
        case babyId = "baby_id"
        case type
        case subtype
        case startTime = "start_time"
        case endTime = "end_time"
        case amount
        case unit
        case side
        case note
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    /// Convert DTO to domain model
    func toEvent() -> Event {
        Event(
            id: id,
            babyId: babyId,
            type: EventType(rawValue: type) ?? .feed,
            subtype: subtype,
            startTime: startTime,
            endTime: endTime,
            amount: amount,
            unit: unit,
            side: side,
            note: note,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    /// Convert domain model to DTO
    static func from(_ event: Event, familyId: UUID, userId: UUID?) -> EventDTO {
        EventDTO(
            id: event.id,
            familyId: familyId,
            babyId: event.babyId,
            type: event.type.rawValue,
            subtype: event.subtype,
            startTime: event.startTime,
            endTime: event.endTime,
            amount: event.amount,
            unit: event.unit,
            side: event.side,
            note: event.note,
            createdBy: userId,
            createdAt: event.createdAt,
            updatedAt: event.updatedAt
        )
    }
}

