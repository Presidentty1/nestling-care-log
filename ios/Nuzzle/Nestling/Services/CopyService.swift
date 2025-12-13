import Foundation

/// Brand voice and copy guidelines service
/// Warm, supportive, confident tone throughout
@MainActor
class CopyService {
    static let shared = CopyService()

    // MARK: - Copy Principles
    // 1. Use "you" and baby's name liberally
    // 2. Be specific, not vague
    // 3. Reassure, don't alarm
    // 4. Celebrate effort, not perfection
    // 5. Make features human, not technical

    // MARK: - Empty States

    func getEmptyState(for context: EmptyStateContext) -> EmptyStateCopy {
        switch context {
        case .homeNoLogs:
            return EmptyStateCopy(
                title: "Let's get started! 🎉",
                body: "Tap + to log \(getBabyName())'s first feed. We'll show you patterns as you go.",
                actionLabel: "Add First Log"
            )

        case .timelineNoLogsToday:
            return EmptyStateCopy(
                title: "No logs yet today",
                body: "That's okay—add one when you're ready. Every log helps us learn \(getBabyName())'s patterns.",
                actionLabel: "Add Log"
            )

        case .insightsInsufficientData:
            return EmptyStateCopy(
                title: "Patterns emerge after 3 days",
                body: "Keep logging feeds, sleeps, and diapers. We'll show you what's working and what might need attention.",
                actionLabel: "View Timeline"
            )
        }
    }

    // MARK: - Error Messages

    func getErrorMessage(for error: ErrorType) -> ErrorCopy {
        switch error {
        case .syncFailed:
            return ErrorCopy(
                title: "Couldn't sync right now",
                body: "Your data is safe—we'll try again soon. Check your connection and try again in a few minutes.",
                primaryAction: "Retry Now",
                secondaryAction: "Continue Offline"
            )

        case .exportFailed:
            return ErrorCopy(
                title: "Something went wrong",
                body: "We couldn't export your data. Want to try again or contact support?",
                primaryAction: "Try Again",
                secondaryAction: "Contact Support"
            )

        case .predictionUnavailable:
            return ErrorCopy(
                title: "Prediction temporarily unavailable",
                body: "We need a few more days of data to give accurate predictions. Keep logging and we'll be back soon!",
                primaryAction: "Continue Logging",
                secondaryAction: nil
            )
        }
    }

    // MARK: - Success Messages

    func getSuccessMessage(for success: SuccessType) -> SuccessCopy {
        switch success {
        case .logCreated(let type, let time):
            return SuccessCopy(
                title: "Got it! ✅",
                body: "\(getBabyName())'s \(type) logged at \(formatTime(time)).",
                actionLabel: nil
            )

        case .partnerInvited:
            return SuccessCopy(
                title: "Invitation sent! 👋",
                body: "We'll let you know when \(getPartnerName()) accepts and starts syncing.",
                actionLabel: nil
            )

        case .subscriptionActivated:
            return SuccessCopy(
                title: "Welcome to Pro! 🌟",
                body: "Enjoy AI predictions and insights. Your first prediction is ready.",
                actionLabel: "View Prediction"
            )
        }
    }

    // MARK: - Reassurance Messages

    func getReassuranceMessage(for situation: ReassuranceSituation) -> ReassuranceCopy {
        switch situation {
        case .irregularSchedule:
            return ReassuranceCopy(
                title: "Schedules take time 💙",
                body: "Most babies don't have predictable patterns until 3-4 months. You're doing great building this foundation.",
                actionLabel: "Learn More About Schedules"
            )

        case .missedLogs:
            return ReassuranceCopy(
                title: "No worries!",
                body: "Missing a few logs won't affect predictions much. Every log helps, but consistency matters more than perfection.",
                actionLabel: nil
            )

        case .roughNight:
            return ReassuranceCopy(
                title: "Hang in there 💪",
                body: "Rough nights happen to every parent. You're doing an amazing job getting through this together.",
                actionLabel: nil
            )
        }
    }

    // MARK: - Feature Descriptions

    func getFeatureDescription(for feature: ProFeature) -> FeatureCopy {
        // Make features human, not technical
        switch feature {
        case .smartPredictions:
            return FeatureCopy(
                title: "Know when to nap",
                description: "AI learns \(getBabyName())'s patterns and tells you when the next nap window opens—before the meltdown.",
                valueProp: "Save time guessing and reduce frustration for everyone"
            )

        case .cryInsights:
            return FeatureCopy(
                title: "Understand what they need",
                description: "Our AI analyzes cry patterns to help you understand if \(getBabyName()) is hungry, tired, or needs a change.",
                valueProp: "Feel more confident responding to your baby's needs"
            )

        case .advancedAnalytics:
            return FeatureCopy(
                title: "See what's working",
                description: "Detailed charts show \(getBabyName())'s feeding patterns, sleep trends, and growth over time.",
                valueProp: "Make informed decisions about feeding and sleep schedules"
            )

        case .aiAssistant:
            return FeatureCopy(
                title: "Get parenting answers",
                description: "Ask questions about \(getBabyName())'s development, feeding, or sleep. Get personalized, evidence-based answers.",
                valueProp: "Feel supported with expert guidance when you need it"
            )

        case .todaysInsight:
            return FeatureCopy(
                title: "Personalized recommendations",
                description: "Each day, get one actionable insight about \(getBabyName())'s patterns and what you can try next.",
                valueProp: "Learn what works best for your unique situation"
            )
        }
    }

    // MARK: - Helper Methods

    private func getBabyName() -> String {
        // TODO: Integrate with baby profile
        return "Emma" // Placeholder
    }

    private func getPartnerName() -> String {
        // TODO: Integrate with partner data
        return "your partner" // Placeholder
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Data Structures

struct EmptyStateCopy {
    let title: String
    let body: String
    let actionLabel: String?
}

struct ErrorCopy {
    let title: String
    let body: String
    let primaryAction: String?
    let secondaryAction: String?
}

struct SuccessCopy {
    let title: String
    let body: String
    let actionLabel: String?
}

struct ReassuranceCopy {
    let title: String
    let body: String
    let actionLabel: String?
}

struct FeatureCopy {
    let title: String
    let description: String
    let valueProp: String
}

// MARK: - Enums

enum EmptyStateContext {
    case homeNoLogs
    case timelineNoLogsToday
    case insightsInsufficientData
}

enum ErrorType {
    case syncFailed
    case exportFailed
    case predictionUnavailable
}

enum SuccessType {
    case logCreated(type: String, time: Date)
    case partnerInvited
    case subscriptionActivated
}

enum ReassuranceSituation {
    case irregularSchedule
    case missedLogs
    case roughNight
}