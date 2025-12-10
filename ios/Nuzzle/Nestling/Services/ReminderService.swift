import Foundation
import UIKit
import UserNotifications

/// Service for scheduling and managing local notifications for reminders
@MainActor
class ReminderService {
    static let shared = ReminderService()
    
    var authorizationStatus: UNAuthorizationStatus = .notDetermined
    var remindersPaused = false
    var quietHoursStart: Date?
    var quietHoursEnd: Date?
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private init() {
        checkAuthorizationStatus()
        
        // Listen for authorization changes
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.checkAuthorizationStatus()
        }
    }
    
    // MARK: - Authorization
    
    func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            Task { @MainActor in
                self?.authorizationStatus = settings.authorizationStatus
            }
        }
    }
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            authorizationStatus = granted ? .authorized : .denied
            return granted
        } catch {
            print("Failed to request notification authorization: \(error)")
            return false
        }
    }
    
    func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }

    func updatePausedState(_ paused: Bool) async {
        remindersPaused = paused
        if paused {
            // Cancel all existing reminders when paused
            cancelAllReminders(babyId: nil)
        }
    }
    
    func updateQuietHours(start: Date?, end: Date?) {
        quietHoursStart = start
        quietHoursEnd = end
    }
    
    // MARK: - Feed Reminders
    
    func scheduleFeedReminder(babyId: UUID, hoursSinceLastFeed: Double, reminderHours: Int) async {
        guard authorizationStatus == .authorized else { return }
        guard !remindersPaused else { return }
        guard !isQuietHours(Date(), start: quietHoursStart, end: quietHoursEnd) else { return }
        
        // Stagger if another reminder is already queued within 5 minutes
        let triggerTime: TimeInterval = hasPendingWithin(minutes: 5) ? 5 * 60 : 60
        
        // Cancel existing feed reminder
        cancelFeedReminder(babyId: babyId)
        
        // Calculate when to remind (if time since last feed > reminder hours)
        guard hoursSinceLastFeed >= Double(reminderHours) else { return }
        
        // Remind immediately (already past threshold)
        let content = UNMutableNotificationContent()
        content.title = "Feed Reminder"
        content.body = "It's been \(Int(hoursSinceLastFeed)) hours since last feed for \(babyName(for: babyId))"
        content.sound = .default
        content.categoryIdentifier = "FEED_REMINDER"
        content.userInfo = [
            "type": "feed",
            "babyId": babyId.uuidString
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: triggerTime, repeats: false)
        let request = UNNotificationRequest(
            identifier: "feed_reminder_\(babyId.uuidString)",
            content: content,
            trigger: trigger
        )
        
        try? await notificationCenter.add(request)
    }
    
    func cancelFeedReminder(babyId: UUID) {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: ["feed_reminder_\(babyId.uuidString)"]
        )
    }
    
    // MARK: - Nap Window Reminders
    
    func scheduleNapWindowReminder(babyId: UUID, windowStart: Date, windowEnd: Date, reminderAtMidpoint: Bool = false) async {
        guard authorizationStatus == .authorized else { return }
        guard !remindersPaused else { return }
        guard !isQuietHours(windowStart, start: quietHoursStart, end: quietHoursEnd) else { return }
        
        // Cancel existing nap reminders
        cancelNapWindowReminders(babyId: babyId)
        
        let now = Date()
        guard windowStart > now else { return } // Only schedule if window hasn't started
        
        // Reminder at window start
        let startContent = UNMutableNotificationContent()
        startContent.title = "Nap Window"
        startContent.body = "It's time for \(babyName(for: babyId))'s next nap window"
        startContent.sound = .default
        startContent.categoryIdentifier = "NAP_REMINDER"
        startContent.userInfo = [
            "type": "nap",
            "babyId": babyId.uuidString,
            "windowStart": windowStart.timeIntervalSince1970,
            "windowEnd": windowEnd.timeIntervalSince1970
        ]
        
        let startTrigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: windowStart),
            repeats: false
        )
        
        let startRequest = UNNotificationRequest(
            identifier: "nap_window_start_\(babyId.uuidString)",
            content: startContent,
            trigger: startTrigger
        )
        
        try? await notificationCenter.add(startRequest)
        
        // Optional reminder at window midpoint
        if reminderAtMidpoint {
            let midpoint = Date(timeIntervalSince1970: (windowStart.timeIntervalSince1970 + windowEnd.timeIntervalSince1970) / 2)
            guard midpoint > now else { return }
            guard !isQuietHours(midpoint, start: quietHoursStart, end: quietHoursEnd) else { return }
            let triggerDelay: TimeInterval = hasPendingWithin(minutes: 5) ? 5 * 60 : 60
            
            let midpointContent = UNMutableNotificationContent()
            midpointContent.title = "Nap Window"
            midpointContent.body = "\(babyName(for: babyId))'s nap window is halfway through"
            midpointContent.sound = .default
            midpointContent.categoryIdentifier = "NAP_REMINDER"
            midpointContent.userInfo = [
                "type": "nap_midpoint",
                "babyId": babyId.uuidString
            ]
            
            let midpointTrigger = UNTimeIntervalNotificationTrigger(timeInterval: triggerDelay, repeats: false)
            
            let midpointRequest = UNNotificationRequest(
                identifier: "nap_window_midpoint_\(babyId.uuidString)",
                content: midpointContent,
                trigger: midpointTrigger
            )
            
            try? await notificationCenter.add(midpointRequest)
        }
    }
    
    func cancelNapWindowReminders(babyId: UUID) {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [
                "nap_window_start_\(babyId.uuidString)",
                "nap_window_midpoint_\(babyId.uuidString)"
            ]
        )
    }
    
    // MARK: - Diaper Reminders
    
    func scheduleDiaperReminder(babyId: UUID, hoursSinceLastDiaper: Double, reminderHours: Int) async {
        guard authorizationStatus == .authorized else { return }
        guard !remindersPaused else { return }
        guard !isQuietHours(Date(), start: quietHoursStart, end: quietHoursEnd) else { return }
        
        let triggerTime: TimeInterval = hasPendingWithin(minutes: 5) ? 5 * 60 : 60
        
        // Cancel existing diaper reminder
        cancelDiaperReminder(babyId: babyId)
        
        // Calculate when to remind (if time since last diaper > reminder hours)
        guard hoursSinceLastDiaper >= Double(reminderHours) else { return }
        
        // Remind immediately (already past threshold)
        let content = UNMutableNotificationContent()
        content.title = "Diaper Check"
        content.body = "It's been \(Int(hoursSinceLastDiaper)) hours since \(babyName(for: babyId))'s last diaper change"
        content.sound = .default
        content.categoryIdentifier = "DIAPER_REMINDER"
        content.userInfo = [
            "type": "diaper",
            "babyId": babyId.uuidString
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: triggerTime, repeats: false)
        let request = UNNotificationRequest(
            identifier: "diaper_reminder_\(babyId.uuidString)",
            content: content,
            trigger: trigger
        )
        
        try? await notificationCenter.add(request)
    }
    
    func cancelDiaperReminder(babyId: UUID) {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: ["diaper_reminder_\(babyId.uuidString)"]
        )
    }
    
    // MARK: - Quiet Hours
    
    private func isQuietHours(_ date: Date, start: Date?, end: Date?) -> Bool {
        guard let start = start, let end = end else { return false }
        
        let calendar = Calendar.current
        let nowComponents = calendar.dateComponents([.hour, .minute], from: date)
        let startComponents = calendar.dateComponents([.hour, .minute], from: start)
        let endComponents = calendar.dateComponents([.hour, .minute], from: end)
        
        let nowMinutes = (nowComponents.hour ?? 0) * 60 + (nowComponents.minute ?? 0)
        let startMinutes = (startComponents.hour ?? 0) * 60 + (startComponents.minute ?? 0)
        let endMinutes = (endComponents.hour ?? 0) * 60 + (endComponents.minute ?? 0)
        
        // Handle overnight quiet hours (e.g., 10 PM - 7 AM)
        if startMinutes > endMinutes {
            return nowMinutes >= startMinutes || nowMinutes < endMinutes
        } else {
            return nowMinutes >= startMinutes && nowMinutes < endMinutes
        }
    }
    
    func shouldSendReminder(_ date: Date, quietHoursStart: Date?, quietHoursEnd: Date?) -> Bool {
        return !isQuietHours(date, start: quietHoursStart, end: quietHoursEnd)
    }
    
    private func babyName(for babyId: UUID) -> String {
        // Placeholder: real implementation could cache baby profiles
        return "your baby"
    }

    private func hasPendingWithin(minutes: Int) -> Bool {
        let threshold = Double(minutes * 60)
        var found = false
        let semaphore = DispatchSemaphore(value: 0)
        notificationCenter.getPendingNotificationRequests { requests in
            let now = Date()
            found = requests.contains { request in
                if let trigger = request.trigger as? UNTimeIntervalNotificationTrigger {
                    return trigger.timeInterval < threshold
                }
                if let trigger = request.trigger as? UNCalendarNotificationTrigger,
                   let next = trigger.nextTriggerDate() {
                    return next.timeIntervalSince(now) < threshold
                }
                return false
            }
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .now() + 1)
        return found
    }
    
    // MARK: - Cancel All
    
    func cancelAllReminders(babyId: UUID?) {
        guard let babyId = babyId else {
            // If no babyId provided, we can't cancel specific reminders
            // The pause functionality prevents new reminders from being scheduled
            return
        }
        cancelFeedReminder(babyId: babyId)
        cancelNapWindowReminders(babyId: babyId)
        cancelDiaperReminder(babyId: babyId)
    }
}

