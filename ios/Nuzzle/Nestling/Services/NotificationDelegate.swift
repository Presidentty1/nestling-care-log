import Foundation
import UserNotifications
import Combine
import OSLog

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
            trackNotificationEvent(name: "notif_fired", notification: notification)
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
        let notification = response.notification
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            trackNotificationEvent(name: "notif_tap_opened", notification: notification)
            
            // Handle deep link routing
            let userInfo = notification.request.content.userInfo
            if let deepLinkString = userInfo["deepLink"] as? String,
               let deepLinkURL = URL(string: deepLinkString) {
                let route = DeepLinkRouter.parse(url: deepLinkURL)
                
                // Post notification to main app to handle deep link
                // The main app's NavigationCoordinator will handle this
                NotificationCenter.default.post(
                    name: NSNotification.Name("HandleDeepLink"),
                    object: nil,
                    userInfo: ["route": route]
                )
            } else {
                // Fallback: Open home tab if no deep link specified
                NotificationCenter.default.post(
                    name: NSNotification.Name("HandleDeepLink"),
                    object: nil,
                    userInfo: ["route": DeepLinkRoute.openHome]
                )
            }
        } else if response.actionIdentifier.lowercased().contains("snooze") {
            trackNotificationEvent(name: "notif_snoozed", notification: notification)

            // Reschedule a one-off snoozed reminder
            let minutes: Int
            switch response.actionIdentifier {
            case "SNOOZE_15":
                minutes = 15
            case "SNOOZE_30":
                minutes = 30
            default:
                // Best-effort parse: "SNOOZE_XX"
                let parts = response.actionIdentifier.split(separator: "_")
                minutes = parts.last.flatMap { Int($0) } ?? 15
            }
            NotificationScheduler.shared.snooze(notification: notification, minutes: minutes)
        } else {
            // Handle new rich notification actions
            switch response.actionIdentifier {
            case "START_NAP":
                trackNotificationEvent(name: "notif_start_nap", notification: notification)
                // Deep link to sleep logging
                NotificationCenter.default.post(
                    name: NSNotification.Name("HandleDeepLink"),
                    object: nil,
                    userInfo: ["route": DeepLinkRoute.sleepStart]
                )
            case "SNOOZE_15":
                trackNotificationEvent(name: "notif_snooze_15", notification: notification)
                NotificationScheduler.shared.snooze(notification: notification, minutes: 15)
            case "VIEW_SUMMARY":
                trackNotificationEvent(name: "notif_view_summary", notification: notification)
                NotificationCenter.default.post(
                    name: NSNotification.Name("HandleDeepLink"),
                    object: nil,
                    userInfo: ["route": DeepLinkRoute.openHome]
                )
            case "LOG_NOW":
                trackNotificationEvent(name: "notif_log_now", notification: notification)
                NotificationCenter.default.post(
                    name: NSNotification.Name("HandleDeepLink"),
                    object: nil,
                    userInfo: ["route": DeepLinkRoute.openHome]
                )
            case "SEE_INSIGHTS":
                trackNotificationEvent(name: "notif_see_insights", notification: notification)
                NotificationCenter.default.post(
                    name: NSNotification.Name("HandleDeepLink"),
                    object: nil,
                    userInfo: ["route": DeepLinkRoute.openHistory]
                )
            case "SHARE_WEEK":
                trackNotificationEvent(name: "notif_share_week", notification: notification)
                // Check if offline - queue the action if needed
                if !NetworkMonitor.shared.isConnected {
                    // Show offline queued message via local notification
                    let offlineContent = UNMutableNotificationContent()
                    offlineContent.title = "Share Queued"
                    offlineContent.body = "Weekly recap share will be available when you're back online."
                    offlineContent.sound = .default

                    let request = UNNotificationRequest(
                        identifier: "offline_share_queue_\(UUID().uuidString)",
                        content: offlineContent,
                        trigger: nil
                    )

                    UNUserNotificationCenter.current().add(request) { error in
                        if let error = error {
                            logger.error("Failed to show offline share queued notification: \(error)")
                        }
                    }
                } else {
                    // Trigger share flow for weekly recap
                    NotificationCenter.default.post(
                        name: NSNotification.Name("HandleDeepLink"),
                        object: nil,
                        userInfo: ["route": DeepLinkRoute.openHistory]
                    )
                }
            default:
                break
            }
        }
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
    
    private func trackNotificationEvent(name: String, notification: UNNotification) {
        let userInfo = notification.request.content.userInfo
        let notifType = userInfo["type"] as? String ?? "unknown"
        Task { await Analytics.shared.log(name, parameters: [
            "notif_type": notifType
        ]) }
    }
}

