import Foundation
import UserNotifications

class NotificationScheduler {
    static let shared = NotificationScheduler()
    private let center = UNUserNotificationCenter.current()

    private init() {
        setupNotificationCategories()
    }

    private func setupNotificationCategories() {
        // Define notification categories for better UX
        let feedCategory = UNNotificationCategory(
            identifier: "FEED_REMINDER",
            actions: [
                UNNotificationAction(identifier: "LOG_FEED", title: "Log Feed", options: .foreground),
                UNNotificationAction(identifier: "SNOOZE", title: "Remind Later", options: [])
            ],
            intentIdentifiers: [],
            options: []
        )

        let napCategory = UNNotificationCategory(
            identifier: "NAP_WINDOW",
            actions: [
                UNNotificationAction(identifier: "START_NAP", title: "Start Nap Timer", options: .foreground),
                UNNotificationAction(identifier: "SNOOZE_NAP", title: "Remind in 15 min", options: [])
            ],
            intentIdentifiers: [],
            options: []
        )

        let winBackCategory = UNNotificationCategory(
            identifier: "WIN_BACK",
            actions: [
                UNNotificationAction(identifier: "OPEN_APP", title: "Open Nestling", options: .foreground),
                UNNotificationAction(identifier: "DISMISS", title: "Not Now", options: [])
            ],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([feedCategory, napCategory, winBackCategory])
    }

    // MARK: - Nap Window Alerts

    /// Schedule nap window alert for upcoming nap prediction
    func scheduleNapWindowAlert(baby: Baby, napPrediction: Prediction, enabled: Bool) {
        center.removePendingNotificationRequests(withIdentifiers: ["nap_window_\(napPrediction.id)"])

        guard enabled else { return }
        guard NotificationRateLimiter.shared.canSendNotification(type: .nap) else {
            Logger.warning("Nap window alert rate limit exceeded")
            return
        }

        // Schedule notification 15 minutes before nap window starts
        let alertTime = napPrediction.predictedTime.addingTimeInterval(-15 * 60)

        // Don't schedule if alert time is in the past
        guard alertTime > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Nap window starting soon"
        // Epic 6 AC3: Non-prescriptive language
        let timeRange = "\(napPrediction.predictedTime.formatted(date: .omitted, time: .shortened))–\(napPrediction.predictedTime.addingTimeInterval(3600).formatted(date: .omitted, time: .shortened))"
        content.body = "Many babies this age start getting sleepy around \(timeRange). You can start a wind-down when you're ready."
        content.sound = .default
        content.categoryIdentifier = "NAP_WINDOW"
        content.userInfo = [
            "notification_type": "nap_window",
            "baby_id": baby.id.uuidString,
            "prediction_id": napPrediction.id.uuidString
        ]

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: alertTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: "nap_window_\(napPrediction.id)", content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                Logger.dataError("Failed to schedule nap window alert: \(error.localizedDescription)")
            } else {
                Logger.info("Scheduled nap window alert for \(alertTime)")
            }
        }
    }

    // MARK: - Intelligent Feed Reminders

    /// Schedule intelligent feed reminder based on baby's pattern
    func scheduleIntelligentFeedReminder(baby: Baby, dataStore: DataStore, enabled: Bool) async {
        center.removePendingNotificationRequests(withIdentifiers: ["intelligent_feed_reminder"])

        guard enabled else { return }
        guard NotificationRateLimiter.shared.canSendNotification(type: .feed) else {
            Logger.warning("Intelligent feed reminder rate limit exceeded")
            return
        }

        do {
            // Analyze recent feeding patterns to predict next feed time
            let now = Date()
            let weekAgo = now.addingTimeInterval(-7 * 24 * 3600)

            let recentFeeds = try await dataStore.fetchEvents(for: baby, from: weekAgo, to: now)
                .filter { $0.type == .feed }
                .sorted { $0.startTime > $1.startTime } // Most recent first

            guard recentFeeds.count >= 3 else {
                // Not enough data for intelligent reminders
                Logger.info("Not enough feed data for intelligent reminders (\(recentFeeds.count) feeds)")
                return
            }

            // Calculate average interval between feeds
            let intervals = zip(recentFeeds, recentFeeds.dropFirst()).map { $0.startTime.timeIntervalSince($1.startTime) }
            let avgInterval = intervals.reduce(0, +) / Double(intervals.count)

            // Only remind if interval is reasonable (2-6 hours)
            guard avgInterval >= 7200 && avgInterval <= 21600 else {
                Logger.info("Feed interval not in reasonable range: \(avgInterval / 3600) hours")
                return
            }

            let lastFeedTime = recentFeeds.first!.startTime
            let nextFeedTime = lastFeedTime.addingTimeInterval(avgInterval)

            // Don't schedule if next feed is too soon (less than 1 hour) or too far (more than 8 hours)
            let timeUntilNextFeed = nextFeedTime.timeIntervalSince(now)
            guard timeUntilNextFeed >= 3600 && timeUntilNextFeed <= 28800 else {
                Logger.info("Next feed time not in scheduleable range: \(timeUntilNextFeed / 3600) hours")
                return
            }

            let content = UNMutableNotificationContent()
            content.title = "Time since last feed"
            // Epic 6 AC4: Non-prescriptive language
            content.body = "Last feed was \(Int(timeUntilNextFeed / 3600)) hours ago. Common range for this age is 2–3 hours. You can offer a feed if your baby seems hungry."
            content.sound = .default
            content.categoryIdentifier = "FEED_REMINDER"
            content.userInfo = [
                "notification_type": "intelligent_feed_reminder",
                "baby_id": baby.id.uuidString,
                "pattern_based": true
            ]

            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: nextFeedTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

            let request = UNNotificationRequest(identifier: "intelligent_feed_reminder", content: content, trigger: trigger)

            center.add(request) { error in
                if let error = error {
                    Logger.dataError("Failed to schedule intelligent feed reminder: \(error.localizedDescription)")
                } else {
                    Logger.info("Scheduled intelligent feed reminder for \(nextFeedTime)")
                }
            }

        } catch {
            Logger.dataError("Failed to schedule intelligent feed reminder: \(error.localizedDescription)")
        }
    }

    // MARK: - Win-Back Notifications

    /// Schedule win-back notification for inactive users
    func scheduleWinBackNotification(baby: Baby, daysInactive: Int, lastActivity: Date) {
        let identifier = "win_back_\(daysInactive)days"

        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        guard NotificationRateLimiter.shared.canSendNotification(type: .winBack) else {
            Logger.warning("Win-back notification rate limit exceeded")
            return
        }

        // Schedule for morning (9 AM)
        let now = Date()
        var components = Calendar.current.dateComponents([.year, .month, .day], from: now)
        components.hour = 9
        components.minute = 0

        guard let scheduledTime = Calendar.current.date(from: components),
              scheduledTime > now else {
            // Schedule for tomorrow if it's already past 9 AM today
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
            components = Calendar.current.dateComponents([.year, .month, .day], from: tomorrow)
            components.hour = 9
            components.minute = 0
            guard let scheduledTime = Calendar.current.date(from: components) else { return }
        }

        let content = UNMutableNotificationContent()

        if daysInactive == 3 {
            content.title = "We miss seeing \(baby.name)'s updates!"
            content.body = "It's been a few days since your last log. How is \(baby.name) doing?"
        } else if daysInactive >= 7 {
            content.title = "Patterns may have changed"
            content.body = "\(baby.name) is growing fast! Check back for updated nap predictions and insights."
        } else {
            return // Don't send for other intervals
        }

        content.sound = .default
        content.categoryIdentifier = "WIN_BACK"
        content.userInfo = [
            "notification_type": "win_back",
            "baby_id": baby.id.uuidString,
            "days_inactive": daysInactive
        ]

        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: scheduledTime), repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                Logger.dataError("Failed to schedule win-back notification: \(error.localizedDescription)")
            } else {
                Logger.info("Scheduled win-back notification for \(scheduledTime)")
            }
        }
    }

    // MARK: - Cancellation Methods

    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    func cancelNotifications(for baby: Baby) {
        // Get all pending notifications and filter by baby
        center.getPendingNotificationRequests { requests in
            let babyNotifications = requests.filter { request in
                if let babyId = request.content.userInfo["baby_id"] as? String {
                    return babyId == baby.id.uuidString
                }
                return false
            }

            let identifiers = babyNotifications.map { $0.identifier }
            self.center.removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }
    
    // MARK: - Feed Reminders

    func scheduleFeedReminder(hours: Int, enabled: Bool, quietHoursStart: Date? = nil, quietHoursEnd: Date? = nil) {
        center.removePendingNotificationRequests(withIdentifiers: ["feed_reminder"])
        guard enabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "It might be time for a feed"
        content.body = "It's been about \(hours) hour\(hours == 1 ? "" : "s") since the last feed. If your baby seems hungry, you can try offering a feed."
        content.sound = .default
        content.categoryIdentifier = "FEED_REMINDER"
        content.userInfo = ["notification_type": "feed_reminder"]

        // Schedule recurring reminder every N hours
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Double(hours * 3600), repeats: true)
        let request = UNNotificationRequest(identifier: "feed_reminder", content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                Logger.dataError("Failed to schedule feed reminder: \(error.localizedDescription)")
            }
        }
    }

    /// Schedule feed reminder based on last feed time
    func scheduleFeedReminderFromLastFeed(lastFeedTime: Date, hours: Int, enabled: Bool) {
        center.removePendingNotificationRequests(withIdentifiers: ["feed_reminder"])

        guard enabled else { return }
        guard NotificationRateLimiter.shared.canSendNotification(type: .feed) else {
                Logger.warning("Feed reminder rate limit exceeded")
            return
        }

        let reminderTime = lastFeedTime.addingTimeInterval(Double(hours * 3600))

        // Don't schedule if reminder time is in the past
        guard reminderTime > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "It might be time for a feed"
        content.body = "It's been about \(hours) hour\(hours == 1 ? "" : "s") since the last feed. If your baby seems hungry, you can try offering a feed."
        content.sound = .default
        content.categoryIdentifier = "FEED_REMINDER"
        content.userInfo = ["notification_type": "feed_reminder"]

        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderTime), repeats: false)
        let request = UNNotificationRequest(identifier: "feed_reminder", content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                Logger.dataError("Failed to schedule feed reminder from last feed: \(error.localizedDescription)")
            } else {
                NotificationRateLimiter.shared.recordNotificationSent(type: .feed)
            }
        }
    }
    
    func sendTestNotification(category: String = "TEST") {
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "This is a test notification from Nestling"
        content.sound = .default
        content.categoryIdentifier = category
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "test_\(category)_\(Date().timeIntervalSince1970)", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                Logger.dataError("Failed to send test notification: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Nap Window Alerts

    func scheduleNapWindowAlert(predictedTime: Date, enabled: Bool, babyName: String? = nil) {
        center.removePendingNotificationRequests(withIdentifiers: ["nap_window_alert"])

        guard enabled else { return }
        guard NotificationRateLimiter.shared.canSendNotification(type: .nap) else {
                Logger.warning("Nap window alert rate limit exceeded")
            return
        }

        // Schedule alert 15 minutes before predicted nap time
        let alertTime = predictedTime.addingTimeInterval(-15 * 60)
        guard alertTime > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Nap window starting soon"
        // Epic 6 AC3: Non-prescriptive language
        let name = babyName ?? "your baby"
        content.body = "Many babies this age start getting sleepy around now based on \(name)'s age and last wake. You can start a wind-down when you're ready."
        content.sound = .default
        content.categoryIdentifier = "NAP_WINDOW"
        content.userInfo = ["notification_type": "nap_window"]

        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: alertTime), repeats: false)
        let request = UNNotificationRequest(identifier: "nap_window_alert", content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                Logger.dataError("Failed to schedule nap window alert: \(error.localizedDescription)")
            } else {
                NotificationRateLimiter.shared.recordNotificationSent(type: .nap)
            }
        }
    }
    
    // MARK: - Diaper Reminders

    func scheduleDiaperReminder(hours: Int, enabled: Bool) {
        center.removePendingNotificationRequests(withIdentifiers: ["diaper_reminder"])

        guard enabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Diaper Check"
        content.body = "Time to check diaper"
        content.sound = .default
        content.categoryIdentifier = "DIAPER_REMINDER"
        content.userInfo = ["notification_type": "diaper_reminder"]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Double(hours * 3600), repeats: true)
        let request = UNNotificationRequest(identifier: "diaper_reminder", content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                Logger.dataError("Failed to schedule diaper reminder: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Quiet Hours
    
    func isWithinQuietHours(start: Date?, end: Date?) -> Bool {
        guard let start = start, let end = end else { return false }
        
        let calendar = Calendar.current
        let now = Date()
        let startComponents = calendar.dateComponents([.hour, .minute], from: start)
        let endComponents = calendar.dateComponents([.hour, .minute], from: end)
        
        var nowComponents = calendar.dateComponents([.hour, .minute], from: now)
        let startTime = calendar.date(bySettingHour: startComponents.hour ?? 0, minute: startComponents.minute ?? 0, second: 0, of: now) ?? now
        let endTime = calendar.date(bySettingHour: endComponents.hour ?? 0, minute: endComponents.minute ?? 0, second: 0, of: now) ?? now
        
        if startTime < endTime {
            return now >= startTime && now <= endTime
        } else {
            // Quiet hours span midnight
            return now >= startTime || now <= endTime
        }
    }
    
    // MARK: - Test Notifications
    
    func sendTestNotification(category: String = "TEST") {
        sendTestNotification(category: category)
    }
    
    // MARK: - Cancel All
    
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }
}

