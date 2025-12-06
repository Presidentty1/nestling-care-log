import Foundation
import UserNotifications

class NotificationScheduler {
    static let shared = NotificationScheduler()
    private let center = UNUserNotificationCenter.current()
    
    private init() {}
    
    // MARK: - Feed Reminders
    
    func scheduleFeedReminder(hours: Int, enabled: Bool, quietHoursStart: Date? = nil, quietHoursEnd: Date? = nil) {
        center.removePendingNotificationRequests(withIdentifiers: ["feed_reminder"])
        
        guard enabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Feed Reminder"
        content.body = "Time for a feed"
        content.sound = .default
        content.categoryIdentifier = "FEED_REMINDER"
        
        // Schedule recurring reminder every N hours
        // Note: Quiet hours check happens at notification delivery time (via notification delegate)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Double(hours * 3600), repeats: true)
        let request = UNNotificationRequest(identifier: "feed_reminder", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule feed reminder: \(error)")
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
        
        // Schedule alert 15 minutes before predicted nap time
        let alertTime = predictedTime.addingTimeInterval(-15 * 60)
        guard alertTime > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Nap Window Approaching"
        content.body = "Baby may be ready for a nap soon"
        content.sound = .default
        content.categoryIdentifier = "NAP_WINDOW"
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: alertTime), repeats: false)
        let request = UNNotificationRequest(identifier: "nap_window_alert", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule nap window alert: \(error)")
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
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Double(hours * 3600), repeats: true)
        let request = UNNotificationRequest(identifier: "diaper_reminder", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule diaper reminder: \(error)")
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
    
    // MARK: - Test Notifications
    
    // Note: sendTestNotification is already defined above (line 35)
    // This duplicate was removed to fix the redeclaration error
    
    // MARK: - Cancel All
    
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }
}

