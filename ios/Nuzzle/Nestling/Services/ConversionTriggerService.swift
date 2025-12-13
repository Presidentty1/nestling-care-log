import Foundation
import Combine

/// Conversion Trigger Service - Manages strategic upgrade prompts
/// Research shows behavioral triggers outperform random prompts by 3x
@MainActor
class ConversionTriggerService: ObservableObject {
    static let shared = ConversionTriggerService()

    @Published var pendingTrigger: ConversionTrigger?

    enum ConversionTrigger: String, CaseIterable {
        // High-intent triggers (user has seen value)
        case aiPredictionAccurate = "prediction_accurate"  // User gave thumbs up on prediction
        case patternUnlocked = "pattern_unlocked"  // Reached 10+ logs
        case weeklyInsightReady = "weekly_insight_ready"  // End of first week

        // Medium-intent triggers (milestone-based)
        case fiftyLogs = "fifty_logs"
        case sevenDayStreak = "seven_day_streak"
        case thirdDayActive = "third_day_active"

        // Low-intent triggers (time-based)
        case trialEnding = "trial_ending"  // 2 days before trial ends
        case trialEnded = "trial_ended"

        var priority: Int {
            switch self {
            case .aiPredictionAccurate: return 100  // Highest - user just got value
            case .patternUnlocked: return 90
            case .weeklyInsightReady: return 85
            case .sevenDayStreak: return 70
            case .fiftyLogs: return 60
            case .thirdDayActive: return 50
            case .trialEnding: return 40
            case .trialEnded: return 30
            }
        }

        var modalType: UpgradeModalType {
            switch self {
            case .aiPredictionAccurate, .patternUnlocked:
                return .valueRealized  // "You just experienced Pro value"
            case .weeklyInsightReady:
                return .insightPreview  // Show blurred insight
            case .sevenDayStreak, .fiftyLogs, .thirdDayActive:
                return .milestone  // Celebration + upgrade
            case .trialEnding:
                return .urgency  // Countdown with benefits
            case .trialEnded:
                return .fullPaywall
            }
        }

        enum UpgradeModalType {
            case valueRealized
            case insightPreview
            case milestone
            case urgency
            case fullPaywall
        }
    }

    private var triggeredThisSession: Set<ConversionTrigger> = []

    /// Check if any conversion trigger should fire
    func checkTriggers(
        totalLogs: Int,
        streakDays: Int,
        daysActive: Int,
        trialDaysRemaining: Int?,
        lastPredictionFeedback: Bool?,
        isPro: Bool
    ) {
        guard !isPro else { return }

        // Collect all valid triggers
        var validTriggers: [ConversionTrigger] = []

        // Check each trigger condition
        if lastPredictionFeedback == true {
            validTriggers.append(.aiPredictionAccurate)
        }

        if totalLogs >= 10 && !hasTriggered(.patternUnlocked) {
            validTriggers.append(.patternUnlocked)
        }

        if daysActive == 7 && !hasTriggered(.weeklyInsightReady) {
            validTriggers.append(.weeklyInsightReady)
        }

        if streakDays == 7 && !hasTriggered(.sevenDayStreak) {
            validTriggers.append(.sevenDayStreak)
        }

        if totalLogs == 50 && !hasTriggered(.fiftyLogs) {
            validTriggers.append(.fiftyLogs)
        }

        if let remaining = trialDaysRemaining {
            if remaining == 2 && !hasTriggered(.trialEnding) {
                validTriggers.append(.trialEnding)
            }
            if remaining == 0 && !hasTriggered(.trialEnded) {
                validTriggers.append(.trialEnded)
            }
        }

        // Select highest priority trigger
        if let bestTrigger = validTriggers.max(by: { $0.priority < $1.priority }) {
            pendingTrigger = bestTrigger
            triggeredThisSession.insert(bestTrigger)

            // Analytics
            Task {
                await Analytics.shared.log("conversion_trigger_fired", parameters: [
                    "trigger": bestTrigger.rawValue,
                    "priority": bestTrigger.priority
                ])
            }
        }
    }

    private func hasTriggered(_ trigger: ConversionTrigger) -> Bool {
        return triggeredThisSession.contains(trigger) ||
               UserDefaults.standard.bool(forKey: "trigger_\(trigger.rawValue)_shown")
    }

    func markTriggerShown(_ trigger: ConversionTrigger) {
        UserDefaults.standard.set(true, forKey: "trigger_\(trigger.rawValue)_shown")
    }

    /// Reset triggers (useful for testing or onboarding)
    func resetTriggers() {
        for trigger in ConversionTrigger.allCases {
            UserDefaults.standard.removeObject(forKey: "trigger_\(trigger.rawValue)_shown")
        }
        triggeredThisSession.removeAll()
    }
}
