import Foundation
import WidgetKit

/// Manages sharing data with widgets through App Groups
class WidgetDataManager {
    static let shared = WidgetDataManager()

    private let appGroupId = "group.com.nestling.app"

    private init() {}

    // MARK: - Data Sharing Methods

    /// Share active baby with widgets
    func shareActiveBaby(_ baby: Baby) {
        SharedWidgetData.shared.saveActiveBaby(baby)
    }

    /// Share predictions with widgets
    func sharePredictions(_ predictions: [Prediction]) {
        SharedWidgetData.shared.savePredictions(predictions)
    }

    /// Share recent events with widgets (last 7 days)
    func shareRecentEvents(_ events: [Event]) {
        // Filter to recent events (last 7 days)
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentEvents = events.filter { $0.startTime >= sevenDaysAgo }

        // Limit to last 100 events to avoid storage issues
        let limitedEvents = recentEvents.sorted(by: { $0.startTime > $1.startTime }).prefix(100)

        SharedWidgetData.shared.saveRecentEvents(Array(limitedEvents))
    }

    /// Clear all shared data (useful for logout)
    func clearSharedData() {
        // Note: SharedWidgetData methods would need to be extended for clearing
        // For now, we'll reload widgets which will show empty states
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Reload all widget timelines
    func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - Integration Points

extension WidgetDataManager {
    /// Called when user switches babies
    func onBabySwitched(_ baby: Baby) {
        shareActiveBaby(baby)
    }

    /// Called when predictions are updated
    func onPredictionsUpdated(_ predictions: [Prediction]) {
        sharePredictions(predictions)
    }

    /// Called when events are created/updated/deleted
    func onEventsChanged(_ events: [Event]) {
        shareRecentEvents(events)
    }

    /// Called when user logs out
    func onUserLoggedOut() {
        clearSharedData()
    }
}

