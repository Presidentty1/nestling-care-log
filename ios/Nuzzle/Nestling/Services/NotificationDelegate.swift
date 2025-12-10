import Foundation
import UserNotifications
import Combine

/// Notification delegate that handles quiet hours filtering
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    // Cache quiet hours settings
    private var quietHoursStart: Date?
    private var quietHoursEnd: Date?
    private var cancellables = Set<AnyCancellable>()
    
    private override init() {
        super.init()
        loadQuietHours()
        
        // Listen for settings changes
        NotificationCenter.default.publisher(for: NSNotification.Name("AppSettingsDidChange"))
            .sink { [weak self] _ in
                self?.loadQuietHours()
            }
            .store(in: &cancellables)
    }
    
    private func loadQuietHours() {
        // Load from UserDefaults - settings are stored there by AppEnvironment
        // We'll use a simple key-based approach
        if let startData = UserDefaults.standard.data(forKey: "appSettings_quietHoursStart"),
           let endData = UserDefaults.standard.data(forKey: "appSettings_quietHoursEnd") {
            let decoder = JSONDecoder()
            quietHoursStart = try? decoder.decode(Date.self, from: startData)
            quietHoursEnd = try? decoder.decode(Date.self, from: endData)
        } else {
            // Try alternative storage method
            quietHoursStart = UserDefaults.standard.object(forKey: "quietHoursStart") as? Date
            quietHoursEnd = UserDefaults.standard.object(forKey: "quietHoursEnd") as? Date
        }
    }
    
    /// Called when a notification is delivered while the app is in the foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Check if we should suppress this notification due to quiet hours
        if shouldSuppressNotification(notification) {
            // Suppress notification during quiet hours
            completionHandler([])
        } else {
            // Show notification with banner and sound
            completionHandler([.banner, .sound, .badge])
        }
    }
    
    /// Called when user interacts with a notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle notification interaction
        completionHandler()
    }
    
    /// Check if notification should be suppressed due to quiet hours
    private func shouldSuppressNotification(_ notification: UNNotification) -> Bool {
        // Check if reminders are paused globally
        if UserDefaults.standard.bool(forKey: "remindersPaused") {
            return true
        }
        
        // Reload quiet hours in case they changed
        loadQuietHours()
        
        // Check if current time is within quiet hours
        guard let start = quietHoursStart, let end = quietHoursEnd else {
            // No quiet hours configured - allow notification
            return false
        }
        
        return NotificationScheduler.shared.isWithinQuietHours(start: start, end: end)
    }
}

