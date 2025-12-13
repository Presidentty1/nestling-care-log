import Foundation

class ProactiveInsightsService {
    static let shared = ProactiveInsightsService()

    func generateDailyInsight(baby: Baby, events: [Event]) async -> String? {
        // Analyze patterns and generate insight
        let sleepEvents = events.filter { $0.type == .sleep }

        if let avgNapDuration = calculateAverageNapDuration(sleepEvents),
           avgNapDuration < previousWeekAverage() {
            return "I noticed \(baby.name)'s naps got shorter this week. This is common during growth spurts around \(baby.ageInWeeks) weeks."
        }

        if hasFeedingPatternImproved(events) {
            return "Great job! Feeding times are becoming more consistent this week."
        }

        return nil
    }

    private func calculateAverageNapDuration(_ sleepEvents: [Event]) -> Double? {
        let naps = sleepEvents.filter { ($0.durationMinutes ?? 0) < 180 } // Less than 3 hours = nap
        guard !naps.isEmpty else { return nil }
        let totalMinutes = naps.reduce(0) { $0 + ($1.durationMinutes ?? 0) }
        return Double(totalMinutes) / Double(naps.count)
    }

    private func previousWeekAverage() -> Double {
        // Placeholder - would calculate from historical data
        return 45.0 // 45 minutes average
    }

    private func hasFeedingPatternImproved(_ events: [Event]) -> Bool {
        // Check if feeding intervals are becoming more regular
        let feedEvents = events.filter { $0.type == .feed }.sorted { $0.startTime < $1.startTime }
        guard feedEvents.count >= 3 else { return false }

        // Simple check: if the last 3 feeds are within reasonable intervals
        return true // Placeholder logic
    }
}