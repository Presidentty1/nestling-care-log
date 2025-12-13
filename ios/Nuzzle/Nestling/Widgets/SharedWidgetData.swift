import Foundation
import WidgetKit

/// Shared data manager for widgets using App Groups
class SharedWidgetData {
    private static let appGroupId: String = {
        #if DEBUG
        return "group.com.nestling.app.dev"
        #else
        return "group.com.nestling.app"
        #endif
    }()
    private static let predictionsKey = "predictions"
    private static let eventsKey = "recentEvents"
    private static let babyKey = "activeBaby"

    static let shared = SharedWidgetData()

    private let userDefaults: UserDefaults?

    private init() {
        userDefaults = UserDefaults(suiteName: SharedWidgetData.appGroupId)
    }

    // MARK: - Baby Data

    func getActiveBaby() -> Baby? {
        guard let userDefaults = userDefaults,
              let babyData = userDefaults.data(forKey: SharedWidgetData.babyKey) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(Baby.self, from: babyData)
        } catch {
            logger.debug("Failed to decode baby data: \(error)")
            return nil
        }
    }

    func saveActiveBaby(_ baby: Baby) {
        guard let userDefaults = userDefaults else { return }

        do {
            let data = try JSONEncoder().encode(baby)
            userDefaults.set(data, forKey: SharedWidgetData.babyKey)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            logger.debug("Failed to encode baby data: \(error)")
        }
    }

    // MARK: - Predictions Data

    func getPredictions() -> [Prediction] {
        guard let userDefaults = userDefaults,
              let predictionsData = userDefaults.data(forKey: SharedWidgetData.predictionsKey) else {
            return []
        }

        do {
            return try JSONDecoder().decode([Prediction].self, from: predictionsData)
        } catch {
            logger.debug("Failed to decode predictions: \(error)")
            return []
        }
    }

    func savePredictions(_ predictions: [Prediction]) {
        guard let userDefaults = userDefaults else { return }

        do {
            let data = try JSONEncoder().encode(predictions)
            userDefaults.set(data, forKey: SharedWidgetData.predictionsKey)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            logger.debug("Failed to encode predictions: \(error)")
        }
    }

    // MARK: - Events Data

    func getRecentEvents() -> [Event] {
        guard let userDefaults = userDefaults,
              let eventsData = userDefaults.data(forKey: SharedWidgetData.eventsKey) else {
            return []
        }

        do {
            return try JSONDecoder().decode([Event].self, from: eventsData)
        } catch {
            logger.debug("Failed to decode events: \(error)")
            return []
        }
    }

    func saveRecentEvents(_ events: [Event]) {
        guard let userDefaults = userDefaults else { return }

        do {
            let data = try JSONEncoder().encode(events)
            userDefaults.set(data, forKey: SharedWidgetData.eventsKey)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            logger.debug("Failed to encode events: \(error)")
        }
    }

    // MARK: - Computed Data for Widgets

    func getNextNapPrediction() -> Prediction? {
        let predictions = getPredictions()
        return predictions.first { $0.type == .nextNap }
    }

    func getNextFeedPrediction() -> Prediction? {
        let predictions = getPredictions()
        return predictions.first { $0.type == .nextFeed }
    }

    func getTodaySummary() -> TodaySummary {
        let events = getRecentEvents()
        let today = Calendar.current.startOfDay(for: Date())

        let todayEvents = events.filter { event in
            let eventDate = Calendar.current.startOfDay(for: event.startTime)
            return eventDate == today
        }

        let feedCount = todayEvents.filter { $0.type == .feed }.count
        let diaperCount = todayEvents.filter { $0.type == .diaper }.count
        let sleepEvents = todayEvents.filter { $0.type == .sleep }

        let totalSleepMinutes = sleepEvents.compactMap { $0.durationMinutes }.reduce(0, +)
        let napCount = sleepEvents.filter { $0.subtype == "nap" }.count

        return TodaySummary(
            feedCount: feedCount,
            diaperCount: diaperCount,
            totalSleepMinutes: totalSleepMinutes,
            napCount: napCount
        )
    }

    func getSleepActivity() -> SleepActivity {
        let events = getRecentEvents()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayStart = Calendar.current.startOfDay(for: yesterday)
        let yesterdayEnd = Calendar.current.date(byAdding: .day, value: 1, to: yesterdayStart)!

        let yesterdayEvents = events.filter { event in
            return event.startTime >= yesterdayStart && event.startTime < yesterdayEnd
        }

        let sleepEvents = yesterdayEvents.filter { $0.type == .sleep }
        let totalSleepMinutes = sleepEvents.compactMap { $0.durationMinutes }.reduce(0, +)

        // Simple sleep quality calculation (can be enhanced)
        let quality: Double = min(Double(totalSleepMinutes) / (12.0 * 60.0), 1.0) // 12 hours as baseline

        return SleepActivity(
            totalMinutes: totalSleepMinutes,
            quality: quality,
            date: yesterday
        )
    }
}

// MARK: - Widget Data Structures

struct TodaySummary {
    let feedCount: Int
    let diaperCount: Int
    let totalSleepMinutes: Int
    let napCount: Int

    var totalSleepHours: Double {
        Double(totalSleepMinutes) / 60.0
    }
}

struct SleepActivity {
    let totalMinutes: Int
    let quality: Double // 0.0 - 1.0
    let date: Date

    var qualityText: String {
        switch quality {
        case 0.8...: return "Excellent"
        case 0.6...: return "Good"
        case 0.4...: return "Fair"
        default: return "Needs Work"
        }
    }

    var qualityColor: String {
        switch quality {
        case 0.8...: return "#10B981" // Green
        case 0.6...: return "#F59E0B" // Yellow
        case 0.4...: return "#F97316" // Orange
        default: return "#EF4444" // Red
        }
    }
}
