import Foundation
import SwiftData

/// Unified log entry for all baby care activities.
/// Replaces the separate Event model with a single, unified structure.
@Model
final class LogEntry {
    /// Unique identifier for the log entry
    @Attribute(.unique) var id: UUID

    /// Baby this entry belongs to
    var babyID: UUID

    /// Type of activity (feed, diaper, sleep, tummy time)
    var type: LogEntryType

    /// When the activity started
    var startTime: Date

    /// When the activity ended (optional, computed for some types)
    var endTime: Date?

    /// Source of this entry (manual, reminder, AI suggestion)
    var source: LogEntrySource

    /// When this entry was created
    var createdAt: Date

    /// When this entry was last updated
    var updatedAt: Date

    // MARK: - Type-Specific Payloads

    /// Payload for feed entries
    var payloadFeed: LogEntryPayloadFeed?

    /// Payload for diaper entries
    var payloadDiaper: LogEntryPayloadDiaper?

    /// Payload for sleep entries
    var payloadSleep: LogEntryPayloadSleep?

    /// Payload for tummy time entries
    var payloadTummyTime: LogEntryPayloadTummyTime?

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        babyID: UUID,
        type: LogEntryType,
        startTime: Date = Date(),
        endTime: Date? = nil,
        source: LogEntrySource = .manual,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        payloadFeed: LogEntryPayloadFeed? = nil,
        payloadDiaper: LogEntryPayloadDiaper? = nil,
        payloadSleep: LogEntryPayloadSleep? = nil,
        payloadTummyTime: LogEntryPayloadTummyTime? = nil
    ) {
        self.id = id
        self.babyID = babyID
        self.type = type
        self.startTime = startTime
        self.endTime = endTime
        self.source = source
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.payloadFeed = payloadFeed
        self.payloadDiaper = payloadDiaper
        self.payloadSleep = payloadSleep
        self.payloadTummyTime = payloadTummyTime
    }

    // MARK: - Computed Properties

    /// Duration in minutes (computed from start/end time)
    var durationMinutes: Int? {
        guard let endTime = endTime else { return nil }
        return Int(endTime.timeIntervalSince(startTime) / 60)
    }

    /// Human-readable display text for the entry
    var displayText: String {
        switch type {
        case .feed:
            if let payload = payloadFeed {
                let amount = payload.amountML ?? 0
                let unit = payload.unit ?? "ml"
                return "\(amount)\(unit) feed"
            }
            return "Feed"

        case .diaper:
            if let payload = payloadDiaper {
                var components: [String] = []
                if payload.wet { components.append("wet") }
                if payload.dirty { components.append("dirty") }
                if components.isEmpty { components.append("diaper") }
                return components.joined(separator: " + ")
            }
            return "Diaper"

        case .sleep:
            if let duration = durationMinutes {
                return "Sleep (\(duration)min)"
            }
            return "Sleep"

        case .tummyTime:
            if let duration = durationMinutes {
                return "Tummy time (\(duration)min)"
            }
            return "Tummy time"
        }
    }

    // MARK: - Factory Methods for Testing

    static func mockFeed(
        babyID: UUID,
        amountML: Double = 120,
        unit: String = "ml",
        subtype: LogEntryFeedSource = .bottle
    ) -> LogEntry {
        LogEntry(
            babyID: babyID,
            type: .feed,
            payloadFeed: LogEntryPayloadFeed(
                source: subtype,
                amountML: amountML,
                unit: unit
            )
        )
    }

    static func mockSleep(
        babyID: UUID,
        durationMinutes: Int = 45,
        subtype: LogEntrySleepState = .nap
    ) -> LogEntry {
        let startTime = Date().addingTimeInterval(-Double(durationMinutes * 60))
        let endTime = Date()
        return LogEntry(
            babyID: babyID,
            type: .sleep,
            startTime: startTime,
            endTime: endTime,
            payloadSleep: LogEntryPayloadSleep(
                state: .ended,
                subtype: subtype
            )
        )
    }

    static func mockDiaper(
        babyID: UUID,
        wet: Bool = true,
        dirty: Bool = false
    ) -> LogEntry {
        LogEntry(
            babyID: babyID,
            type: .diaper,
            payloadDiaper: LogEntryPayloadDiaper(
                wet: wet,
                dirty: dirty,
                notes: nil
            )
        )
    }

    static func mockTummyTime(
        babyID: UUID,
        durationMinutes: Int = 5
    ) -> LogEntry {
        let startTime = Date().addingTimeInterval(-Double(durationMinutes * 60))
        let endTime = Date()
        return LogEntry(
            babyID: babyID,
            type: .tummyTime,
            startTime: startTime,
            endTime: endTime,
            payloadTummyTime: LogEntryPayloadTummyTime(durationMinutes: durationMinutes)
        )
    }
}


