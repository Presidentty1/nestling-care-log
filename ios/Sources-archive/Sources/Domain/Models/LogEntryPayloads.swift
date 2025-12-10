import Foundation

// MARK: - Feed Payload

/// Feed-specific data
struct LogEntryPayloadFeed: Codable, Equatable {
    /// Source of the feed (breast, bottle, etc.)
    var source: LogEntryFeedSource

    /// Amount in milliliters
    var amountML: Double?

    /// Unit for display (ml, oz)
    var unit: String?

    /// Side for breast feeding (left, right, both)
    var side: LogEntryBreastSide?

    /// Duration in minutes (for breast feeding)
    var durationMinutes: Double?

    init(
        source: LogEntryFeedSource,
        amountML: Double? = nil,
        unit: String? = nil,
        side: LogEntryBreastSide? = nil,
        durationMinutes: Double? = nil
    ) {
        self.source = source
        self.amountML = amountML
        self.unit = unit
        self.side = side
        self.durationMinutes = durationMinutes
    }
}

/// Feed source types
enum LogEntryFeedSource: String, Codable, CaseIterable {
    case breastLeft
    case breastRight
    case breastBoth
    case bottle
    case solidFood
    case other

    var displayName: String {
        switch self {
        case .breastLeft: return "Left Breast"
        case .breastRight: return "Right Breast"
        case .breastBoth: return "Both Breasts"
        case .bottle: return "Bottle"
        case .solidFood: return "Solid Food"
        case .other: return "Other"
        }
    }
}

/// Breast feeding side
enum LogEntryBreastSide: String, Codable {
    case left
    case right
    case both
}

// MARK: - Diaper Payload

/// Diaper-specific data
struct LogEntryPayloadDiaper: Codable, Equatable {
    /// Whether the diaper was wet
    var wet: Bool

    /// Whether the diaper was dirty
    var dirty: Bool

    /// Optional notes
    var notes: String?

    init(wet: Bool, dirty: Bool, notes: String? = nil) {
        self.wet = wet
        self.dirty = dirty
        self.notes = notes
    }
}

// MARK: - Sleep Payload

/// Sleep-specific data
struct LogEntryPayloadSleep: Codable, Equatable {
    /// Current sleep state
    var state: LogEntrySleepState

    /// Type of sleep (nap, night, etc.)
    var subtype: LogEntrySleepSubtype?

    init(state: LogEntrySleepState, subtype: LogEntrySleepSubtype? = nil) {
        self.state = state
        self.subtype = subtype
    }
}

/// Sleep state
enum LogEntrySleepState: String, Codable {
    case started
    case ended
}

/// Sleep subtype
enum LogEntrySleepSubtype: String, Codable {
    case nap
    case night
    case catNap
}

// MARK: - Tummy Time Payload

/// Tummy time-specific data
struct LogEntryPayloadTummyTime: Codable, Equatable {
    /// Duration in minutes
    var durationMinutes: Int

    init(durationMinutes: Int) {
        self.durationMinutes = durationMinutes
    }
}



