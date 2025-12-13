import Foundation

/// Insight Generation Service - Backend logic for daily insights and weekly summaries
/// Generates personalized, research-backed insights from user data
@MainActor
class InsightGenerationService {
    static let shared = InsightGenerationService()

    /// Generate today's most impactful insight
    /// Priority: Personal wins > Milestones > Patterns > Encouragement
    func generateDailyInsight(
        events: [Event],
        baby: Baby,
        historicalData: [Event]? = nil,
        isPro: Bool
    ) -> WinOfTheDayCard.DailyInsight? {

        let today = Calendar.current.startOfDay(for: Date())
        let todayEvents = events.filter { Calendar.current.isDate($0.startTime, inSameDayAs: today) }

        // 1. Check for concrete wins (most impactful)
        if let longestNap = findLongestNapWin(todayEvents: todayEvents, historicalData: historicalData) {
            return longestNap
        }

        // 2. Check streak milestones
        if let streak = checkStreakMilestone() {
            return streak
        }

        // 3. Check feeding consistency
        if let feedWin = checkFeedingConsistency(todayEvents: todayEvents, baby: baby) {
            return feedWin
        }

        // 4. Check diaper health indicators
        if let diaperWin = checkDiaperPattern(todayEvents: todayEvents) {
            return diaperWin
        }

        // 5. Pro-only: Pattern predictions
        if isPro, let pattern = detectFormingPattern(todayEvents: todayEvents, historicalData: historicalData) {
            return pattern
        }

        // 6. First-time user encouragement
        if todayEvents.count == 1 {
            let type = todayEvents.first?.type.displayName ?? "event"
            return .firstDataPoint(type: type)
        }

        return nil
    }

    /// Generate weekly summary with trends and comparisons
    func generateWeeklySummary(events: [Event], baby: Baby) -> WeekSummary? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Get this week's events (last 7 days)
        let weekStart = calendar.date(byAdding: .day, value: -6, to: today)!
        let thisWeekEvents = events.filter { $0.startTime >= weekStart && $0.startTime <= today }

        // Get last week's events for comparison
        let lastWeekStart = calendar.date(byAdding: .day, value: -13, to: today)!
        let lastWeekEnd = calendar.date(byAdding: .day, value: -7, to: today)!
        let lastWeekEvents = events.filter { $0.startTime >= lastWeekStart && $0.startTime <= lastWeekEnd }

        if thisWeekEvents.isEmpty {
            return nil
        }

        // Calculate averages for this week
        let thisWeekStats = calculateWeekStats(events: thisWeekEvents)

        // Build daily data array
        var dailyData: [WeekSummary.DayData] = []
        for dayOffset in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            let dayEvents = thisWeekEvents.filter { calendar.isDate($0.startTime, inSameDayAs: date) }

            let sleepMinutes = dayEvents
                .filter { $0.type == .sleep && $0.endTime != nil }
                .compactMap { $0.durationMinutes }
                .reduce(0, +)

            let feedCount = dayEvents.filter { $0.type == .feed }.count
            let diaperCount = dayEvents.filter { $0.type == .diaper }.count

