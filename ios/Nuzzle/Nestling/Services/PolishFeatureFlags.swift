import Foundation

/// Centralized feature flags for polish features.
/// All polish features should be gated through this service for easy rollout control and rollback.
final class PolishFeatureFlags {
    static let shared = PolishFeatureFlags()

    private let defaults = UserDefaults.standard
    private let prefix = "polish."

    // Tier 1 - Quick Wins
    var skeletonLoadingEnabled: Bool { flag("skeletonLoading", default: true) }
    var contextualBadgesEnabled: Bool { flag("contextualBadges", default: true) }
    var smartCTAsEnabled: Bool { flag("smartCTAs", default: true) }

    // Tier 2 - High Impact
    var shareCardsEnabled: Bool { flag("shareCards", default: true) }
    var timelineGroupingEnabled: Bool { flag("timelineGrouping", default: true) }
    var richNotificationsEnabled: Bool { flag("richNotifications", default: true) }
    var swipeActionsEnabled: Bool { flag("swipeActions", default: true) }

    // Tier 3 - Defensive
    var optimisticUIEnabled: Bool { flag("optimisticUI", default: true) }
    var celebrationThrottleEnabled: Bool { flag("celebrationThrottle", default: true) }

    // Kill switch - disables ALL polish features
    var allPolishDisabled: Bool { defaults.bool(forKey: "\(prefix)killSwitch") }

    private func flag(_ key: String, default value: Bool) -> Bool {
        guard !allPolishDisabled else { return false }
        return defaults.object(forKey: "\(prefix)\(key)") as? Bool ?? value
    }

    func setFlag(_ key: String, enabled: Bool) {
        defaults.set(enabled, forKey: "\(prefix)\(key)")
    }

    func resetAllToDefaults() {
        let allKeys = [
            "skeletonLoading", "contextualBadges", "smartCTAs",
            "shareCards", "timelineGrouping", "richNotifications", "swipeActions",
            "optimisticUI", "celebrationThrottle"
        ]

        for key in allKeys {
            defaults.removeObject(forKey: "\(prefix)\(key)")
        }
    }

    /// Debug description of current flag states
    var debugDescription: String {
        """
        Polish Feature Flags:
        Kill Switch: \(allPolishDisabled)
        Tier 1: Skeleton=\(skeletonLoadingEnabled), Badges=\(contextualBadgesEnabled), SmartCTAs=\(smartCTAsEnabled)
        Tier 2: Share=\(shareCardsEnabled), Grouping=\(timelineGroupingEnabled), Notifs=\(richNotificationsEnabled), Swipe=\(swipeActionsEnabled)
        Tier 3: Optimistic=\(optimisticUIEnabled), Throttle=\(celebrationThrottleEnabled)
        """
    }
}