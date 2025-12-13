import Foundation

/// Service providing contextual reassurance and support during difficult parenting phases
///
/// Detects challenging patterns and provides normalizing messages that:
/// - Acknowledge the difficulty without judgment
/// - Provide evidence-based context about typical baby behavior
/// - Suggest gentle next steps
/// - Direct to professional help when appropriate
class ReassuranceCopyService {
    static let shared = ReassuranceCopyService()

    enum Context: String {
        case firstLog
        case missedDay = "missed_day"
        case sleepEnded = "sleep_ended"
        case frequentWaking = "frequent_waking"
        case shortNaps = "short_naps"
        case clusterFeeding = "cluster_feeding"
        case cryingSpree = "crying_spree"
        case growthSpurt = "growth_spurt"
        case separationAnxiety = "separation_anxiety"
        case teething = "teething"
    }

    enum DifficultyPattern {
        case frequentNightWaking(count: Int, babyAgeWeeks: Int)
        case shortNaps(averageMinutes: Int, babyAgeWeeks: Int)
        case irregularFeeding(gapHours: Int, babyAgeWeeks: Int)
        case excessiveCrying(hoursPerDay: Double, babyAgeWeeks: Int)
        case missedLogging(days: Int)

        var context: Context {
            switch self {
            case .frequentNightWaking: return .frequentWaking
            case .shortNaps: return .shortNaps
            case .irregularFeeding: return .clusterFeeding
            case .excessiveCrying: return .cryingSpree
            case .missedLogging: return .missedDay
            }
        }
    }

    private init() {}

    /// Get reassurance message for a specific context
    func message(for context: Context, babyName: String = "your baby", babyAgeWeeks: Int? = nil) -> ReassuranceMessage {
        switch context {
        case .firstLog:
            return ReassuranceMessage(
                title: "Welcome to the journey! 🌟",
                message: "Every parent feels overwhelmed at first. You're already taking great steps by tracking.",
                encouragement: "Remember: perfect parenting doesn't exist. You're doing your best, and that's enough.",
                actionText: "Keep logging - patterns will emerge"
            )

        case .missedDay:
            return ReassuranceMessage(
                title: "It's okay to miss a day",
                message: "Life with a new baby is unpredictable. One missed day doesn't erase your progress.",
                encouragement: "Every logged day helps build better predictions. Pick up whenever you're ready.",
                actionText: "Log when you can - no pressure"
            )

        case .sleepEnded:
            return ReassuranceMessage(
                title: "Sleep session ended",
                message: "All sleep sessions end eventually. This is normal and expected.",
                encouragement: "Each sleep session, no matter how short, helps your baby's development.",
                actionText: "Ready for the next nap opportunity"
            )

        case .frequentWaking:
            let ageContext = getAgeAppropriateContext(babyAgeWeeks, for: .frequentWaking)
            return ReassuranceMessage(
                title: "Frequent waking is normal",
                message: ageContext,
                encouragement: "This phase will pass. Your consistent care is building a secure foundation.",
                actionText: "Track the wakings to spot patterns",
                showHelpLink: babyAgeWeeks.map { $0 < 12 } ?? false // Show for babies under 3 months
            )

        case .shortNaps:
            let ageContext = getAgeAppropriateContext(babyAgeWeeks, for: .shortNaps)
            return ReassuranceMessage(
                title: "Short naps are common",
                message: ageContext,
                encouragement: "Nap length varies greatly. Focus on quality over quantity.",
                actionText: "Look for nap timing patterns"
            )

        case .clusterFeeding:
            return ReassuranceMessage(
                title: "Cluster feeding is normal",
                message: "Babies often feed more frequently during growth spurts or developmental leaps. This is temporary.",
                encouragement: "Your body knows what your baby needs. Trust the process.",
                actionText: "Track feeding to see when it eases"
            )

        case .cryingSpree:
            return ReassuranceMessage(
                title: "Crying peaks are normal",
                message: "All babies have crying peaks, often in the evening. This usually improves by 6-8 weeks.",
                encouragement: "Your responsive care is exactly what your baby needs right now.",
                actionText: "Try logging crying patterns",
                showHelpLink: babyAgeWeeks.map { $0 < 8 } ?? false // Show for babies under 2 months
            )

        case .growthSpurt:
            return ReassuranceMessage(
                title: "Growth spurts can be intense",
                message: "Increased feeding and fussiness often signal a growth spurt. This typically lasts 2-3 days.",
                encouragement: "You're fueling important development. This phase will pass.",
                actionText: "Extra feeds are helping growth"
            )

        case .separationAnxiety:
            return ReassuranceMessage(
                title: "Separation anxiety is a milestone",
                message: "Around 6-9 months, babies often become more aware of separation. This shows healthy attachment.",
                encouragement: "Your consistent presence builds security. This phase will evolve.",
                actionText: "Comfort and consistency help"
            )

        case .teething:
            return ReassuranceMessage(
                title: "Teething discomfort is temporary",
                message: "Teething symptoms vary widely. Some babies sail through, others need extra comfort.",
                encouragement: "This phase will pass. Your comfort helps your baby through it.",
                actionText: "Track symptoms to see improvement"
            )
        }
    }