            dailyData.append(WeekSummary.DayData(
                date: date,
                sleepHours: Double(sleepMinutes) / 60.0,
                feedCount: feedCount,
                diaperCount: diaperCount
            ))
        }

        return WeekSummary(
            avgSleepHours: thisWeekStats.avgSleepHours,
            avgFeeds: thisWeekStats.avgFeeds,
            avgDiapers: thisWeekStats.avgDiapers,
            dailyData: dailyData.reversed() // Show oldest to newest
        )
    }

    private func findLongestNapWin(todayEvents: [Event], historicalData: [Event]?) -> WinOfTheDayCard.DailyInsight? {
        let todayNaps = todayEvents.filter { $0.type == .sleep && $0.endTime != nil }
        guard let longestNap = todayNaps.max(by: { ($0.durationMinutes ?? 0) < ($1.durationMinutes ?? 0) }),
              let duration = longestNap.durationMinutes,
              duration > 30 else { return nil }

        // Calculate improvement vs average
        var improvementPercent = 0
        if let historical = historicalData {
            let avgNapMinutes = historical
                .filter { $0.type == .sleep && $0.endTime != nil }
                .compactMap { $0.durationMinutes }
                .reduce(0, +) / max(1, historical.filter { $0.type == .sleep }.count)

            if avgNapMinutes > 0 {
                improvementPercent = Int(((Double(duration) - Double(avgNapMinutes)) / Double(avgNapMinutes)) * 100)
            }
        }

        // Only show if there's meaningful improvement (>5%)
        if improvementPercent > 5 {
            return .longerNap(minutes: duration, percentageImprovement: improvementPercent)
        }

        return nil
    }

    private func checkStreakMilestone() -> WinOfTheDayCard.DailyInsight? {
        // This would integrate with streak tracking service
        // For now, return nil - will be implemented when streak service is available
        return nil
    }

    private func checkFeedingConsistency(todayEvents: [Event], baby: Baby) -> WinOfTheDayCard.DailyInsight? {
        let feeds = todayEvents.filter { $0.type == .feed }

        // Only show if we have multiple feeds (shows consistency)
        guard feeds.count >= 3 else { return nil }

        // Calculate average time between feeds
        let feedTimes = feeds.map { $0.startTime }.sorted()
        var intervals: [TimeInterval] = []
        for i in 1..<feedTimes.count {
            intervals.append(feedTimes[i].timeIntervalSince(feedTimes[i-1]))
        }

        let avgIntervalHours = intervals.reduce(0, +) / Double(intervals.count) / 3600.0

        // Determine if consistent based on baby's age
        let monthsOld = Calendar.current.dateComponents([.month], from: baby.dateOfBirth, to: Date()).month ?? 0

        var targetRange = ""
        var isConsistent = false

        if monthsOld < 3 {
            // Newborns: every 2-3 hours
            targetRange = "2-3 hours"
            isConsistent = avgIntervalHours >= 1.5 && avgIntervalHours <= 3.5
        } else if monthsOld < 6 {
            // 3-6 months: every 3-4 hours
            targetRange = "3-4 hours"
            isConsistent = avgIntervalHours >= 2.5 && avgIntervalHours <= 4.5
        } else {
            // 6+ months: every 4-6 hours
            targetRange = "4-6 hours"
            isConsistent = avgIntervalHours >= 3.0 && avgIntervalHours <= 6.5
        }

        if isConsistent {
            return .consistentFeeds(count: feeds.count, targetRange: targetRange)
        }

        return nil
    }

    private func checkDiaperPattern(todayEvents: [Event]) -> WinOfTheDayCard.DailyInsight? {
        let diapers = todayEvents.filter { $0.type == .diaper }

        // Need at least 3 diaper changes to analyze pattern
        guard diapers.count >= 3 else { return nil }

        let wetCount = diapers.filter { $0.subtype?.lowercased() == "wet" }.count
        let dirtyCount = diapers.filter { $0.subtype?.lowercased() == "dirty" }.count

        // Look for healthy pattern: mix of wet and dirty, not all one type
        let hasWet = wetCount > 0
        let hasDirty = dirtyCount > 0
        let ratio = Double(wetCount) / Double(dirtyCount)

        // Good pattern: some wet and some dirty, reasonable ratio
        if hasWet && hasDirty && ratio >= 0.5 && ratio <= 2.0 {
            return .goodDiaperPattern(wetCount: wetCount, dirtyCount: dirtyCount)
        }

        return nil
    }

    private func detectFormingPattern(todayEvents: [Event], historicalData: [Event]?) -> WinOfTheDayCard.DailyInsight? {
        guard let historical = historicalData, historical.count >= 10 else { return nil }

        // Simple pattern detection: consistent nap times
        let napTimes = historical
            .filter { $0.type == .sleep && $0.endTime != nil }
            .compactMap { $0.startTime }
            .map { Calendar.current.component(.hour, from: $0) * 60 + Calendar.current.component(.minute, from: $0) }

        // Check if nap times cluster around certain periods
        if napTimes.count >= 5 {
            // Simple clustering: if most naps are within 2 hour windows
            let sortedTimes = napTimes.sorted()
            var clusters: [[Int]] = []

            for time in sortedTimes {
                if let lastCluster = clusters.last, let lastTime = lastCluster.last, abs(time - lastTime) <= 120 {
                    clusters[clusters.count - 1].append(time)
                } else {
                    clusters.append([time])
                }
            }

            // If we have a strong cluster (at least 3 naps within 2 hours)
            if let mainCluster = clusters.max(by: { $0.count < $1.count }), mainCluster.count >= 3 {
                let confidence = min(95, mainCluster.count * 15) // Scale confidence with cluster strength
                return .predictedPattern(patternType: "nap", confidence: confidence)
            }
        }

        return nil
    }

    private func calculateWeekStats(events: [Event]) -> (avgSleepHours: Double, avgFeeds: Double, avgDiapers: Double) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekStart = calendar.date(byAdding: .day, value: -6, to: today)!

        var dailyStats: [(sleepHours: Double, feeds: Int, diapers: Int)] = []

        // Calculate stats for each of the last 7 days
        for dayOffset in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            let dayEvents = events.filter { calendar.isDate($0.startTime, inSameDayAs: date) }

            let sleepMinutes = dayEvents
                .filter { $0.type == .sleep && $0.endTime != nil }
                .compactMap { $0.durationMinutes }
                .reduce(0, +)

            let feeds = dayEvents.filter { $0.type == .feed }.count
            let diapers = dayEvents.filter { $0.type == .diaper }.count

            dailyStats.append((
                sleepHours: Double(sleepMinutes) / 60.0,
                feeds: feeds,
                diapers: diapers
            ))
        }

        // Calculate averages
        let totalDays = Double(dailyStats.count)
        let avgSleep = dailyStats.map { $0.sleepHours }.reduce(0, +) / totalDays
        let avgFeeds = Double(dailyStats.map { $0.feeds }.reduce(0, +)) / totalDays
        let avgDiapers = Double(dailyStats.map { $0.diapers }.reduce(0, +)) / totalDays

        return (avgSleep, avgFeeds, avgDiapers)
    }
}

// MARK: - Supporting Types

extension InsightGenerationService {
    struct WeekSummary {
        let avgSleepHours: Double
        let avgFeeds: Double
        let avgDiapers: Double
        let dailyData: [DayData]

        struct DayData: Identifiable {
            let id = UUID()
            let date: Date
            let sleepHours: Double
            let feedCount: Int
            let diaperCount: Int
        }
    }
}