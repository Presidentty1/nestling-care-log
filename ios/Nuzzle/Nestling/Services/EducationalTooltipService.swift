import Foundation

/// Service for providing contextual educational tooltips to help parents understand app value
///
/// Shows educational moments at optimal times:
/// - After first log of each event type
/// - When patterns are first detected
/// - When predictions become more accurate
/// - When milestones are reached
///
/// Prevents spam with frequency limits and user preferences.
class EducationalTooltipService {
    static let shared = EducationalTooltipService()

    enum Context {
        case firstSleepLog
        case firstFeedLog
        case firstDiaperLog
        case firstCryRecording
        case firstPatternDetected(patternType: String)
        case predictionAccuracyImproved(accuracy: Double)
        case milestoneReached(milestone: String)
        case featureFirstUsed(feature: String)
    }

    struct EducationalTooltip {
        let id: String
        let title: String
        let message: String
        let outcome: String // Why this matters for baby development
        let actionText: String? // Optional call-to-action
        let priority: Priority

        enum Priority {
            case low, medium, high
        }

        var displayText: String {
            return """
            \(title)

            \(message)

            Why it matters: \(outcome)
            """
        }
    }

    private let userDefaults = UserDefaults.standard
    private let maxTooltipsPerDay = 1
    private let maxTooltipsPerSession = 1

    private init() {}

    /// Get tooltip for a specific context (nil if not appropriate)
    func tooltip(for context: Context, babyAgeInDays: Int? = nil) -> EducationalTooltip? {
        // Check if we've shown too many tooltips recently
        if shouldThrottleTooltips() {
            return nil
        }

        // Check if we've already shown this specific tooltip
        let tooltipId = tooltipId(for: context)
        if hasShownTooltip(tooltipId) {
            return nil
        }

        // Get appropriate tooltip for context
        let tooltip = createTooltip(for: context, babyAgeInDays: babyAgeInDays)

        // Mark as shown
        if let tooltip = tooltip {
            markTooltipAsShown(tooltip.id)
        }

        return tooltip
    }

    /// Check if we should show a tooltip now (throttling)
    func shouldShowTooltipNow() -> Bool {
        return !shouldThrottleTooltips()
    }

    // MARK: - Tooltip Creation

    private func createTooltip(for context: Context, babyAgeInDays: Int?) -> EducationalTooltip? {
        switch context {
        case .firstSleepLog:
            return EducationalTooltip(
                id: "first_sleep_log",
                title: "Great first sleep log! 💤",
                message: "Tracking sleep helps identify patterns and predict when your baby might be tired. Most babies need 14-17 hours of sleep in their first month.",
                outcome: "Consistent sleep patterns support brain development and emotional regulation.",
                actionText: "Keep logging to unlock nap predictions",
                priority: .high
            )

        case .firstFeedLog:
            return EducationalTooltip(
                id: "first_feed_log",
                title: "Feed tracking started! 🍼",
                message: "Monitoring feeding patterns helps ensure your baby gets enough nutrition. Newborns typically feed 8-12 times per day.",
                outcome: "Regular feeding supports healthy growth and development.",
                actionText: "Log feeds to see spacing patterns",
                priority: .high
            )

        case .firstDiaperLog:
            return EducationalTooltip(
                id: "first_diaper_log",
                title: "Diaper tracking helps spot patterns! 🧷",
                message: "Newborns typically have 6-8 wet diapers per day. This is a great indicator of hydration and feeding effectiveness.",
                outcome: "Monitoring diaper patterns can help detect dehydration early.",
                actionText: "Wet diapers show good hydration",
                priority: .medium
            )

        case .firstCryRecording:
            if let age = babyAgeInDays, age < 90 { // First 3 months
                return EducationalTooltip(
                    id: "first_cry_recording",
                    title: "Cry analysis can help understand needs! 👶",
                    message: "Different cries often indicate different needs - hunger, discomfort, tiredness, or overstimulation.",
                    outcome: "Understanding cry patterns helps parents respond more effectively to their baby's needs.",
                    actionText: "Try the cry analyzer when your baby is fussy",
                    priority: .medium
                )
            }

        case .firstPatternDetected(let patternType):
            return EducationalTooltip(
                id: "first_pattern_\(patternType)",
                title: "Pattern detected! 📊",
                message: "Your baby shows a \(patternType) pattern. This means the app can now make better predictions for you.",
                outcome: "Patterns help predict optimal nap and feed times, making parenting easier.",
                actionText: "Check your nap predictions for accuracy",
                priority: .high
            )

        case .predictionAccuracyImproved(let accuracy):
            if accuracy >= 0.8 {
                return EducationalTooltip(
                    id: "high_accuracy_achieved",
                    title: "Predictions are getting accurate! 🎯",
                    message: "Your baby's patterns are becoming clear. This means you can rely on nap predictions within about 15-30 minutes.",
                    outcome: "Accurate predictions help prevent overtiredness and improve sleep quality.",
                    actionText: "Use nap predictions to time your baby's day",
                    priority: .medium
                )
            }

        case .milestoneReached(let milestone):
            return EducationalTooltip(
                id: "milestone_\(milestone.replacingOccurrences(of: " ", with: "_").lowercased())",
                title: "Development milestone! 🌟",
                message: "You've reached: \(milestone). This is an important step in your baby's development.",
                outcome: "Tracking milestones helps ensure healthy development and catch any concerns early.",
                actionText: "Continue logging to see progress over time",
                priority: .medium
            )

        case .featureFirstUsed(let feature):
            // Lower priority for feature discovery
            return nil
        }

        return nil
    }

