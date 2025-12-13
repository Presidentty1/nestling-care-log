import Foundation
import Combine

/// Celebration Service - Enhanced celebration system with more trigger points
/// Research shows celebration moments increase daily retention by 27%
@MainActor
class CelebrationService: ObservableObject {
    static let shared = CelebrationService()

    @Published var pendingCelebration: Celebration?

    // Fatigue prevention - track recent celebrations
    private var recentCelebrations: [Date] = []
    private let maxCelebrationsPerHour = 3

    enum Celebration {
        case firstLog(eventType: String)
        case streakMilestone(days: Int)
        case patternMilestone(logsToUnlock: Int)
        case weekComplete(weekNumber: Int)
        case sleepRecord(minutes: Int, previousRecord: Int)
        case consistencyWin(daysInRow: Int, category: String)

        var confettiEnabled: Bool {
            switch self {
            case .streakMilestone(let days) where days >= 7: return true
            case .weekComplete: return true
            case .sleepRecord: return true
            default: return false
            }
        }

        var hapticStyle: HapticStyle {
            switch self {
            case .firstLog: return .success
            case .streakMilestone(let days):
                return days >= 7 ? .celebration : .success
            case .sleepRecord: return .celebration
            default: return .light
            }
        }

        enum HapticStyle {
            case light, success, celebration
        }
    }

    /// Check if a celebration should be shown (with fatigue prevention)
    func shouldShowCelebration(_ celebration: Celebration) -> Bool {
        guard PolishFeatureFlags.shared.celebrationThrottleEnabled else { return true }

        // Remove celebrations older than 1 hour
        recentCelebrations = recentCelebrations.filter {
            Date().timeIntervalSince($0) < 3600
        }

        // Always show first-time milestones (high value)
        switch celebration {
        case .firstLog:
            return true
        case .streakMilestone(let days) where days >= 7:
            return true // Major milestones always show
        case .weekComplete, .sleepRecord:
            return true // Significant achievements always show
        default:
            // Throttle minor celebrations
            guard recentCelebrations.count < maxCelebrationsPerHour else {
                // Log throttled celebration for analytics
                Task {
                    await Analytics.shared.log("celebration_throttled", parameters: [
                        "type": String(describing: celebration),
                        "recent_count": recentCelebrations.count
                    ])
                }
                return false
            }
            recentCelebrations.append(Date())
            return true
        }
    }

    func checkForCelebration(
        events: [Event],
        totalLogs: Int,
        streakDays: Int,
        baby: Baby
    ) {
        // First log celebration
        if totalLogs == 1 {
            let eventType = events.first?.type.displayName ?? "event"
            triggerCelebration(.firstLog(eventType: eventType))
            return
        }

        // Streak milestones: 3, 7, 14, 30 days
        let streakMilestones = [3, 7, 14, 30, 50, 100]
        if streakMilestones.contains(streakDays) && !hasCelebrated("streak_\(streakDays)") {
            triggerCelebration(.streakMilestone(days: streakDays))
            markCelebrated("streak_\(streakDays)")
            return
        }

        // Pattern milestone (10 logs)
        if totalLogs == 10 && !hasCelebrated("pattern_10") {
            triggerCelebration(.patternMilestone(logsToUnlock: 0))
            markCelebrated("pattern_10")
            return
        }

        // Sleep record
        if let todayLongestNap = findLongestNapToday(events: events),
           let previousRecord = getPreviousSleepRecord(for: baby.id),
           todayLongestNap > previousRecord {
            triggerCelebration(.sleepRecord(minutes: todayLongestNap, previousRecord: previousRecord))
            saveSleepRecord(todayLongestNap, for: baby.id)
        }
    }

    private func triggerCelebration(_ celebration: Celebration) {
        // Check fatigue prevention
        guard shouldShowCelebration(celebration) else {
            logger.debug("Celebration throttled: \(celebration)")
            return
        }

        // Play haptic
        switch celebration.hapticStyle {
        case .light:
            Haptics.light()
        case .success:
            Haptics.success()
        case .celebration:
            // Multi-pulse celebration haptic pattern
            Haptics.success()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                Haptics.light()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
                Haptics.light()
            }
        }

        pendingCelebration = celebration

        // Analytics
        Task {
            await Analytics.shared.log("celebration_shown", parameters: [
                "type": String(describing: celebration)
            ])
        }
    }

    // Helper methods...
    private func hasCelebrated(_ key: String) -> Bool {
        UserDefaults.standard.bool(forKey: "celebration_\(key)")
    }

    private func markCelebrated(_ key: String) {
        UserDefaults.standard.set(true, forKey: "celebration_\(key)")
    }

    private func findLongestNapToday(events: [Event]) -> Int? {
        events
            .filter { $0.type == .sleep && Calendar.current.isDateInToday($0.startTime) }
            .compactMap { $0.durationMinutes }
            .max()
    }

    private func getPreviousSleepRecord(for babyId: UUID) -> Int? {
        UserDefaults.standard.object(forKey: "sleep_record_\(babyId)") as? Int
    }

    private func saveSleepRecord(_ minutes: Int, for babyId: UUID) {
        UserDefaults.standard.set(minutes, forKey: "sleep_record_\(babyId)")
    }
}
