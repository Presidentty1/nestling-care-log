import Foundation

/// Service for predictive single-tap logging based on heuristics and patterns
///
/// Analyzes recent history and time-of-day to suggest common logging scenarios.
/// Starts with simple heuristics, can be enhanced with ML later.
///
/// Goals:
/// - Reduce logging friction from 2-3 taps to 1 tap
/// - Predict based on time patterns, recent history, baby age
/// - Show confidence levels and allow easy undo
class PredictiveLoggingService {
    static let shared = PredictiveLoggingService()

    enum PredictedEventType {
        case feed(amount: Double?, unit: String?, side: String?)
        case sleep // Start sleep timer
        case diaper(type: String?)
        case tummyTime // Start tummy time timer

        var icon: String {
            switch self {
            case .feed: return "drop.fill"
            case .sleep: return "moon.fill"
            case .diaper: return "drop.circle.fill"
            case .tummyTime: return "figure.child"
            }
        }

        var color: Color {
            switch self {
            case .feed: return .eventFeed
            case .sleep: return .eventSleep
            case .diaper: return .eventDiaper
            case .tummyTime: return .eventTummy
            }
        }

        var title: String {
            switch self {
            case .feed(let amount, _, _):
                if let amount = amount {
                    return "Log \(Int(amount))oz feed"
                } else {
                    return "Log feed"
                }
            case .sleep:
                return "Start sleep"
            case .diaper:
                return "Log diaper"
            case .tummyTime:
                return "Start tummy time"
            }
        }

        var subtitle: String? {
            switch self {
            case .feed(_, _, let side):
                if let side = side {
                    return "Usually \(side) side"
                } else {
                    return "Common amount"
                }
            case .sleep:
                return "Based on nap schedule"
            case .diaper(let type):
                if let type = type {
                    return "Usually \(type)"
                } else {
                    return "Quick log"
                }
            case .tummyTime:
                return "Track development"
            }
        }
    }

    struct Prediction: Identifiable {
        let id = UUID()
        let type: PredictedEventType
        let confidence: Double // 0.0 to 1.0
        let reason: String // Why this prediction was made

        var shouldShow: Bool {
            confidence >= 0.6 // Only show predictions with reasonable confidence
        }
    }

    private init() {}

    // MARK: - Prediction Logic

    /// Get predictions for the current moment
    func getPredictions(
        for baby: Baby,
        recentEvents: [Event],
        currentTime: Date = Date()
    ) -> [Prediction] {
        var predictions: [Prediction] = []

        let hour = Calendar.current.component(.hour, from: currentTime)
        let babyAgeWeeks = Calendar.current.dateComponents([.weekOfYear], from: baby.dateOfBirth, to: currentTime).weekOfYear ?? 0

        // Predict based on time of day and recent patterns
        if let feedPrediction = predictNextFeed(recentEvents, hour: hour, babyAgeWeeks: babyAgeWeeks) {
            predictions.append(feedPrediction)
        }

        if let sleepPrediction = predictSleepStart(recentEvents, hour: hour) {
            predictions.append(sleepPrediction)
        }

        if let diaperPrediction = predictDiaperChange(recentEvents, hour: hour) {
            predictions.append(diaperPrediction)
        }

        if let tummyPrediction = predictTummyTime(recentEvents, hour: hour, babyAgeWeeks: babyAgeWeeks) {
            predictions.append(tummyPrediction)
        }

        // Sort by confidence and return top predictions
        return predictions
            .filter { $0.shouldShow }
            .sorted { $0.confidence > $1.confidence }
            .prefix(2) // Show max 2 predictions
            .map { $0 }
    }

    // MARK: - Individual Prediction Methods

    private func predictNextFeed(_ events: [Event], hour: Int, babyAgeWeeks: Int) -> Prediction? {
        let recentFeeds = events
            .filter { $0.type == .feed }
            .filter { Calendar.current.isDateInToday($0.startTime) }
            .sorted { $0.startTime > $1.startTime }

        guard !recentFeeds.isEmpty else {
            // No feeds today, suggest based on typical schedule
            let typicalAmounts = getTypicalFeedAmounts(for: babyAgeWeeks)
            if let typicalAmount = typicalAmounts.first {
                return Prediction(
                    type: .feed(amount: typicalAmount.amount, unit: typicalAmount.unit, side: nil),
                    confidence: 0.7,
                    reason: "Typical first feed of the day"
                )
            }
            return nil
        }

        // Analyze recent feed patterns
        let lastFeed = recentFeeds.first!
        let timeSinceLastFeed = Date().timeIntervalSince(lastFeed.startTime) / 3600 // hours

        // If it's been 2-4 hours since last feed, suggest next feed
        if timeSinceLastFeed >= 2 && timeSinceLastFeed <= 4 {
            let averageAmount = recentFeeds.prefix(3).compactMap { $0.amount }.reduce(0, +) / Double(min(3, recentFeeds.count))

            // Predict side alternation for breastfed babies
            var predictedSide: String? = nil
            if let lastSide = lastFeed.subtype?.lowercased() {
                if lastSide.contains("left") {
                    predictedSide = "right"
                } else if lastSide.contains("right") {
                    predictedSide = "left"
                }
            }

            return Prediction(
                type: .feed(amount: averageAmount > 0 ? averageAmount : nil, unit: "oz", side: predictedSide),
                confidence: 0.8,
                reason: "Based on recent feeding pattern"
            )
        }

        // If it's been more than 4 hours, higher confidence for feeding
        if timeSinceLastFeed > 4 {
            return Prediction(
                type: .feed(amount: nil, unit: nil, side: nil),
                confidence: 0.9,
                reason: "Overdue for feeding"
            )
        }

        return nil
    }

