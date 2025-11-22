import Foundation

/// Service for generating personalized recommendations based on baby's patterns
class PersonalizedRecommendationsService {
    static let shared = PersonalizedRecommendationsService()

    /// Types of recommendations
    enum RecommendationType: String, Codable {
        case feedTiming = "feed_timing"
        case napRoutine = "nap_routine"
        case sleepSchedule = "sleep_schedule"
        case diaperChanges = "diaper_changes"
        case tummyTime = "tummy_time"
        case general = "general"

        var displayName: String {
            switch self {
            case .feedTiming: return "Feeding Pattern"
            case .napRoutine: return "Nap Routine"
            case .sleepSchedule: return "Sleep Schedule"
            case .diaperChanges: return "Diaper Changes"
            case .tummyTime: return "Tummy Time"
            case .general: return "General Tip"
            }
        }

        var iconName: String {
            switch self {
            case .feedTiming: return "drop.fill"
            case .napRoutine: return "moon.fill"
            case .sleepSchedule: return "bed.double.fill"
            case .diaperChanges: return "diaper"
            case .tummyTime: return "figure.roll"
            case .general: return "lightbulb.fill"
            }
        }
    }

    /// A personalized recommendation
    struct Recommendation: Identifiable, Codable {
        let id: String
        let type: RecommendationType
        let title: String
        let message: String
        let priority: Int // 1 = highest priority, 3 = lowest
        let actionable: Bool
        let createdAt: Date

        var isNew: Bool {
            Date().timeIntervalSince(createdAt) < 86400 // New for 24 hours
        }
    }

    /// Generate recommendations based on recent events
    func generateRecommendations(for baby: Baby, recentEvents: [Event]) async -> [Recommendation] {
        var recommendations: [Recommendation] = []

        // Get events from last 7 days
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentEvents = recentEvents.filter { $0.startTime >= sevenDaysAgo }

        // Feed timing recommendations
        if let feedRecommendation = generateFeedRecommendation(recentEvents: recentEvents) {
            recommendations.append(feedRecommendation)
        }

        // Nap routine recommendations
        if let napRecommendation = generateNapRecommendation(recentEvents: recentEvents) {
            recommendations.append(napRecommendation)
        }

        // Sleep schedule recommendations
        if let sleepRecommendation = generateSleepRecommendation(recentEvents: recentEvents) {
            recommendations.append(sleepRecommendation)
        }

        // Diaper change recommendations
        if let diaperRecommendation = generateDiaperRecommendation(recentEvents: recentEvents) {
            recommendations.append(diaperRecommendation)
        }

        // Tummy time recommendations
        if let tummyRecommendation = generateTummyTimeRecommendation(recentEvents: recentEvents) {
            recommendations.append(tummyRecommendation)
        }

        // General encouragement
        if recommendations.isEmpty {
            recommendations.append(generateGeneralRecommendation())
        }

        // Sort by priority (highest first)
        return recommendations.sorted { $0.priority < $1.priority }
    }

    private func generateFeedRecommendation(recentEvents: [Event]) -> Recommendation? {
        let feeds = recentEvents.filter { $0.type == .feed }

        guard feeds.count >= 3 else {
            return Recommendation(
                id: "feed_minimum_data",
                type: .feedTiming,
                title: "More feeding data needed",
                message: "Log a few more feeds and we'll help optimize timing.",
                priority: 3,
                actionable: false,
                createdAt: Date()
            )
        }

        // Calculate average feed interval
        let sortedFeeds = feeds.sorted { $0.startTime < $1.startTime }
        var intervals: [TimeInterval] = []

        for i in 1..<sortedFeeds.count {
            let interval = sortedFeeds[i].startTime.timeIntervalSince(sortedFeeds[i-1].startTime)
            intervals.append(interval)
        }

        guard let averageInterval = intervals.average() else { return nil }

        // Check if last feed was too long ago
        if let lastFeed = sortedFeeds.last {
            let hoursSinceLastFeed = Date().timeIntervalSince(lastFeed.startTime) / 3600

            if hoursSinceLastFeed > (averageInterval / 3600) * 1.5 {
                return Recommendation(
                    id: "feed_overdue",
                    type: .feedTiming,
                    title: "Consider an early feed",
                    message: "It's been longer than usual since the last feed. Your baby might be getting hungry.",
                    priority: 1,
                    actionable: true,
                    createdAt: Date()
                )
            }
        }

        // Suggest optimal timing based on patterns
        let hours = Int(averageInterval / 3600)
        let minutes = Int((averageInterval.truncatingRemainder(dividingBy: 3600)) / 60)

        return Recommendation(
            id: "feed_pattern",
            type: .feedTiming,
            title: "Feed pattern observed",
            message: "Your feeds are typically \(hours)h \(minutes)m apart. This seems like a good rhythm for your baby.",
            priority: 2,
            actionable: false,
            createdAt: Date()
        )
    }