    // MARK: - Throttling & Tracking

    private func shouldThrottleTooltips() -> Bool {
        let todayTooltips = tooltipsShownToday()
        let sessionTooltips = tooltipsShownThisSession()

        return todayTooltips >= maxTooltipsPerDay || sessionTooltips >= maxTooltipsPerSession
    }

    private func tooltipsShownToday() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        let shownDates = userDefaults.array(forKey: "tooltip_shown_dates") as? [Date] ?? []

        return shownDates.filter { Calendar.current.isDate($0, inSameDayAs: today) }.count
    }

    private func tooltipsShownThisSession() -> Int {
        return userDefaults.integer(forKey: "tooltips_shown_this_session")
    }

    private func hasShownTooltip(_ id: String) -> Bool {
        let shownTooltips = userDefaults.array(forKey: "shown_tooltips") as? [String] ?? []
        return shownTooltips.contains(id)
    }

    private func markTooltipAsShown(_ id: String) {
        // Add to shown tooltips list
        var shownTooltips = userDefaults.array(forKey: "shown_tooltips") as? [String] ?? []
        shownTooltips.append(id)
        userDefaults.set(shownTooltips, forKey: "shown_tooltips")

        // Track date shown
        var shownDates = userDefaults.array(forKey: "tooltip_shown_dates") as? [Date] ?? []
        shownDates.append(Date())
        userDefaults.set(shownDates, forKey: "tooltip_shown_dates")

        // Track session count
        let sessionCount = tooltipsShownThisSession() + 1
        userDefaults.set(sessionCount, forKey: "tooltips_shown_this_session")
    }

    private func tooltipId(for context: Context) -> String {
        switch context {
        case .firstSleepLog: return "first_sleep_log"
        case .firstFeedLog: return "first_feed_log"
        case .firstDiaperLog: return "first_diaper_log"
        case .firstCryRecording: return "first_cry_recording"
        case .firstPatternDetected(let pattern): return "first_pattern_\(pattern)"
        case .predictionAccuracyImproved: return "prediction_accuracy_improved"
        case .milestoneReached(let milestone): return "milestone_\(milestone)"
        case .featureFirstUsed(let feature): return "feature_\(feature)"
        }
    }

    // MARK: - Session Management

    func resetSessionCounts() {
        userDefaults.set(0, forKey: "tooltips_shown_this_session")
    }

    // MARK: - Analytics

    func trackTooltipShown(_ tooltip: EducationalTooltip, context: Context) {
        AnalyticsService.shared.track(event: "educational_tooltip_shown", properties: [
            "tooltip_id": tooltip.id,
            "context": String(describing: context),
            "priority": String(describing: tooltip.priority),
            "has_action": tooltip.actionText != nil
        ])
    }

    func trackTooltipActionTaken(tooltipId: String, action: String) {
        AnalyticsService.shared.track(event: "educational_tooltip_action_taken", properties: [
            "tooltip_id": tooltipId,
            "action": action
        ])
    }
}