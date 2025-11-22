import Foundation
import SwiftUI

struct Event: Identifiable, Codable, Equatable {
    let id: UUID
    let babyId: UUID
    let type: EventType
    let subtype: String?
    let startTime: Date
    var endTime: Date?
    let amount: Double?
    let unit: String?
    let side: String?
    let note: String?
    let photoUrls: [String]? // URLs to stored photos
    let createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        babyId: UUID,
        type: EventType,
        subtype: String? = nil,
        startTime: Date = Date(),
        endTime: Date? = nil,
        amount: Double? = nil,
        unit: String? = nil,
        side: String? = nil,
        note: String? = nil,
        photoUrls: [String]? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.babyId = babyId
        self.type = type
        self.subtype = subtype
        self.startTime = startTime
        self.endTime = endTime
        self.amount = amount
        self.unit = unit
        self.side = side
        self.note = note
        self.photoUrls = photoUrls
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Computed Properties
    
    var durationMinutes: Int? {
        guard let endTime = endTime else { return nil }
        return Int(endTime.timeIntervalSince(startTime) / 60)
    }
    
    // MARK: - Mock Data
    
    static func mockFeed(babyId: UUID, amount: Double = 120, unit: String = "ml", subtype: String = "bottle") -> Event {
        Event(
            babyId: babyId,
            type: .feed,
            subtype: subtype,
            amount: amount,
            unit: unit,
            note: nil
        )
    }
    
    static func mockSleep(babyId: UUID, durationMinutes: Int = 45, subtype: String = "nap") -> Event {
        let startTime = Date().addingTimeInterval(-Double(durationMinutes * 60))
        let endTime = Date()
        return Event(
            babyId: babyId,
            type: .sleep,
            subtype: subtype,
            startTime: startTime,
            endTime: endTime,
            note: nil
        )
    }
    
    static func mockDiaper(babyId: UUID, subtype: String = "wet") -> Event {
        Event(
            babyId: babyId,
            type: .diaper,
            subtype: subtype,
            note: nil
        )
    }
    
    static func mockTummyTime(babyId: UUID, durationMinutes: Int = 5) -> Event {
        let startTime = Date().addingTimeInterval(-Double(durationMinutes * 60))
        let endTime = Date()
        return Event(
            babyId: babyId,
            type: .tummyTime,
            startTime: startTime,
            endTime: endTime,
            note: nil
        )
    }
}

enum EventType: String, Codable, CaseIterable {
    case feed
    case diaper
    case sleep
    case tummyTime = "tummy_time"
    
    var displayName: String {
        switch self {
        case .feed: return "Feed"
        case .diaper: return "Diaper"
        case .sleep: return "Sleep"
        case .tummyTime: return "Tummy Time"
        }
    }
    
    var iconName: String {
        switch self {
        case .feed: return "drop.fill"
        case .diaper: return "drop.circle.fill"
        case .sleep: return "moon.fill"
        case .tummyTime: return "figure.child"
        }
    }
    
    var color: Color {
        switch self {
        case .feed: return .blue
        case .diaper: return .orange
        case .sleep: return .purple
        case .tummyTime: return .green
        }
    }
}

