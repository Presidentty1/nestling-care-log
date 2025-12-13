import Foundation

/// Service for detecting "OMG moments" - impressive outcomes that deserve celebration and sharing
///
/// Detects moments like:
/// - 6+ hour sleep sessions
/// - Highly accurate nap predictions
/// - Milestone achievements
/// - Partner sync moments
///
/// These moments get enhanced celebrations with confetti, special copy, and share prompts.
class OMGMomentDetectionService {
    static let shared = OMGMomentDetectionService()

    enum OMGMoment: Equatable {
        case sleepBreakthrough(hours: Double, babyName: String)
        case patternAccuracy(predicted: Date, actual: Date, accuracyMinutes: Int, babyName: String)
        case weekMilestone(weekNumber: Int, totalSleepHours: Double, babyName: String)
        case partnerSync(firstSharedLog: Bool, partnerName: String, babyName: String)

        var title: String {
            switch self {
            case .sleepBreakthrough(let hours, _):
                return "😴 \(Int(hours)) Hour Sleep!"
            case .patternAccuracy(_, _, let accuracyMinutes, _):
                return "🎯 Spot On Prediction!"
            case .weekMilestone(let weekNumber, _, _):
                return "🏆 Week \(weekNumber) Champion!"
            case .partnerSync(_, _, _):
                return "🤝 Team Effort!"
            }
        }

        var message: String {
            switch self {
            case .sleepBreakthrough(let hours, let babyName):
                return "\(babyName) just slept \(Int(hours)) hours! This is huge for their development. 🌙"
            case .patternAccuracy(_, _, let accuracyMinutes, let babyName):
                return "Our prediction was only \(accuracyMinutes) minutes off! \(babyName)'s patterns are so clear now. 🎯"
            case .weekMilestone(let weekNumber, let totalSleepHours, let babyName):
                return "Week \(weekNumber) complete with \(Int(totalSleepHours)) hours of total sleep! \(babyName) is thriving! 📈"
            case .partnerSync(_, let partnerName, let babyName):
                return "\(partnerName) joined the team! Now both of you can track \(babyName)'s amazing progress together. 🤝"
            }
        }

        var sharePrompt: String {
            switch self {
            case .sleepBreakthrough:
                return "This breakthrough deserves to be shared! 💫"
            case .patternAccuracy:
                return "Parents everywhere need to know this works! 📢"
            case .weekMilestone:
                return "Show off your tracking success! 🌟"
            case .partnerSync:
                return "Teamwork makes the dream work! 👨‍👩‍👧"
            }
        }

        var shouldTriggerCelebration: Bool {
            return true // All OMG moments get celebrations
        }

        var celebrationIcon: String {
            switch self {
            case .sleepBreakthrough:
                return "moon.zzz.fill"
            case .patternAccuracy:
                return "target"
            case .weekMilestone:
                return "star.fill"
            case .partnerSync:
                return "person.2.fill"
            }
        }

        var celebrationColor: String {
            switch self {
            case .sleepBreakthrough:
                return "success"
            case .patternAccuracy:
                return "warning"
            case .weekMilestone:
                return "primary"
            case .partnerSync:
                return "success"
            }
        }
    }

    // MARK: - Detection Logic

    /// Detect OMG moments after a sleep event is logged
    func detectAfterSleepEvent(event: Event, baby: Baby, recentHistory: [Event]) -> OMGMoment? {
        guard event.type == .sleep else { return nil }

        let sleepDuration = event.endTime.timeIntervalSince(event.startTime) / 3600 // hours

        // 6+ hour sleep breakthrough
        if sleepDuration >= 6.0 {
            return .sleepBreakthrough(hours: sleepDuration, babyName: baby.name)
        }

        // Check for pattern accuracy (if we have prediction data)
        if let predictedEndTime = event.predictedEndTime,
           let accuracyMinutes = calculatePredictionAccuracy(predicted: predictedEndTime, actual: event.endTime),
           accuracyMinutes <= 5 { // Within 5 minutes
            return .patternAccuracy(
                predicted: predictedEndTime,
                actual: event.endTime,
                accuracyMinutes: accuracyMinutes,
                babyName: baby.name
            )
        }

        return nil
    }

    /// Detect OMG moments after weekly summary generation
    func detectAfterWeeklySummary(weekNumber: Int, totalSleepHours: Double, baby: Baby) -> OMGMoment? {
        // Week milestone - significant sleep accumulation
        if totalSleepHours >= Double(weekNumber * 7 * 14) { // At least 14 hours/day average
            return .weekMilestone(
                weekNumber: weekNumber,
                totalSleepHours: totalSleepHours,
                babyName: baby.name
            )
        }

        return nil
    }

    /// Detect OMG moments when partner syncs first log
    func detectPartnerSync(firstSharedLog: Bool, partnerName: String, baby: Baby) -> OMGMoment? {
        if firstSharedLog {
            return .partnerSync(
                firstSharedLog: true,
                partnerName: partnerName,
                babyName: baby.name
            )
        }

        return nil
    }

    /// Check if a detected moment should trigger (prevent spam)
    func shouldTriggerMoment(_ moment: OMGMoment) -> Bool {
        // Prevent duplicate celebrations within 24 hours for the same type
        let momentKey: String
        switch moment {
        case .sleepBreakthrough:
            momentKey = "omg_sleep_breakthrough"
        case .patternAccuracy:
            momentKey = "omg_pattern_accuracy"
        case .weekMilestone(let weekNumber, _, _):
            momentKey = "omg_week_\(weekNumber)"
        case .partnerSync:
            momentKey = "omg_partner_sync"
        }

        let lastTriggeredKey = "last_omg_\(momentKey)"
        let lastTriggered = UserDefaults.standard.double(forKey: lastTriggeredKey)
        let now = Date().timeIntervalSince1970
        let hoursSinceLast = (now - lastTriggered) / 3600

        if hoursSinceLast < 24 {
            return false // Too soon
        }

        // Update last triggered time
        UserDefaults.standard.set(now, forKey: lastTriggeredKey)
        return true
    }

    // MARK: - Helper Methods

    private func calculatePredictionAccuracy(predicted: Date, actual: Date) -> Int? {
        let difference = abs(predicted.timeIntervalSince(actual))
        return Int(difference / 60) // minutes
    }

    /// Get celebration copy for a moment
    func getCelebrationCopy(for moment: OMGMoment) -> (title: String, message: String) {
        return (moment.title, moment.message)
    }

    /// Get share prompt for a moment
    func getSharePrompt(for moment: OMGMoment) -> String {
        return moment.sharePrompt
    }
}

// MARK: - CelebrationType Extension

extension CelebrationType {
    // Add OMG-specific celebration types
    static var sleepRecord: CelebrationType {
        return .milestoneUnlocked(name: "Sleep Record")
    }
}