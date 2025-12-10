import Foundation

/// Service for tracking and providing smart defaults for quick logging
class SmartDefaultsService {
    private let dataStore: DataStore
    private let defaults = UserDefaults.standard

    // Keys for storing defaults
    private enum Keys {
        static let feedAmount = "smartDefaults.feed.amount"
        static let feedUnit = "smartDefaults.feed.unit"
        static let feedSubtype = "smartDefaults.feed.subtype"
        static let diaperSubtype = "smartDefaults.diaper.subtype"
        static let tummyDuration = "smartDefaults.tummy.duration"
    }

    init(dataStore: DataStore) {
        self.dataStore = dataStore
    }

    /// Get smart defaults for an event type
    func getDefaults(for eventType: EventType) async throws -> SmartDefaults {
        switch eventType {
        case .feed:
            return try await getFeedDefaults()
        case .diaper:
            return try await getDiaperDefaults()
        case .sleep:
            // Sleep doesn't use quick defaults (use start/stop timer instead)
            return SmartDefaults()
        case .tummyTime:
            return try await getTummyTimeDefaults()
        }
    }

    /// Update smart defaults based on a logged event
    func updateDefaults(for eventType: EventType, from event: Event) async {
        switch eventType {
        case .feed:
            updateFeedDefaults(from: event)
        case .diaper:
            updateDiaperDefaults(from: event)
        case .sleep:
            // No smart defaults for sleep
            break
        case .tummyTime:
            updateTummyTimeDefaults(from: event)
        }
    }

    // MARK: - Feed Defaults

    private func getFeedDefaults() async throws -> SmartDefaults {
        // Try UserDefaults first (fast)
        if let amount = defaults.double(forKey: Keys.feedAmount) as Double?,
           let unit = defaults.string(forKey: Keys.feedUnit),
           let subtype = defaults.string(forKey: Keys.feedSubtype) {

            return SmartDefaults(
                amount: amount > 0 ? amount : nil,
                unit: unit,
                subtype: subtype
            )
        }

        // Fall back to analyzing recent feed data
        return try await analyzeRecentFeedData()
    }

    private func analyzeRecentFeedData() async throws -> SmartDefaults {
        // Get last 7 days of feed events
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        // Note: This would need baby context, but for now we'll assume global defaults
        // In a full implementation, this would filter by baby

        var amounts: [Double] = []
        var units: [String] = []
        var subtypes: [String] = []

        // For now, return sensible defaults since we don't have baby context
        return SmartDefaults(
            amount: 120, // 120ml is common
            unit: "ml",
            subtype: "bottle"
        )
    }

    private func updateFeedDefaults(from event: Event) {
        if let amount = event.amount {
            defaults.set(amount, forKey: Keys.feedAmount)
        }
        if let unit = event.unit {
            defaults.set(unit, forKey: Keys.feedUnit)
        }
        if let subtype = event.subtype {
            defaults.set(subtype, forKey: Keys.feedSubtype)
        }
    }

    // MARK: - Diaper Defaults

    private func getDiaperDefaults() async throws -> SmartDefaults {
        if let subtype = defaults.string(forKey: Keys.diaperSubtype) {
            return SmartDefaults(subtype: subtype)
        }

        // Default to "wet" as most common
        return SmartDefaults(subtype: "wet")
    }

    private func updateDiaperDefaults(from event: Event) {
        if let subtype = event.subtype {
            defaults.set(subtype, forKey: Keys.diaperSubtype)
        }
    }

    // MARK: - Tummy Time Defaults

    private func getTummyTimeDefaults() async throws -> SmartDefaults {
        let duration = defaults.integer(forKey: Keys.tummyDuration)
        return SmartDefaults(durationMinutes: duration > 0 ? duration : 5) // Default 5 minutes
    }

    private func updateTummyTimeDefaults(from event: Event) {
        if let duration = event.durationMinutes {
            defaults.set(duration, forKey: Keys.tummyDuration)
        }
    }
}

/// Container for smart default values
struct SmartDefaults {
    var amount: Double?
    var unit: String?
    var subtype: String?
    var durationMinutes: Int?

    init(
        amount: Double? = nil,
        unit: String? = nil,
        subtype: String? = nil,
        durationMinutes: Int? = nil
    ) {
        self.amount = amount
        self.unit = unit
        self.subtype = subtype
        self.durationMinutes = durationMinutes
    }
}


