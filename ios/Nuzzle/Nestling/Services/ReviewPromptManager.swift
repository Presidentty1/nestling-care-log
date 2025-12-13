import Foundation
import StoreKit

/// Manages App Store review prompts with research-backed timing
/// Apple limits to 3 prompts per 365 days per user
@MainActor
class ReviewPromptManager {
    static let shared = ReviewPromptManager()

    private let userDefaults = UserDefaults.standard
    private let maxPromptsPerYear = 3
    private let minimumDaysBetweenPrompts = 60  // Space out prompts

    private enum Keys {
        static let promptsThisYear = "review_prompts_this_year"
        static let lastPromptDate = "last_review_prompt_date"
        static let yearStartDate = "review_prompt_year_start"
    }

    private init() {
        initializeYearTracking()
    }

    // MARK: - Prompt Logic

    /// Check if we should show a review prompt after positive moments
    func checkForPositiveMoment(
        streakDays: Int? = nil,
        predictionAccurate: Bool? = nil,
        longSleepMilestone: Bool? = nil
    ) {
        // Don't prompt if already at limit
        guard canShowPrompt() else { return }

        // Check timing constraints
        guard shouldShowBasedOnTiming() else { return }

        // Check context (not at 2AM, etc.)
        guard shouldShowBasedOnContext() else { return }

        // Only show after genuine delight moments
        let shouldShow = shouldShowBasedOnMoment(
            streakDays: streakDays,
            predictionAccurate: predictionAccurate,
            longSleepMilestone: longSleepMilestone
        )

        if shouldShow {
            requestReview()
        }
    }

    /// Main review request method
    func requestReview() {
        guard canShowPrompt() else { return }

        // Use SKStoreReviewController for iOS 10.3+
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)

            // Record the prompt
            recordPromptShown()
        }
    }

    // MARK: - Prompt Eligibility

    private func canShowPrompt() -> Bool {
        let promptsThisYear = getPromptsThisYear()
        return promptsThisYear < maxPromptsPerYear
    }

    private func shouldShowBasedOnTiming() -> Bool {
        guard let lastPromptDate = userDefaults.object(forKey: Keys.lastPromptDate) as? Date else {
            return true // First prompt ever
        }

        let daysSinceLastPrompt = Calendar.current.dateComponents([.day], from: lastPromptDate, to: Date()).day ?? 0
        return daysSinceLastPrompt >= minimumDaysBetweenPrompts
    }

    private func shouldShowBasedOnContext() -> Bool {
        // Don't show during night mode hours
        let hour = Calendar.current.component(.hour, from: Date())
        let isNightTime = hour >= 22 || hour < 7  // 10PM - 7AM
        if isNightTime { return false }

        // Don't show if user recently dismissed a celebration
        if let lastCelebrationDismissal = getLastCelebrationDismissal(),
           Calendar.current.dateComponents([.minute], from: lastCelebrationDismissal, to: Date()).minute ?? 0 < 5 {
            return false
        }

        // Don't show if user recently had negative feedback
        if let lastNegativeFeedback = getLastNegativeFeedbackDate(),
           Calendar.current.dateComponents([.day], from: lastNegativeFeedback, to: Date()).day ?? 0 < 30 {
            return false
        }

        return true
    }

    private func shouldShowBasedOnMoment(
        streakDays: Int?,
        predictionAccurate: Bool?,
        longSleepMilestone: Bool?
    ) -> Bool {
        // Priority 1: 7-day logging streak celebration
        if let days = streakDays, days >= 7 {
            return true
        }

        // Priority 2: Accurate prediction confirmation
        if predictionAccurate == true {
            return true
        }

        // Priority 3: Long sleep milestone (4+ hours)
        if longSleepMilestone == true {
            return true
        }

        return false
    }

    // MARK: - Data Management

    private func initializeYearTracking() {
        let currentYear = Calendar.current.component(.year, from: Date())

        if let storedYear = userDefaults.object(forKey: Keys.yearStartDate) as? Date {
            let storedYearValue = Calendar.current.component(.year, from: storedYear)
            if storedYearValue != currentYear {
                // New year, reset counter
                userDefaults.set(0, forKey: Keys.promptsThisYear)
                userDefaults.set(Date(), forKey: Keys.yearStartDate)
            }
        } else {
            // First time setup
            userDefaults.set(0, forKey: Keys.promptsThisYear)
            userDefaults.set(Date(), forKey: Keys.yearStartDate)
        }
    }

    private func getPromptsThisYear() -> Int {
        return userDefaults.integer(forKey: Keys.promptsThisYear)
    }

    private func recordPromptShown() {
        let currentCount = getPromptsThisYear()
        userDefaults.set(currentCount + 1, forKey: Keys.promptsThisYear)
        userDefaults.set(Date(), forKey: Keys.lastPromptDate)

        // Analytics
        Task {
            await Analytics.shared.log("review_prompt_shown", parameters: [
                "prompts_this_year": currentCount + 1,
                "days_since_last": getDaysSinceLastPrompt()
            ])
        }
    }

    private func getDaysSinceLastPrompt() -> Int {
        guard let lastDate = userDefaults.object(forKey: Keys.lastPromptDate) as? Date else {
            return 999 // Never shown
        }
        return Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
    }

    private func getLastCelebrationDismissal() -> Date? {
        return userDefaults.object(forKey: "last_celebration_dismissal") as? Date
    }

    private func getLastNegativeFeedbackDate() -> Date? {
        return userDefaults.object(forKey: "last_negative_feedback") as? Date
    }

    // MARK: - Integration Points

    /// Call this when user dismisses a celebration quickly (< 2 seconds)
    func recordCelebrationDismissal() {
        userDefaults.set(Date(), forKey: "last_celebration_dismissal")
    }

    /// Call this when user provides negative feedback
    func recordNegativeFeedback() {
        userDefaults.set(Date(), forKey: "last_negative_feedback")
    }

    // MARK: - Debug/Testing

    func resetPromptLimits() {
        userDefaults.set(0, forKey: Keys.promptsThisYear)
        userDefaults.removeObject(forKey: Keys.lastPromptDate)
    }

    func getPromptStatus() -> [String: Any] {
        return [
            "prompts_this_year": getPromptsThisYear(),
            "max_prompts_per_year": maxPromptsPerYear,
            "days_since_last_prompt": getDaysSinceLastPrompt(),
            "can_show_prompt": canShowPrompt()
        ]
    }
}