    private func generateNapRecommendation(recentEvents: [Event]) -> Recommendation? {
        let naps = recentEvents.filter { $0.type == .sleep && ($0.subtype == "nap" || $0.endTime != nil) }

        guard naps.count >= 2 else { return nil }

        // Check for short naps
        let shortNaps = naps.filter { ($0.endTime?.timeIntervalSince($0.startTime) ?? 0) < 1800 } // < 30 min

        if Double(shortNaps.count) / Double(naps.count) > 0.5 {
            return Recommendation(
                id: "nap_short",
                type: .napRoutine,
                title: "Naps seem short",
                message: "Many naps are under 30 minutes. Try creating a calmer environment or adjusting wake windows.",
                priority: 1,
                actionable: true,
                createdAt: Date()
            )
        }

        // Check for consistent nap timing
        let napHours = naps.map { Calendar.current.component(.hour, from: $0.startTime) }
        let mostCommonHour = napHours.mostCommon()

        if let commonHour = mostCommonHour, napHours.filter({ $0 == commonHour }).count >= naps.count / 2 {
            let hourString = String(format: "%d:00", commonHour)
            return Recommendation(
                id: "nap_consistent",
                type: .napRoutine,
                title: "Consistent nap timing",
                message: "Most naps start around \(hourString). This consistency helps establish good sleep habits.",
                priority: 2,
                actionable: false,
                createdAt: Date()
            )
        }

        return nil
    }

    private func generateSleepRecommendation(recentEvents: [Event]) -> Recommendation? {
        let sleepEvents = recentEvents.filter { $0.type == .sleep }

        guard sleepEvents.count >= 3 else { return nil }

        // Calculate total sleep in last 24 hours
        let last24Hours = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let recentSleep = sleepEvents.filter { $0.startTime >= last24Hours }

        let totalSleepHours = recentSleep.reduce(0) { total, event in
            if let duration = event.endTime?.timeIntervalSince(event.startTime) {
                return total + duration / 3600
            }
            return total
        }

        // Age-based sleep recommendations (rough guidelines)
        let babyAgeMonths = 6 // TODO: Calculate from baby birth date

        let recommendedSleep: Double
        if babyAgeMonths < 3 {
            recommendedSleep = 16-18
        } else if babyAgeMonths < 6 {
            recommendedSleep = 14-16
        } else if babyAgeMonths < 12 {
            recommendedSleep = 13-15
        } else {
            recommendedSleep = 12-14
        }

        if totalSleepHours < recommendedSleep * 0.8 {
            return Recommendation(
                id: "sleep_low",
                type: .sleepSchedule,
                title: "Sleep seems low",
                message: "In the last 24 hours, your baby got about \(Int(totalSleepHours)) hours of sleep. Consider extending bedtime or adding nap time.",
                priority: 1,
                actionable: true,
                createdAt: Date()
            )
        } else if totalSleepHours > recommendedSleep * 1.2 {
            return Recommendation(
                id: "sleep_high",
                type: .sleepSchedule,
                title: "Good sleep amount",
                message: "Your baby is getting plenty of sleep (\(Int(totalSleepHours)) hours in 24 hours). Keep up the good work!",
                priority: 2,
                actionable: false,
                createdAt: Date()
            )
        }

        return nil
    }

    private func generateDiaperRecommendation(recentEvents: [Event]) -> Recommendation? {
        let diapers = recentEvents.filter { $0.type == .diaper }

        guard diapers.count >= 5 else { return nil }

        // Check for infrequent changes
        let sortedDiapers = diapers.sorted { $0.startTime < $1.startTime }

        if sortedDiapers.count >= 2 {
            let lastDiaper = sortedDiapers.last!
            let previousDiaper = sortedDiapers[sortedDiapers.count - 2]

            let hoursSinceChange = lastDiaper.startTime.timeIntervalSince(previousDiaper.startTime) / 3600

            if hoursSinceChange > 4 {
                return Recommendation(
                    id: "diaper_check",
                    type: .diaperChanges,
                    title: "Diaper check",
                    message: "It's been \(Int(hoursSinceChange)) hours since the last diaper change. Consider checking if your baby needs a change.",
                    priority: 2,
                    actionable: true,
                    createdAt: Date()
                )
            }
        }

        return nil
    }

    private func generateTummyTimeRecommendation(recentEvents: [Event]) -> Recommendation? {
        let tummyTimes = recentEvents.filter { $0.type == .tummyTime }

        // Encourage tummy time if none logged recently
        let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentTummyTimes = tummyTimes.filter { $0.startTime >= lastWeek }

        if recentTummyTimes.isEmpty {
            return Recommendation(
                id: "tummy_time_encourage",
                type: .tummyTime,
                title: "Try tummy time",
                message: "Tummy time helps build neck and core strength. Try 2-3 minutes, 2-3 times a day when your baby is awake and alert.",
                priority: 3,
                actionable: true,
                createdAt: Date()
            )
        }

        return nil
    }

    private func generateGeneralRecommendation() -> Recommendation {
        let encouragements = [
            "You're doing a great job tracking your baby's day!",
            "Every logged event helps us give better suggestions.",
            "Keep up the excellent work caring for your little one.",
            "Your consistency in logging will help spot patterns over time.",
            "You're building a beautiful record of your baby's early days."
        ]

        let randomEncouragement = encouragements.randomElement() ?? encouragements[0]

        return Recommendation(
            id: "general_encouragement",
            type: .general,
            title: "Keep going!",
            message: randomEncouragement,
            priority: 3,
            actionable: false,
            createdAt: Date()
        )
    }
}

// Helper extensions
private extension Array where Element == TimeInterval {
    func average() -> TimeInterval? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Double(count)
    }
}

private extension Array where Element: Hashable {
    func mostCommon() -> Element? {
        let counts = reduce(into: [:]) { counts, element in
            counts[element, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key
    }
}