    /// Detect difficulty patterns from recent event data
    func detectDifficultyPatterns(events: [Event], baby: Baby) -> [DifficultyPattern] {
        var patterns: [DifficultyPattern] = []
        let babyAgeWeeks = Calendar.current.dateComponents([.weekOfYear], from: baby.dateOfBirth, to: Date()).weekOfYear ?? 0

        // Analyze last 24 hours for acute patterns
        let last24Hours = Date().addingTimeInterval(-24 * 60 * 60)
        let recentEvents = events.filter { $0.startTime > last24Hours }

        // Check for frequent waking
        let sleepEvents = recentEvents.filter { $0.type == .sleep }
        if !sleepEvents.isEmpty {
            let totalWakes = sleepEvents.count - 1 // Subtract the current sleep if it's ongoing
            if totalWakes >= 5 {
                patterns.append(.frequentNightWaking(count: totalWakes, babyAgeWeeks: babyAgeWeeks))
            }
        }

        // Check for short naps
        let completedNaps = sleepEvents.filter { $0.endTime != nil }
        if !completedNaps.isEmpty {
            let avgNapMinutes = completedNaps.reduce(0) { sum, event in
                let duration = event.endTime!.timeIntervalSince(event.startTime) / 60
                return sum + duration
            } / Double(completedNaps.count)

            if avgNapMinutes < 30 && babyAgeWeeks > 4 { // Short naps concerning after 1 month
                patterns.append(.shortNaps(averageMinutes: Int(avgNapMinutes), babyAgeWeeks: babyAgeWeeks))
            }
        }

        // Check for irregular feeding
        let feedEvents = recentEvents.filter { $0.type == .feed }
        if feedEvents.count >= 2 {
            let sortedFeeds = feedEvents.sorted { $0.startTime < $1.startTime }
            var gaps: [TimeInterval] = []

            for i in 1..<sortedFeeds.count {
                let gap = sortedFeeds[i].startTime.timeIntervalSince(sortedFeeds[i-1].startTime)
                gaps.append(gap)
            }

            if let maxGap = gaps.max(), maxGap > 6 * 60 * 60 { // 6+ hour gap
                patterns.append(.irregularFeeding(gapHours: Int(maxGap / 3600), babyAgeWeeks: babyAgeWeeks))
            }
        }

        // Check for excessive crying (if cry events exist)
        let cryEvents = recentEvents.filter { $0.type == .cry }
        if !cryEvents.isEmpty {
            let totalCryMinutes = cryEvents.reduce(0) { sum, event in
                if let endTime = event.endTime {
                    return sum + endTime.timeIntervalSince(event.startTime) / 60
                }
                return sum
            }

            if totalCryMinutes > 180 { // 3+ hours of crying
                patterns.append(.excessiveCrying(hoursPerDay: totalCryMinutes / 60, babyAgeWeeks: babyAgeWeeks))
            }
        }

        // Check for missed logging days
        let lastWeek = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        let weekEvents = events.filter { $0.startTime > lastWeek }
        let daysWithEvents = Set(weekEvents.map { Calendar.current.startOfDay(for: $0.startTime) })
        let totalDays = 7
        let daysWithoutEvents = totalDays - daysWithEvents.count

        if daysWithoutEvents >= 2 {
            patterns.append(.missedLogging(days: daysWithoutEvents))
        }

        return patterns
    }

    /// Get age-appropriate context for difficulty patterns
    private func getAgeAppropriateContext(_ babyAgeWeeks: Int?, for pattern: Context) -> String {
        guard let age = babyAgeWeeks else {
            return "This is common at your baby's age."
        }

        switch pattern {
        case .frequentWaking:
            if age < 8 { // 2 months
                return "Newborns wake frequently for feeding. 4-6 wakings per night are completely normal."
            } else if age < 16 { // 4 months
                return "At this age, 2-4 night wakings are typical as sleep cycles develop."
            } else {
                return "Most babies consolidate sleep between 4-6 months, but every baby is different."
            }

        case .shortNaps:
            if age < 12 { // 3 months
                return "Short naps are common before 3 months. Focus on total daily sleep rather than nap length."
            } else {
                return "Nap patterns vary widely. Some babies take short, frequent naps; others prefer longer ones."
            }

        default:
            return "Every baby develops at their own pace. This is a normal phase."
        }
    }

    /// Should we show reassurance for detected patterns?
    func shouldShowReassurance(for patterns: [DifficultyPattern]) -> Bool {
        // Don't overwhelm with too many messages
        let lastReassuranceTime = UserDefaults.standard.double(forKey: "last_reassurance_shown")
        let hoursSinceLast = (Date().timeIntervalSince1970 - lastReassuranceTime) / 3600

        return !patterns.isEmpty && hoursSinceLast > 12 // Max once per 12 hours
    }

    /// Mark reassurance as shown
    func markReassuranceShown() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "last_reassurance_shown")
    }
}

/// Structure for reassurance messages
struct ReassuranceMessage {
    let title: String
    let message: String
    let encouragement: String
    let actionText: String?
    let showHelpLink: Bool = false

    var fullMessage: String {
        """
        \(title)

        \(message)

        \(encouragement)
        """
    }
}
