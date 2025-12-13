import Foundation

/// Reassurance copy to reduce anxiety and build emotional connection
/// Brand voice: Warm, supportive, confident (never clinical or overwhelming)
///
/// Usage:
/// ```swift
/// let message = ReassuranceCopyService.shared.getMessage(for: .irregularSchedule)
/// showToast(message)
/// ```
@MainActor
class ReassuranceCopyService {
    static let shared = ReassuranceCopyService()
    
    private init() {}
    
    // MARK: - Reassurance Messages
    
    func getMessage(for scenario: ReassuranceScenario, babyName: String? = nil) -> ReassuranceMessage {
        let name = babyName ?? "your baby"
        
        switch scenario {
        case .irregularSchedule:
            return ReassuranceMessage(
                title: "Schedules take time 💙",
                body: "Most babies don't have predictable patterns until 3-4 months. You're doing great!",
                actionLabel: "Learn more",
                actionLink: "help://sleep-patterns"
            )
            
        case .missedLogs:
            return ReassuranceMessage(
                title: "No worries!",
                body: "Missing a few logs won't affect predictions much. Track when you can, rest when you need to.",
                actionLabel: nil,
                actionLink: nil
            )
            
        case .roughNight:
            return ReassuranceMessage(
                title: "Hang in there 💪",
                body: "Rough nights happen to everyone. You're doing an amazing job.",
                actionLabel: nil,
                actionLink: nil
            )
            
        case .shortSleep:
            return ReassuranceMessage(
                title: "Short naps are normal",
                body: "\(name) might just need a quick power nap. Every baby is different!",
                actionLabel: "About sleep cycles",
                actionLink: "help://sleep-cycles"
            )
            
        case .frequentWaking:
            return ReassuranceMessage(
                title: "This is temporary",
                body: "Frequent wake-ups are tough, but they usually pass. Could be a growth spurt or developmental leap.",
                actionLabel: "Common causes",
                actionLink: "help://frequent-waking"
            )
            
        case .lowMilkIntake:
            return ReassuranceMessage(
                title: "Intake varies day to day",
                body: "Babies' appetites fluctuate. If \(name) seems content and has wet diapers, they're likely getting enough.",
                actionLabel: "Feeding guide",
                actionLink: "help://feeding-amounts"
            )
            
        case .noPredictionAvailable:
            return ReassuranceMessage(
                title: "Building \(name)'s baseline...",
                body: "After a few days of tracking, we'll be able to predict patterns. Keep logging!",
                actionLabel: nil,
                actionLink: nil
            )
            
        case .predictionWrong:
            return ReassuranceMessage(
                title: "Predictions improve over time",
                body: "Every baby is unique. The more you track, the better we understand \(name)'s rhythms.",
                actionLabel: "How predictions work",
                actionLink: "help://predictions-accuracy"
            )
            
        case .gapInTracking:
            return ReassuranceMessage(
                title: "Welcome back!",
                body: "Took a break from tracking? That's totally fine. Pick up where you left off.",
                actionLabel: nil,
                actionLink: nil
            )
            
        case .dataNotSyncing:
            return ReassuranceMessage(
                title: "Your data is safe",
                body: "Couldn't sync right now, but your logs are saved locally. We'll sync when possible.",
                actionLabel: "Check sync status",
                actionLink: "settings://sync"
            )
            
        case .firstTimeParent:
            return ReassuranceMessage(
                title: "You've got this 💚",
                body: "Every parent learns as they go. Tracking helps you understand \(name)'s needs better.",
                actionLabel: "New parent tips",
                actionLink: "help://new-parents"
            )
            
        case .lowDiaperCount:
            return ReassuranceMessage(
                title: "Keep an eye on hydration",
                body: "Fewer diapers could mean \(name) needs more fluids. Check with your pediatrician if concerned.",
                actionLabel: "Diaper guidelines",
                actionLink: "help://diaper-frequency"
            )
            
        case .longWakeWindow:
            return ReassuranceMessage(
                title: "\(name) might be overtired",
                body: "Longer wake windows can make it harder to settle. Try for an earlier nap next time.",
                actionLabel: "Wake window guide",
                actionLink: "help://wake-windows"
            )
            
        case .streakBroken:
            return ReassuranceMessage(
                title: "Life happens 🌟",
                body: "You had a great streak going! Start a new one whenever you're ready.",
                actionLabel: nil,
                actionLink: nil
            )
            
        case .trialEnding:
            return ReassuranceMessage(
                title: "Your trial ends soon",
                body: "Continue tracking with Pro to keep AI predictions and insights.",
                actionLabel: "See plans",
                actionLink: "paywall://trial-ending"
            )
        }
    }
    
    // MARK: - Contextual Reassurance
    
    /// Get reassurance message based on current app state
    func getContextualReassurance(
        babyName: String,
        daysTracking: Int,
        logsToday: Int,
        totalLogs: Int,
        lastSyncSuccess: Bool,
        hasPartner: Bool
    ) -> ReassuranceMessage? {
        // No data yet - encourage getting started
        if totalLogs == 0 {
            return ReassuranceMessage(
                title: "Let's get started!",
                body: "Tap + to log \(babyName)'s first activity. We'll start learning their patterns right away.",
                actionLabel: nil,
                actionLink: nil
            )
        }
        
        // First day - celebrate!
        if daysTracking == 1 && totalLogs >= 1 {
            return ReassuranceMessage(
                title: "You're tracking! 🎉",
                body: "Great start! Keep logging \(babyName)'s activities to see patterns emerge.",
                actionLabel: nil,
                actionLink: nil
            )
        }
        
        // Sync issue
        if !lastSyncSuccess && hasPartner {
            return getMessage(for: .dataNotSyncing, babyName: babyName)
        }
        
        // Low engagement today
        if daysTracking > 7 && logsToday == 0 {
            return getMessage(for: .gapInTracking, babyName: babyName)
        }
        
        // Early days, irregular patterns expected
        if daysTracking < 14 {
            return getMessage(for: .irregularSchedule, babyName: babyName)
        }
        
        return nil
    }
}

/// Reassurance scenario enum
enum ReassuranceScenario {
    case irregularSchedule
    case missedLogs
    case roughNight
    case shortSleep
    case frequentWaking
    case lowMilkIntake
    case noPredictionAvailable
    case predictionWrong
    case gapInTracking
    case dataNotSyncing
    case firstTimeParent
    case lowDiaperCount
    case longWakeWindow
    case streakBroken
    case trialEnding
}

/// Reassurance message structure
struct ReassuranceMessage: Identifiable {
    let id = UUID()
    let title: String
    let body: String
    let actionLabel: String?
    let actionLink: String?
    let emoji: String?
    
    init(title: String, body: String, actionLabel: String? = nil, actionLink: String? = nil, emoji: String? = nil) {
        self.title = title
        self.body = body
        self.actionLabel = actionLabel
        self.actionLink = actionLink
        self.emoji = emoji
    }
}

private let logger = LoggerFactory.create(category: "ReassuranceCopy")
