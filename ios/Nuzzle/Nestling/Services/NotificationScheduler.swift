import Foundation
import UserNotifications

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
        
        // Nap window actions
        let logSleepAction = UNNotificationAction(
            identifier: "LOG_SLEEP",
            title: "Start Sleep",
            options: [.foreground]
        )
        let napCategory = UNNotificationCategory(
            identifier: "NAP_WINDOW",
            actions: [logSleepAction, snooze30Action],
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
        
        center.setNotificationCategories([feedCategory, napCategory, diaperCategory])
    }
    
    // MARK: - Feed Reminders
    
    func scheduleFeedReminder(hours: Int, enabled: Bool, lastFeedTime: Date? = nil, quietHoursStart: Date? = nil, quietHoursEnd: Date? = nil) {
        center.removePendingNotificationRequests(withIdentifiers: ["feed_reminder"])
        
        guard enabled else { return }
        
        // Calculate time since last feed
        let hoursSinceLastFeed: Int
        if let lastFeed = lastFeedTime {
            hoursSinceLastFeed = Calendar.current.dateComponents([.hour], from: lastFeed, to: Date()).hour ?? 0
        } else {
            hoursSinceLastFeed = hours
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Feed Reminder"
        // Supportive, non-judgmental language
        content.body = "It's been about \(hoursSinceLastFeed) hours since the last feed"
        content.sound = .default
        content.categoryIdentifier = "FEED_REMINDER"
        // Deep link URL
        content.userInfo = ["deepLink": "nestling://log/feed"]
        
        // Track last notification time for deduplication
        UserDefaults.standard.set(Date(), forKey: "last_feed_notification")
        
        // Schedule recurring reminder every N hours
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Double(hours * 3600), repeats: true)
        let request = UNNotificationRequest(identifier: "feed_reminder", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                Logger.dataError("Failed to schedule feed reminder: \(error.localizedDescription)")
            } else {
                AnalyticsService.shared.track(event: "notif_type_enabled", properties: ["notif_type": "feed"])
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
                print("Failed to send test notification: \(error)")
            }
        }
    }
    
    // MARK: - Nap Window Alerts
    
    func scheduleNapWindowAlert(predictedTime: Date, enabled: Bool) {
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
        content.title = "Nap Window"
        // Supportive, probabilistic language
        content.body = "Nap window is starting soon based on your baby's age and patterns"
        content.sound = .default
        content.categoryIdentifier = "NAP_WINDOW"
        // Deep link URL
        content.userInfo = ["deepLink": "nestling://log/sleep"]
        
        // Track last notification time
        UserDefaults.standard.set(Date(), forKey: "last_nap_notification")
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: alertTime), repeats: false)
        let request = UNNotificationRequest(identifier: "nap_window_alert", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                Logger.dataError("Failed to schedule nap window alert: \(error.localizedDescription)")
            } else {
                AnalyticsService.shared.track(event: "notif_type_enabled", properties: ["notif_type": "nap"])
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
        content.title = "Diaper Check"
        // Supportive, non-judgmental language
        content.body = "It's been about \(hoursSinceLastDiaper) hours since the last diaper change"
        content.sound = .default
        content.categoryIdentifier = "DIAPER_REMINDER"
        // Deep link URL
        content.userInfo = ["deepLink": "nestling://log/diaper"]
        
        // Track last notification time for deduplication
        UserDefaults.standard.set(Date(), forKey: "last_diaper_notification")
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Double(hours * 3600), repeats: true)
        let request = UNNotificationRequest(identifier: "diaper_reminder", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                Logger.dataError("Failed to schedule diaper reminder: \(error.localizedDescription)")
            } else {
                AnalyticsService.shared.track(event: "notif_type_enabled", properties: ["notif_type": "diaper"])
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
            print("[Notifications] Trial warning date is in the past, skipping")
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
                print("[Notifications] Failed to schedule trial warning: \(error)")
            } else {
                print("[Notifications] Scheduled trial warning for \(notificationDate)")
            }
        }
    }
    
    /// Cancel trial warning notification
    func cancelTrialWarningNotification() {
        center.removePendingNotificationRequests(withIdentifiers: ["trial_warning_day5"])
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
    
    // MARK: - Test Notifications
    
    // Note: sendTestNotification is already defined above (line 35)
    // This duplicate was removed to fix the redeclaration error
    
    // MARK: - Cancel All
    
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }
}

