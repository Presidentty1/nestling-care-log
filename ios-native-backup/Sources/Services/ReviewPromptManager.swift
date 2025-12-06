import Foundation
import StoreKit

/// Manages in-app review prompts based on usage thresholds
@MainActor
class ReviewPromptManager {
    static let shared = ReviewPromptManager()

    private let userDefaults = UserDefaults.standard
    private let minTotalLogs = 50
    private let minDaysSinceFirstLog = 7

    private enum Keys {
        static let totalLogs = "reviewPrompt.totalLogs"
        static let firstLogDate = "reviewPrompt.firstLogDate"
        static let hasShownReview = "reviewPrompt.hasShownReview"
        static let lastReviewVersion = "reviewPrompt.lastReviewVersion"
    }

    private init() {}

    // MARK: - Log Tracking

    /// Track that a log was created
    func trackLogCreated() {
        let currentTotal = getTotalLogs()
        userDefaults.set(currentTotal + 1, forKey: Keys.totalLogs)

        // Track first log date if not set
        if userDefaults.object(forKey: Keys.firstLogDate) == nil {
            userDefaults.set(Date(), forKey: Keys.firstLogDate)
        }
    }

    /// Check if review prompt should be shown
    func shouldShowReviewPrompt() -> Bool {
        // Don't show if already shown for this version
        if hasShownReviewForCurrentVersion() {
            return false
        }

        let totalLogs = getTotalLogs()
        let firstLogDate = getFirstLogDate()
        let daysSinceFirstLog = calculateDaysSinceFirstLog(firstLogDate)

        return totalLogs >= minTotalLogs && daysSinceFirstLog >= minDaysSinceFirstLog
    }

    /// Show review prompt if conditions are met
    func requestReviewIfAppropriate(from viewController: UIViewController) {
        guard shouldShowReviewPrompt() else { return }

        // Request review
        if let windowScene = viewController.view.window?.windowScene {
            SKStoreReviewController.requestReview(in: windowScene)
            markReviewShownForCurrentVersion()
        }
    }

    /// Force show review prompt (for testing)
    func forceShowReview(from viewController: UIViewController) {
        if let windowScene = viewController.view.window?.windowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }

    // MARK: - Private Helpers

    private func getTotalLogs() -> Int {
        return userDefaults.integer(forKey: Keys.totalLogs)
    }

    private func getFirstLogDate() -> Date? {
        return userDefaults.object(forKey: Keys.firstLogDate) as? Date
    }

    private func calculateDaysSinceFirstLog(_ firstLogDate: Date?) -> Int {
        guard let firstLogDate = firstLogDate else { return 0 }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: firstLogDate, to: Date())
        return components.day ?? 0
    }

    private func hasShownReviewForCurrentVersion() -> Bool {
        let currentVersion = getAppVersion()
        let lastVersion = userDefaults.string(forKey: Keys.lastReviewVersion)
        return lastVersion == currentVersion
    }

    private func markReviewShownForCurrentVersion() {
        let currentVersion = getAppVersion()
        userDefaults.set(currentVersion, forKey: Keys.lastReviewVersion)
    }

    private func getAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    // MARK: - Debug Info

    /// Get debug information about review prompt state
    func getDebugInfo() -> [String: Any] {
        let firstLogDate = getFirstLogDate()
        return [
            "total_logs": getTotalLogs(),
            "first_log_date": firstLogDate?.description ?? "none",
            "days_since_first_log": calculateDaysSinceFirstLog(firstLogDate),
            "has_shown_review": hasShownReviewForCurrentVersion(),
            "min_total_logs": minTotalLogs,
            "min_days_since_first_log": minDaysSinceFirstLog,
            "should_show": shouldShowReviewPrompt()
        ]
    }

    /// Reset review prompt state (for testing)
    func reset() {
        userDefaults.removeObject(forKey: Keys.totalLogs)
        userDefaults.removeObject(forKey: Keys.firstLogDate)
        userDefaults.removeObject(forKey: Keys.hasShownReview)
        userDefaults.removeObject(forKey: Keys.lastReviewVersion)
    }
}


