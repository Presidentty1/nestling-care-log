import Foundation

/// Service for proactively discovering and suggesting features to users
///
/// Analyzes user behavior, goals, and milestones to suggest relevant features
/// at optimal moments, reducing feature discovery friction.
///
/// Features suggested based on:
/// - User's stated goal (sleep, feeding, development)
/// - Current usage patterns and milestones
/// - Time since onboarding
/// - Feature usage gaps
class ProactiveFeatureDiscoveryService {
    static let shared = ProactiveFeatureDiscoveryService()

    enum FeatureSuggestion: String, Codable {
        case aiInsights = "ai_insights"
        case cryAnalysis = "cry_analysis"
        case analytics = "analytics"
        case patterns = "patterns"
        case predictions = "predictions"
        case caregiverSharing = "caregiver_sharing"
        case voiceCommands = "voice_commands"
        case widgets = "widgets"
        case referrals = "referrals"
        case proUpgrade = "pro_upgrade"

        var title: String {
            switch self {
            case .aiInsights: return "Discover AI Insights"
            case .cryAnalysis: return "Try Cry Analysis"
            case .analytics: return "View Detailed Analytics"
            case .patterns: return "Explore Sleep Patterns"
            case .predictions: return "Check Nap Predictions"
            case .caregiverSharing: return "Share with Caregivers"
            case .voiceCommands: return "Try Voice Commands"
            case .widgets: return "Add Home Screen Widget"
            case .referrals: return "Share with Friends"
            case .proUpgrade: return "Upgrade to Pro"
            }
        }

        var description: String {
            switch self {
            case .aiInsights: return "Get personalized recommendations based on your baby's data"
            case .cryAnalysis: return "Understand what your baby's cries might mean"
            case .analytics: return "See detailed charts and trends over time"
            case .patterns: return "Discover your baby's sleep and feeding rhythms"
            case .predictions: return "See when your baby might be ready for naps"
            case .caregiverSharing: return "Keep everyone in sync with shared access"
            case .voiceCommands: return "Log events hands-free with Siri"
            case .widgets: return "Quick access from your home screen"
            case .referrals: return "Help friends with better sleep tracking"
            case .proUpgrade: return "Unlock all features and insights"
            }
        }

        var icon: String {
            switch self {
            case .aiInsights: return "sparkles"
            case .cryAnalysis: return "waveform"
            case .analytics: return "chart.bar.fill"
            case .patterns: return "chart.line.uptrend.xyaxis"
            case .predictions: return "moon.stars.fill"
            case .caregiverSharing: return "person.2.fill"
            case .voiceCommands: return "mic.fill"
            case .widgets: return "square.grid.2x2.fill"
            case .referrals: return "heart.fill"
            case .proUpgrade: return "crown.fill"
            }
        }

        var priority: Priority {
            switch self {
            case .aiInsights, .predictions, .patterns: return .high
            case .cryAnalysis, .analytics, .caregiverSharing: return .medium
            case .voiceCommands, .widgets, .referrals, .proUpgrade: return .low
            }
        }

        enum Priority {
            case high, medium, low
        }

        var requiredEvents: Int {
            switch self {
            case .patterns, .predictions: return 5
            case .analytics: return 10
            case .aiInsights: return 15
            case .cryAnalysis: return 1 // Just needs to try once
            case .caregiverSharing, .voiceCommands, .widgets, .referrals: return 0
            case .proUpgrade: return 25 // After significant usage
            }
        }

        func isRelevantForGoal(_ goal: String?) -> Bool {
            guard let goal = goal?.lowercased() else { return true }

            switch self {
            case .predictions, .patterns:
                return goal.contains("sleep") || goal.contains("nap")
            case .cryAnalysis:
                return goal.contains("cry") || goal.contains("understand")
            case .aiInsights, .analytics:
                return true // Useful for all goals
            case .caregiverSharing:
                return goal.contains("share") || goal.contains("caregiver")
            case .voiceCommands:
                return true // Useful for all users
            case .widgets:
                return true // Useful for all users
            case .referrals:
                return true // Useful for all users
            case .proUpgrade:
                return true // Always relevant when appropriate
            }
        }
    }

    struct SuggestionContext {
        let userGoal: String?
        let daysSinceOnboarding: Int
        let totalEventsLogged: Int
        let patternsDetected: Int
        let featuresUsed: Set<String>
        let hasPartner: Bool
        let isProUser: Bool

