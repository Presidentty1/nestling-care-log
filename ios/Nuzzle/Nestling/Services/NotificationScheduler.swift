import Foundation
import UserNotifications
import OSLog

class NotificationScheduler {
    static let shared = NotificationScheduler()
    private let center = UNUserNotificationCenter.current()
    
    private init() {
        registerNotificationCategories()
    }
    
    // MARK: - Categories and Actions
    
    /// Register notification categories with actions
    private func registerNotificationCategories() {
        // Feed reminder actions
        let logFeedAction = UNNotificationAction(
            identifier: "LOG_FEED",
            title: "Log Feed",
            options: [.foreground]
        )
        let snooze30Action = UNNotificationAction(
            identifier: "SNOOZE_30",
            title: "Snooze 30 min",
            options: []
        )
        let feedCategory = UNNotificationCategory(
            identifier: "FEED_REMINDER",
            actions: [logFeedAction, snooze30Action],
            intentIdentifiers: [],
            options: []
        )
        
        // Nap window actions - Updated per plan
        let startNapAction = UNNotificationAction(
            identifier: "START_NAP",
            title: "Start Nap",
            options: [.foreground]
        )
        let snooze15Action = UNNotificationAction(
            identifier: "SNOOZE_15",
            title: "Snooze 15min",
            options: []
        )
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "Dismiss",
            options: [.destructive]
        )
        let napCategory = UNNotificationCategory(
            identifier: "NAP_WINDOW",
            actions: [startNapAction, snooze15Action, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        // Diaper reminder actions
        let logDiaperAction = UNNotificationAction(
            identifier: "LOG_DIAPER",
            title: "Log Diaper",
            options: [.foreground]
        )
        let diaperCategory = UNNotificationCategory(
            identifier: "DIAPER_REMINDER",
            actions: [logDiaperAction, snooze30Action],
            intentIdentifiers: [],
            options: []
        )

        // Daily summary actions
        let viewSummaryAction = UNNotificationAction(
            identifier: "VIEW_SUMMARY",
            title: "View Summary",
            options: [.foreground]
        )
        let logNowAction = UNNotificationAction(
            identifier: "LOG_NOW",
            title: "Log Now",
            options: [.foreground]
        )
        let dailySummaryCategory = UNNotificationCategory(
            identifier: "DAILY_SUMMARY",
            actions: [viewSummaryAction, logNowAction],
            intentIdentifiers: [],
            options: []
        )

        // Weekly recap actions
        let seeInsightsAction = UNNotificationAction(
            identifier: "SEE_INSIGHTS",
            title: "See Insights",
            options: [.foreground]
        )
        let shareWeekAction = UNNotificationAction(
            identifier: "SHARE_WEEK",
            title: "Share Week",
            options: [.foreground]
        )
        let weeklyRecapCategory = UNNotificationCategory(
            identifier: "WEEKLY_RECAP",
            actions: [seeInsightsAction, shareWeekAction],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([
            feedCategory, napCategory, diaperCategory,
            dailySummaryCategory, weeklyRecapCategory
        ])
    }
    
    // MARK: - Feed Reminders
    
    func scheduleFeedReminder(hours: Int, enabled: Bool, babyName: String? = nil, lastFeedTime: Date? = nil, quietHoursStart: Date? = nil, quietHoursEnd: Date? = nil) {
        center.removePendingNotificationRequests(withIdentifiers: ["feed_reminder"])
        
        guard enabled else { return }
        
        // Quiet hours guard
        if isWithinQuietHours(start: quietHoursStart, end: quietHoursEnd) {
            Logger.dataInfo("Skipping feed reminder: within quiet hours")
            return
        }
        
        // Calculate time since last feed
        let hoursSinceLastFeed: Int
        if let lastFeed = lastFeedTime {
            hoursSinceLastFeed = Calendar.current.dateComponents([.hour], from: lastFeed, to: Date()).hour ?? 0
        } else {
            hoursSinceLastFeed = hours
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Hey there!"
        // Supportive, non-judgmental language
        let babyNameText = babyName ?? "your baby's"
        content.body = "It's been a bit since \(babyNameText) last feed. How's everyone doing?"
        content.sound = .default
        content.categoryIdentifier = "FEED_REMINDER"
        // Deep link URL
        content.userInfo = ["deepLink": "nestling://log/feed"]
        
        // Track last notification time for deduplication
        let now = Date()
        if let last = UserDefaults.standard.object(forKey: "last_feed_notification") as? Date {
            let minutes = Calendar.current.dateComponents([.minute], from: last, to: now).minute ?? 0
            // Deduplicate if a feed notification fired in the last 30 minutes
            if minutes < 30 {
                Logger.dataInfo("Skipping feed reminder: deduped (last \(minutes) mins)")
                return
            }
        }
        UserDefaults.standard.set(now, forKey: "last_feed_notification")
        
        // Schedule recurring reminder every N hours
        let initialFire = adjustedFireDate(base: now.addingTimeInterval(Double(hours * 3600)), quietHoursStart: quietHoursStart, quietHoursEnd: quietHoursEnd)
        let interval = max(initialFire.timeIntervalSince(now), 60) // minimum 60s safety
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: true)
        let request = UNNotificationRequest(identifier: "feed_reminder", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                Logger.dataError("Failed to schedule feed reminder: \(error.localizedDescription)")
            } else {
                Task { await Analytics.shared.log("notif_type_enabled", parameters: ["notif_type": "feed"]) }
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
                logger.debug("Failed to send test notification: \(error)")
            }
        }
    }
    
    // MARK: - Nap Window Alerts
    
    func scheduleNapWindowAlert(predictedTime: Date, enabled: Bool, babyName: String? = nil) {
        center.removePendingNotificationRequests(withIdentifiers: ["nap_window_alert"])
        
        guard enabled else { return }
        
        // Deduplication: Check if we sent a nap notification recently
        if let lastNapNotif = UserDefaults.standard.object(forKey: "last_nap_notification") as? Date {
            let minutesSince = Calendar.current.dateComponents([.minute], from: lastNapNotif, to: Date()).minute ?? 0
            if minutesSince < 60 {
                Logger.dataInfo("Skipping nap notification - sent recently")
                return
            }
        }
        
        // Schedule alert 15 minutes before predicted nap time
        let alertTime = predictedTime.addingTimeInterval(-15 * 60)
        guard alertTime > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Sweet dreams!"
        // Supportive, probabilistic language
        content.body = "Looks like a good time for \(babyName ?? "your baby") to nap. Ready to start?"
        content.sound = .default
        content.categoryIdentifier = "NAP_WINDOW"
        // Deep link URL
        content.userInfo = ["deepLink": "nestling://log/sleep"]
        
        // Track last notification time
        let now = Date()
        UserDefaults.standard.set(now, forKey: "last_nap_notification")
        
        let adjustedAlertTime = adjustedFireDate(base: alertTime, quietHoursStart: nil, quietHoursEnd: nil)
        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: adjustedAlertTime), repeats: false)
        let request = UNNotificationRequest(identifier: "nap_window_alert", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                Logger.dataError("Failed to schedule nap window alert: \(error.localizedDescription)")
            } else {
                Task { await Analytics.shared.log("notif_type_enabled", parameters: ["notif_type": "nap"]) }
            }
        }
    }
    
    // MARK: - Diaper Reminders
    
    func scheduleDiaperReminder(hours: Int, enabled: Bool, lastDiaperTime: Date? = nil) {
        center.removePendingNotificationRequests(withIdentifiers: ["diaper_reminder"])
        
        guard enabled else { return }
        
        // Calculate time since last diaper
        let hoursSinceLastDiaper: Int
        if let lastDiaper = lastDiaperTime {
            hoursSinceLastDiaper = Calendar.current.dateComponents([.hour], from: lastDiaper, to: Date()).hour ?? 0
        } else {
            hoursSinceLastDiaper = hours
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Time for a check?"
        // Supportive, non-judgmental language
        content.body = "It's been a few hours since the last diaper change. Want to check?"
        content.sound = .default
        content.categoryIdentifier = "DIAPER_REMINDER"
        // Deep link URL
        content.userInfo = ["deepLink": "nestling://log/diaper"]
        
        // Track last notification time for deduplication
        let now = Date()
        if let last = UserDefaults.standard.object(forKey: "last_diaper_notification") as? Date {
            let minutes = Calendar.current.dateComponents([.minute], from: last, to: now).minute ?? 0
            if minutes < 30 {
                Logger.dataInfo("Skipping diaper reminder: deduped (last \(minutes) mins)")
                return
            }
        }
        UserDefaults.standard.set(now, forKey: "last_diaper_notification")
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Double(hours * 3600), repeats: true)
        let request = UNNotificationRequest(identifier: "diaper_reminder", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                Logger.dataError("Failed to schedule diaper reminder: \(error.localizedDescription)")
            } else {
                Task { await Analytics.shared.log("notif_type_enabled", parameters: ["notif_type": "diaper"]) }
            }
        }
    }
    
    // MARK: - Trial Reminders
    
    /// Schedule notification for Day 5 of trial (2 days before expiration)
    func scheduleTrialWarningNotification(trialStartDate: Date) {
        center.removePendingNotificationRequests(withIdentifiers: ["trial_warning_day5"])
        
        // Calculate Day 5 (2 days before trial ends on Day 7)
        let day5Date = Calendar.current.date(byAdding: .day, value: 5, to: trialStartDate)!
        
        // Schedule for 10 AM on Day 5
        var components = Calendar.current.dateComponents([.year, .month, .day], from: day5Date)
        components.hour = 10
        components.minute = 0
        
        guard let notificationDate = Calendar.current.date(from: components),
              notificationDate > Date() else {
            logger.debug("[Notifications] Trial warning date is in the past, skipping")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Your trial ends in 2 days"
        content.body = "Upgrade now to keep tracking your baby's patterns and get personalized insights"
        content.sound = .default
        content.categoryIdentifier = "TRIAL_WARNING"
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate),
            repeats: false
        )
        let request = UNNotificationRequest(identifier: "trial_warning_day5", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                logger.debug("[Notifications] Failed to schedule trial warning: \(error)")
            } else {
                logger.debug("[Notifications] Scheduled trial warning for \(notificationDate)")
            }
        }
    }
    
    /// Cancel trial warning notification
    func cancelTrialWarningNotification() {
        center.removePendingNotificationRequests(withIdentifiers: ["trial_warning_day5"])
    }

    // MARK: - Success & Summary Notifications

    func scheduleSuccessNotification(title: String, body: String, deliveryTime: Date = Date().addingTimeInterval(60)) {
        guard PolishFeatureFlags.shared.richNotificationsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "DAILY_SUMMARY"
        content.userInfo = ["deepLink": "nestling://home/summary"]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: deliveryTime.timeIntervalSince(Date()), repeats: false)
        let request = UNNotificationRequest(identifier: "success_notification_\(UUID().uuidString)", content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                logger.error("Failed to schedule success notification: \(error)")
            }
        }
    }

    func scheduleWeeklyRecapNotification(babyName: String, weekNumber: Int, avgSleepHours: Double) {
        guard PolishFeatureFlags.shared.richNotificationsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Week \(weekNumber) Recap"
        content.body = "\(babyName) averaged \(String(format: "%.1f", avgSleepHours))h sleep. See your insights!"
        content.sound = .default
        content.categoryIdentifier = "WEEKLY_RECAP"
        content.userInfo = ["deepLink": "nestling://history/insights"]

        // Add chart attachment (placeholder - would need actual chart generation)
        // let attachment = try? UNNotificationAttachment(identifier: "weekly-chart", url: chartURL)
        // content.attachments = [attachment]

        // Schedule for Sunday evening
        let calendar = Calendar.current
        let now = Date()
        let nextSunday = calendar.nextDate(after: now, matching: DateComponents(weekday: 1), matchingPolicy: .nextTimePreservingSmallerComponents) ?? now
        let sundayEvening = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: nextSunday) ?? now

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: sundayEvening),
            repeats: false
        )

        let request = UNNotificationRequest(identifier: "weekly_recap_week_\(weekNumber)", content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                logger.error("Failed to schedule weekly recap: \(error)")
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
        
        _ = calendar.dateComponents([.hour, .minute], from: now)
        let startTime = calendar.date(bySettingHour: startComponents.hour ?? 0, minute: startComponents.minute ?? 0, second: 0, of: now) ?? now
        let endTime = calendar.date(bySettingHour: endComponents.hour ?? 0, minute: endComponents.minute ?? 0, second: 0, of: now) ?? now
        
        if startTime < endTime {
            return now >= startTime && now <= endTime
        } else {
            // Quiet hours span midnight
            return now >= startTime || now <= endTime
        }
    }
    
    private func adjustedFireDate(base: Date, quietHoursStart: Date?, quietHoursEnd: Date?) -> Date {
        guard let start = quietHoursStart, let end = quietHoursEnd else {
            return base
        }
        
        if isWithinQuietHours(start: start, end: end) {
            // Push to end of quiet window (today or next day)
            let calendar = Calendar.current
            let startComponents = calendar.dateComponents([.hour, .minute], from: start)
            let endComponents = calendar.dateComponents([.hour, .minute], from: end)
            let now = Date()
            let endToday = calendar.date(bySettingHour: endComponents.hour ?? 0, minute: endComponents.minute ?? 0, second: 0, of: now) ?? base
            if endToday > now {
                return endToday
            }
            // Quiet hours cross midnight; schedule at tomorrow's end time
            return calendar.date(byAdding: .day, value: 1, to: endToday) ?? base
        }
        
        return base
    }
    
    // MARK: - Test Notifications
    
    // Note: sendTestNotification is already defined above (line 35)
    // This duplicate was removed to fix the redeclaration error
    
    // MARK: - Cancel All
    
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Snooze Support

    /// Reschedule an existing notification content after a snooze interval.
    /// Used for actionable notifications (e.g., "Snooze 15min").
    func snooze(notification: UNNotification, minutes: Int) {
        let original = notification.request.content

        let content = UNMutableNotificationContent()
        content.title = original.title
        content.body = original.body
        content.sound = original.sound
        content.categoryIdentifier = original.categoryIdentifier
        content.userInfo = original.userInfo
        content.attachments = original.attachments

        // Mark as snoozed for analytics/debugging
        content.userInfo["snoozed_minutes"] = minutes

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(max(60, minutes * 60)), repeats: false)
        let request = UNNotificationRequest(
            identifier: "snoozed_\(original.categoryIdentifier)_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                logger.error("Failed to schedule snoozed notification: \(error)")
            } else {
                Task { await Analytics.shared.log("notif_snoozed_scheduled", parameters: [
                    "category": original.categoryIdentifier,
                    "minutes": minutes
                ]) }
            }
        }
    }
}

