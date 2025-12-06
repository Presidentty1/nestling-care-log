import Foundation

/// Utility for checking feature access based on subscription status
struct FeatureAccess {
    static var isProUser: Bool {
        ProSubscriptionService.shared.isProUser
    }

    /// Check if user can use Cry Analysis feature
    static var canUseCryAnalysis: Bool {
        isProUser
    }

    /// Check if user can use feed and nap reminders
    static var canUseReminders: Bool {
        isProUser
    }

    /// Check if user can use advanced analytics
    static var canUseAdvancedAnalytics: Bool {
        isProUser
    }

    /// Check if user can invite caregivers
    static var canInviteCaregivers: Bool {
        isProUser
    }

    /// Check if user can export unlimited data
    static var canUseAdvancedExport: Bool {
        isProUser
    }

    /// Check if user can use priority support
    static var canUsePrioritySupport: Bool {
        isProUser
    }

    /// Get appropriate message for Pro-gated feature
    static func proMessage(for feature: ProFeature) -> String {
        switch feature {
        case .cryAnalysis:
            return "Upgrade to Pro for advanced cry analysis features."
        case .reminders:
            return "Upgrade to Pro for intelligent feed and nap reminders."
        case .smartSuggestions:
            return "Upgrade to Pro for smarter suggestions and insights."
        case .advancedExport:
            return "Upgrade to Pro for advanced export options."
        case .familySharing:
            return "Upgrade to Pro to share with family and caregivers."
        case .prioritySupport:
            return "Upgrade to Pro for priority customer support."
        }
    }
}

enum ProFeature {
    case cryAnalysis
    case reminders
    case smartSuggestions
    case advancedExport
    case familySharing
    case prioritySupport
}
