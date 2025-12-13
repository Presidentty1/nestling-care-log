import Foundation
import StoreKit
import UIKit

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

    /// Show review prompt if conditions are met (SwiftUI version)
    func requestReviewIfAppropriate() {
        guard shouldShowReviewPrompt() else { return }

        // Request review using current window scene
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
            markReviewShownForCurrentVersion()
            
            // Analytics
            Task {
                await Analytics.shared.log("review_prompt_shown", parameters: [
                    "total_logs": getTotalLogs(),
                    "days_since_first_log": calculateDaysSinceFirstLog(getFirstLogDate())
                ])
            }
        }
    }
    
    /// Check and show review prompt for specific positive moments
    func checkForPositiveMoment(
        streakDays: Int? = nil,
        totalLogs: Int? = nil,
        predictionAccurate: Bool? = nil
    ) {
        var shouldShow = false
        
        // Check 7-day streak
        if let streak = streakDays, streak == 7 {
            shouldShow = true
            Task {
                await Analytics.shared.log("review_trigger", parameters: ["trigger": "7_day_streak"])
            }
        }
        
        // Check 50 logs milestone
        if let logs = totalLogs, logs == 50 {
            shouldShow = true
            Task {
                await Analytics.shared.log("review_trigger", parameters: ["trigger": "50_logs"])
            }
        }
        
        // Check accurate prediction feedback
        if let accurate = predictionAccurate, accurate {
            shouldShow = true
            Task {
                await Analytics.shared.log("review_trigger", parameters: ["trigger": "accurate_prediction"])
            }
        }
        
        if shouldShow && !hasShownReviewForCurrentVersion() {
            requestReviewIfAppropriate()
        }
    }

    /// Force show review prompt (for testing)
    func forceShowReview() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
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


