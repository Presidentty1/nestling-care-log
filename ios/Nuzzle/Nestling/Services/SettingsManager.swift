import Foundation

/// Centralized settings management to replace scattered UserDefaults usage
/// Consolidates 144+ UserDefaults.standard calls across the codebase
@MainActor
class SettingsManager {
    static let shared = SettingsManager()

    // MARK: - App Settings
    @AppStorage("analyticsEnabled") var analyticsEnabled = true
    @AppStorage("trialStartDate") var trialStartDate: Date?
    @AppStorage("activeBabyId") var activeBabyId: UUID?

    // MARK: - Feature Flags
    @AppStorage("cloudkitSyncEnabled") var cloudkitSyncEnabled = false
    @AppStorage("educationalTooltipsEnabled") var educationalTooltipsEnabled = true
    @AppStorage("omgMomentsEnabled") var omgMomentsEnabled = true

    // MARK: - User Preferences
    @AppStorage("units") var units = "metric"
    @AppStorage("timezone") var timezone = TimeZone.current.identifier
    @AppStorage("theme") var theme = "system"

    // MARK: - Onboarding
    @AppStorage("onboardingCompleted") var onboardingCompleted = false
    @AppStorage("firstLaunch") var firstLaunch = true

    // MARK: - Notifications
    @AppStorage("notificationsEnabled") var notificationsEnabled = true
    @AppStorage("feedRemindersEnabled") var feedRemindersEnabled = true
    @AppStorage("napRemindersEnabled") var napRemindersEnabled = true

    // MARK: - Development
    @AppStorage("devModeEnabled") var devModeEnabled = false
    @AppStorage("devProModeEnabled") var devProModeEnabled = false

    private init() {
        // Migration from old UserDefaults keys if needed
        migrateLegacySettings()
    }

    private func migrateLegacySettings() {
        // Migrate from old key names to new ones
        if let oldAnalyticsEnabled = UserDefaults.standard.object(forKey: "analytics_enabled") as? Bool {
            analyticsEnabled = oldAnalyticsEnabled
            UserDefaults.standard.removeObject(forKey: "analytics_enabled")
        }

        // Add more migrations as needed
    }

    // MARK: - Convenience Methods

    func resetAll() {
        // Reset all settings to defaults
        analyticsEnabled = true
        trialStartDate = nil
        activeBabyId = nil
        cloudkitSyncEnabled = false
        educationalTooltipsEnabled = true
        omgMomentsEnabled = true
        units = "metric"
        timezone = TimeZone.current.identifier
        theme = "system"
        onboardingCompleted = false
        firstLaunch = true
        notificationsEnabled = true
        feedRemindersEnabled = true
        napRemindersEnabled = true
        devModeEnabled = false
        devProModeEnabled = false
    }

    func resetOnboarding() {
        onboardingCompleted = false
        firstLaunch = true
        activeBabyId = nil
        trialStartDate = nil
    }
}