    private func predictSleepStart(_ events: [Event], hour: Int) -> Prediction? {
        // Look for nap time patterns
        let todaySleeps = events
            .filter { $0.type == .sleep }
            .filter { Calendar.current.isDateInToday($0.startTime) }

        // Common nap times: morning (9-11), afternoon (1-3), evening (6-8)
        let isCommonNapTime = (hour >= 9 && hour <= 11) || (hour >= 13 && hour <= 15) || (hour >= 18 && hour <= 20)

        if isCommonNapTime && todaySleeps.count < 3 { // Haven't had too many naps today
            return Prediction(
                type: .sleep,
                confidence: 0.75,
                reason: "Common nap time based on schedule"
            )
        }

        // If awake for 1-2 hours after last nap ended
        if let lastSleepEnd = events
            .filter { $0.type == .sleep }
            .filter { $0.endTime != nil }
            .sorted { $0.endTime! > $1.endTime! }
            .first?.endTime {

            let awakeTime = Date().timeIntervalSince(lastSleepEnd) / 3600 // hours
            if awakeTime >= 1 && awakeTime <= 2 {
                return Prediction(
                    type: .sleep,
                    confidence: 0.85,
                    reason: "Typical awake time after last nap"
                )
            }
        }

        return nil
    }

    private func predictDiaperChange(_ events: [Event], hour: Int) -> Prediction? {
        let recentDiapers = events
            .filter { $0.type == .diaper }
            .filter { Calendar.current.isDateInToday($0.startTime) }
            .sorted { $0.startTime > $1.startTime }

        // If no diaper changes in last 3 hours, suggest one
        if let lastDiaper = recentDiapers.first {
            let timeSinceLast = Date().timeIntervalSince(lastDiaper.startTime) / 3600
            if timeSinceLast >= 3 {
                // Predict diaper type based on recent pattern
                let recentTypes = recentDiapers.prefix(3).compactMap { $0.subtype }
                let mostCommonType = recentTypes.mostCommon()

                return Prediction(
                    type: .diaper(type: mostCommonType),
                    confidence: 0.7,
                    reason: "Time for diaper change"
                )
            }
        } else {
            // No diapers logged today, suggest first one
            return Prediction(
                type: .diaper(type: "wet"),
                confidence: 0.6,
                reason: "First diaper of the day"
            )
        }

        return nil
    }

    private func predictTummyTime(_ events: [Event], hour: Int, babyAgeWeeks: Int) -> Prediction? {
        // Only suggest for babies old enough for tummy time (6+ weeks)
        guard babyAgeWeeks >= 6 else { return nil }

        let todayTummyTime = events
            .filter { $0.type == .tummy }
            .filter { Calendar.current.isDateInToday($0.startTime) }

        // If no tummy time today and it's a good time (morning/afternoon)
        if todayTummyTime.isEmpty && (hour >= 9 && hour <= 16) {
            return Prediction(
                type: .tummyTime,
                confidence: 0.65,
                reason: "Good time for tummy time practice"
            )
        }

        return nil
    }

    // MARK: - Helper Methods

    private func getTypicalFeedAmounts(for babyAgeWeeks: Int) -> [(amount: Double, unit: String)] {
        // Typical feeding amounts by age (in oz)
        if babyAgeWeeks < 2 {
            return [(2.0, "oz"), (3.0, "oz")]
        } else if babyAgeWeeks < 4 {
            return [(3.0, "oz"), (4.0, "oz")]
        } else if babyAgeWeeks < 6 {
            return [(4.0, "oz"), (5.0, "oz")]
        } else {
            return [(5.0, "oz"), (6.0, "oz")]
        }
    }
}

// MARK: - Array Extension for Most Common Element

extension Array where Element: Hashable {
    func mostCommon() -> Element? {
        let counts = reduce(into: [:]) { $0[$1, default: 0] += 1 }
        return counts.max(by: { $0.value < $1.value })?.key
    }
}