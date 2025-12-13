import Foundation
import UserNotifications

/// Handles notification permission requests with research-backed timing
/// DON'T ask on first launch - wait for user to demonstrate intent
/// Asking too early reduces opt-in by 40%
@MainActor
class NotificationPermissionFlow {
    static let shared = NotificationPermissionFlow()

    private let userDefaults = UserDefaults.standard

    private enum Keys {
        static let permissionRequested = "notification_permission_requested"
        static let permissionGranted = "notification_permission_granted"
        static let lastPrimerShown = "notification_primer_last_shown"
    }

    private init() {}

    // MARK: - Permission Logic

    /// Check if we should request notification permission
    /// Session 1: NO permission requests, focus on value
    /// Session 2+: After 3 logs AND 2 sessions, use push primer first
    func shouldRequestPermission() -> Bool {
        // Already requested or granted
        if userDefaults.bool(forKey: Keys.permissionRequested) ||
           userDefaults.bool(forKey: Keys.permissionGranted) {
            return false
        }

        // Must have demonstrated engagement
        guard hasDemonstratedIntent() else { return false }

        // Don't ask again if recently shown primer
        guard shouldShowPrimerAgain() else { return false }

        return true
    }

    /// Show push primer before system prompt
    func showPushPrimer(
        title: String = "Stay ahead of \(getBabyName())'s needs",
        benefits: [String] = [
            "Know when the next nap window opens",
            "Never wonder 'when did I last feed?'",
            "Get gentle, helpful reminders"
        ],
        primaryAction: String = "Enable Notifications",
        secondaryAction: String = "Maybe Later"
    ) {
        // This would integrate with your in-app messaging system
        // For now, we'll directly request permission after showing primer

        userDefaults.set(Date(), forKey: Keys.lastPrimerShown)

        // Show custom primer UI here
        // Then call requestSystemPermission() if user taps primary action

        print("📱 Showing push primer with benefits: \(benefits)")
    }

    /// Request system notification permission
    func requestSystemPermission() async -> Bool {
        userDefaults.set(true, forKey: Keys.permissionRequested)

        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            userDefaults.set(granted, forKey: Keys.permissionGranted)

            // Analytics
            await Analytics.shared.log(granted ? "push_permission_granted" : "push_permission_denied", parameters: [
                "shown_primer": userDefaults.object(forKey: Keys.lastPrimerShown) != nil,
                "engagement_level": getEngagementLevel()
            ])

            return granted
        } catch {
            print("❌ Notification permission request failed: \(error)")
            return false
        }
    }

    // MARK: - Helper Methods

    private func hasDemonstratedIntent() -> Bool {
        // Must have logged at least 3 events
        let logsCount = getLogsCount()
        guard logsCount >= 3 else { return false }

        // Must have used app in at least 2 sessions
        let sessionsCount = getSessionsCount()
        guard sessionsCount >= 2 else { return false }

        return true
    }

    private func shouldShowPrimerAgain() -> Bool {
        guard let lastShown = userDefaults.object(forKey: Keys.lastPrimerShown) as? Date else {
            return true // Never shown
        }

        let daysSinceShown = Calendar.current.dateComponents([.day], from: lastShown, to: Date()).day ?? 0
        return daysSinceShown >= 7 // Wait at least 7 days between primer attempts
    }

    private func getBabyName() -> String {
        // This would get the baby's name from your data store
        return "your baby" // Placeholder
    }

    private func getLogsCount() -> Int {
        // This would integrate with your data store
        return 0 // TODO: Implement
    }

    private func getSessionsCount() -> Int {
        // This would integrate with your analytics
        return 0 // TODO: Implement
    }

    private func getEngagementLevel() -> String {
        let logs = getLogsCount()
        let sessions = getSessionsCount()

        if logs >= 10 && sessions >= 5 { return "high" }
        if logs >= 5 && sessions >= 3 { return "medium" }
        return "low"
    }

    // MARK: - Status Checks

    func getPermissionStatus() -> PermissionStatus {
        let requested = userDefaults.bool(forKey: Keys.permissionRequested)
        let granted = userDefaults.bool(forKey: Keys.permissionGranted)

        if granted { return .granted }
        if requested { return .denied }
        if shouldRequestPermission() { return .readyToRequest }
        return .notReady
    }

    func getPermissionStatusString() -> String {
        let status = getPermissionStatus()
        let engagement = getEngagementLevel()

        return "Status: \(status.rawValue), Engagement: \(engagement), Can Request: \(shouldRequestPermission())"
    }

    enum PermissionStatus: String {
        case notReady = "Not Ready"
        case readyToRequest = "Ready to Request"
        case granted = "Granted"
        case denied = "Denied"
    }

    // MARK: - Debug/Testing

    func resetPermissionState() {
        userDefaults.removeObject(forKey: Keys.permissionRequested)
        userDefaults.removeObject(forKey: Keys.permissionGranted)
        userDefaults.removeObject(forKey: Keys.lastPrimerShown)
    }
}