        static func current() -> SuggestionContext {
            let onboardingDate = UserDefaults.standard.object(forKey: "onboardingCompleteDate") as? Date
            let daysSince = onboardingDate.map {
                Calendar.current.dateComponents([.day], from: $0, to: Date()).day ?? 0
            } ?? 0

            let totalEvents = UserDefaults.standard.integer(forKey: "total_events_logged")

            return SuggestionContext(
                userGoal: UserDefaults.standard.string(forKey: "user_goal"),
                daysSinceOnboarding: daysSince,
                totalEventsLogged: totalEvents,
                patternsDetected: 0, // TODO: Get from pattern detection service
                featuresUsed: [], // TODO: Track feature usage
                hasPartner: UserDefaults.standard.bool(forKey: "has_caregiver_invite"),
                isProUser: ProSubscriptionService.shared.isProUser
            )
        }
    }

    private init() {}

    /// Get the best feature suggestion for the current user context
    func getSuggestion(context: SuggestionContext = .current()) -> FeatureSuggestion? {
        // Don't suggest if user is in free trial (let them explore naturally)
        if ProSubscriptionService.shared.trialDaysRemaining ?? 0 > 0 {
            return nil
        }

        // Don't spam suggestions
        if shouldThrottleSuggestions() {
            return nil
        }

        let candidates = generateCandidates(context: context)
        let filtered = candidates.filter { shouldSuggest($0, context: context) }

        // Return highest priority suggestion
        return filtered.sorted { $0.priority.sortOrder > $1.priority.sortOrder }.first
    }

    /// Generate candidate suggestions based on context
    private func generateCandidates(context: SuggestionContext) -> [FeatureSuggestion] {
        var candidates: [FeatureSuggestion] = []

        // Add suggestions based on usage milestones
        if context.totalEventsLogged >= 5 {
            candidates.append(.patterns)
            candidates.append(.predictions)
        }

        if context.totalEventsLogged >= 10 {
            candidates.append(.analytics)
        }

        if context.totalEventsLogged >= 15 {
            candidates.append(.aiInsights)
        }

        if context.daysSinceOnboarding >= 3 {
            candidates.append(.cryAnalysis)
        }

        if context.daysSinceOnboarding >= 7 {
            candidates.append(.caregiverSharing)
            candidates.append(.voiceCommands)
            candidates.append(.widgets)
        }

        if context.daysSinceOnboarding >= 14 {
            candidates.append(.referrals)
        }

        if context.totalEventsLogged >= 25 && !context.isProUser {
            candidates.append(.proUpgrade)
        }

        return candidates
    }

    /// Check if a suggestion should be shown
    private func shouldSuggest(_ suggestion: FeatureSuggestion, context: SuggestionContext) -> Bool {
        // Check if feature is already discovered/used
        if context.featuresUsed.contains(suggestion.rawValue) {
            return false
        }

        // Check event threshold
        if context.totalEventsLogged < suggestion.requiredEvents {
            return false
        }

        // Check goal relevance
        if !suggestion.isRelevantForGoal(context.userGoal) {
            return false
        }

        // Don't suggest Pro upgrade to Pro users
        if suggestion == .proUpgrade && context.isProUser {
            return false
        }

        // Don't suggest caregiver sharing if they already have a partner
        if suggestion == .caregiverSharing && context.hasPartner {
            return false
        }

        return true
    }

    /// Throttle suggestions to avoid spam
    private func shouldThrottleSuggestions() -> Bool {
        let lastSuggestionTime = UserDefaults.standard.double(forKey: "last_feature_suggestion_time")
        let hoursSinceLast = (Date().timeIntervalSince1970 - lastSuggestionTime) / 3600

        // Max 1 suggestion per 24 hours
        return hoursSinceLast < 24
    }

    /// Mark suggestion as shown
    func markSuggestionShown(_ suggestion: FeatureSuggestion) {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "last_feature_suggestion_time")

        AnalyticsService.shared.track(event: "feature_suggestion_shown", properties: [
            "feature": suggestion.rawValue,
            "priority": String(describing: suggestion.priority)
        ])
    }

    /// Track when user acts on suggestion
    func trackSuggestionAction(_ suggestion: FeatureSuggestion, action: String) {
        AnalyticsService.shared.track(event: "feature_suggestion_action", properties: [
            "feature": suggestion.rawValue,
            "action": action
        ])
    }
}

extension ProactiveFeatureDiscoveryService.FeatureSuggestion.Priority {
    var sortOrder: Int {
        switch self {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
}
