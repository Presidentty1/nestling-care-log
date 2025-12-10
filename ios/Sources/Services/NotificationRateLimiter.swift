import Foundation

/// Manages notification rate limiting to prevent spam.
/// Tracks daily notification counts and enforces limits.
class NotificationRateLimiter {
    static let shared = NotificationRateLimiter()

    private let userDefaults = UserDefaults.standard
    private let maxNotificationsPerDay = 6
    private let maxNotificationsPerType = 3

    private enum Keys {
        static let lastResetDate = "notificationRateLimiter.lastResetDate"
        static let totalNotificationsToday = "notificationRateLimiter.totalNotificationsToday"
        static let feedNotificationsToday = "notificationRateLimiter.feedNotificationsToday"
        static let napNotificationsToday = "notificationRateLimiter.napNotificationsToday"
        static let diaperNotificationsToday = "notificationRateLimiter.diaperNotificationsToday"
    }

    private init() {
        resetIfNeeded()
    }

    // MARK: - Rate Limiting

    /// Check if a notification can be sent
    func canSendNotification(type: NotificationType) -> Bool {
        resetIfNeeded()

        let totalToday = getTotalNotificationsToday()

        // Check total daily limit
        if totalToday >= maxNotificationsPerDay {
            return false
        }

        // Check per-type limit
        switch type {
        case .feed:
            return getFeedNotificationsToday() < maxNotificationsPerType
        case .nap:
            return getNapNotificationsToday() < maxNotificationsPerType
        case .diaper:
            return getDiaperNotificationsToday() < maxNotificationsPerType
        }
    }

    /// Record that a notification was sent
    func recordNotificationSent(type: NotificationType) {
        resetIfNeeded()

        incrementTotalNotifications()
        incrementTypeNotifications(type)
    }

    // MARK: - Daily Reset

    private func resetIfNeeded() {
        let lastReset = userDefaults.object(forKey: Keys.lastResetDate) as? Date ?? Date.distantPast
        let calendar = Calendar.current

        if !calendar.isDate(lastReset, inSameDayAs: Date()) {
            // Reset counters for new day
            userDefaults.set(Date(), forKey: Keys.lastResetDate)
            userDefaults.set(0, forKey: Keys.totalNotificationsToday)
            userDefaults.set(0, forKey: Keys.feedNotificationsToday)
            userDefaults.set(0, forKey: Keys.napNotificationsToday)
            userDefaults.set(0, forKey: Keys.diaperNotificationsToday)
        }
    }

    // MARK: - Counters

    private func getTotalNotificationsToday() -> Int {
        return userDefaults.integer(forKey: Keys.totalNotificationsToday)
    }

    private func incrementTotalNotifications() {
        let current = getTotalNotificationsToday()
        userDefaults.set(current + 1, forKey: Keys.totalNotificationsToday)
    }

    private func getFeedNotificationsToday() -> Int {
        return userDefaults.integer(forKey: Keys.feedNotificationsToday)
    }

    private func getNapNotificationsToday() -> Int {
        return userDefaults.integer(forKey: Keys.napNotificationsToday)
    }

    private func getDiaperNotificationsToday() -> Int {
        return userDefaults.integer(forKey: Keys.diaperNotificationsToday)
    }

    private func incrementTypeNotifications(_ type: NotificationType) {
        let key: String
        let current: Int

        switch type {
        case .feed:
            key = Keys.feedNotificationsToday
            current = getFeedNotificationsToday()
        case .nap:
            key = Keys.napNotificationsToday
            current = getNapNotificationsToday()
        case .diaper:
            key = Keys.diaperNotificationsToday
            current = getDiaperNotificationsToday()
        }

        userDefaults.set(current + 1, forKey: key)
    }

    // MARK: - Debug Info

    /// Get current rate limit status (for debugging)
    func getDebugInfo() -> [String: Any] {
        resetIfNeeded()
        return [
            "total_today": getTotalNotificationsToday(),
            "feed_today": getFeedNotificationsToday(),
            "nap_today": getNapNotificationsToday(),
            "diaper_today": getDiaperNotificationsToday(),
            "max_per_day": maxNotificationsPerDay,
            "max_per_type": maxNotificationsPerType
        ]
    }
}

enum NotificationType {
    case feed
    case nap
    case diaper
}




