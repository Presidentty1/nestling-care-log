import AppIntents
import Foundation
import Nestling

struct QueryLastFeedIntent: AppIntent {
    static var title: LocalizedStringResource = "Time Since Last Feed"
    static var description = IntentDescription("Check how long ago your baby was last fed")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // Get recent events from shared data
        let events = SharedWidgetData.shared.getRecentEvents()

        // Find the most recent feed event
        let feedEvents = events.filter { $0.type == .feed }
        guard let lastFeed = feedEvents.sorted(by: { $0.startTime > $1.startTime }).first else {
            return .result(value: "No feeds logged yet")
        }

        let timeSince = Date().timeIntervalSince(lastFeed.startTime)
        let hours = Int(timeSince / 3600)
        let minutes = Int((timeSince.truncatingRemainder(dividingBy: 3600)) / 60)

        var timeString = ""
        if hours > 0 {
            timeString = "\(hours) hour\(hours == 1 ? "" : "s")"
            if minutes > 0 {
                timeString += " and \(minutes) minute\(minutes == 1 ? "" : "s")"
            }
        } else {
            timeString = "\(minutes) minute\(minutes == 1 ? "" : "s")"
        }

        let amount = lastFeed.amount != nil ? " (\(lastFeed.amount!) \(lastFeed.unit ?? "ml"))" : ""
        let response = "Last fed \(timeString) ago\(amount)"

        return .result(value: response)
    }
}

struct QueryLastDiaperIntent: AppIntent {
    static var title: LocalizedStringResource = "Time Since Last Diaper"
    static var description = IntentDescription("Check how long ago your baby was last changed")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let events = SharedWidgetData.shared.getRecentEvents()

        let diaperEvents = events.filter { $0.type == .diaper }
        guard let lastDiaper = diaperEvents.sorted(by: { $0.startTime > $1.startTime }).first else {
            return .result(value: "No diaper changes logged yet")
        }

        let timeSince = Date().timeIntervalSince(lastDiaper.startTime)
        let hours = Int(timeSince / 3600)
        let minutes = Int((timeSince.truncatingRemainder(dividingBy: 3600)) / 60)

        var timeString = ""
        if hours > 0 {
            timeString = "\(hours) hour\(hours == 1 ? "" : "s")"
            if minutes > 0 {
                timeString += " and \(minutes) minute\(minutes == 1 ? "" : "s")"
            }
        } else {
            timeString = "\(minutes) minute\(minutes == 1 ? "" : "s")"
        }

        let response = "Last diaper change \(timeString) ago"

        return .result(value: response)
    }
}

struct QueryLastSleepIntent: AppIntent {
    static var title: LocalizedStringResource = "Time Since Last Nap"
    static var description = IntentDescription("Check how long ago your baby last woke from a nap")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let events = SharedWidgetData.shared.getRecentEvents()

        let sleepEvents = events.filter { $0.type == .sleep && $0.endTime != nil }
        guard let lastSleep = sleepEvents.sorted(by: { ($0.endTime ?? $0.startTime) > ($1.endTime ?? $1.startTime) }).first else {
            return .result(value: "No completed naps logged yet")
        }

        guard let endTime = lastSleep.endTime else {
            return .result(value: "Baby is currently sleeping")
        }

        let timeSince = Date().timeIntervalSince(endTime)
        let hours = Int(timeSince / 3600)
        let minutes = Int((timeSince.truncatingRemainder(dividingBy: 3600)) / 60)

        var timeString = ""
        if hours > 0 {
            timeString = "\(hours) hour\(hours == 1 ? "" : "s")"
            if minutes > 0 {
                timeString += " and \(minutes) minute\(minutes == 1 ? "" : "s")"
            }
        } else {
            timeString = "\(minutes) minute\(minutes == 1 ? "" : "s")"
        }

        let duration = lastSleep.durationMinutes ?? 0
        let response = "Last nap ended \(timeString) ago (slept \(duration) minutes)"

        return .result(value: response)
    }
}

