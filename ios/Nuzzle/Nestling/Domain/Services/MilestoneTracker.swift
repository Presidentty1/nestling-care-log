import Foundation
import Combine

enum BabyMilestone: String, CaseIterable {
    case firstFullNight      // 6+ hours sleep logged
    case feedingPattern      // Consistent feeding times for 3+ days
    case tummyTimeChampion   // Cumulative 30 minutes tummy time
    case oneWeekOld
    case oneMonthOld
    case firstSmile          // User-logged milestone

    var title: String {
        switch self {
        case .firstFullNight: return "First Full Night!"
        case .feedingPattern: return "Feeding Pattern Established!"
        case .tummyTimeChampion: return "Tummy Time Champion!"
        case .oneWeekOld: return "One Week Old!"
        case .oneMonthOld: return "One Month Old!"
        case .firstSmile: return "First Smile!"
        }
    }

    var message: String {
        switch self {
        case .firstFullNight: return "Amazing! Your baby slept for 6+ hours. This is a big milestone!"
        case .feedingPattern: return "Your feeding schedule is becoming consistent. Great job!"
        case .tummyTimeChampion: return "30 minutes of tummy time completed! Building strong neck muscles."
        case .oneWeekOld: return "One week down! You're doing an incredible job."
        case .oneMonthOld: return "A whole month! Your dedication is paying off."
        case .firstSmile: return "The first smile! Such a precious moment to celebrate."
        }
    }

    var icon: String {
        switch self {
        case .firstFullNight: return "moon.stars.fill"
        case .feedingPattern: return "clock.fill"
        case .tummyTimeChampion: return "figure.child"
        case .oneWeekOld: return "calendar.badge.checkmark"
        case .oneMonthOld: return "calendar.badge.clock"
        case .firstSmile: return "face.smiling.fill"
        }
    }
}

class MilestoneTracker: ObservableObject {
    func checkMilestones(baby: Baby, events: [Event]) -> BabyMilestone? {
        // Check age milestones
        let ageInDays = Calendar.current.dateComponents([.day], from: baby.dateOfBirth, to: Date()).day ?? 0

        if ageInDays >= 30 && !hasMilestoneBeenAchieved(.oneMonthOld, for: baby) {
            return .oneMonthOld
        } else if ageInDays >= 7 && !hasMilestoneBeenAchieved(.oneWeekOld, for: baby) {
            return .oneWeekOld
        }

        // Check for first full night (6+ hours sleep)
        let sleepEvents = events.filter { $0.type == .sleep }
        if let longestSleep = sleepEvents.max(by: { ($0.durationMinutes ?? 0) < ($1.durationMinutes ?? 0) }),
           let duration = longestSleep.durationMinutes,
           duration >= 360, // 6 hours
           !hasMilestoneBeenAchieved(.firstFullNight, for: baby) {
            return .firstFullNight
        }

        // Check for feeding pattern consistency (3+ days with regular feeding)
        let feedEvents = events.filter { $0.type == .feed }.sorted { $0.startTime < $1.startTime }
        if hasConsistentFeedingPattern(feedEvents) && !hasMilestoneBeenAchieved(.feedingPattern, for: baby) {
            return .feedingPattern
        }

        // Check for tummy time champion (30+ minutes cumulative)
        let tummyTimeEvents = events.filter { $0.type == .tummyTime }
        let totalTummyTime = tummyTimeEvents.reduce(0) { $0 + ($1.durationMinutes ?? 0) }
        if totalTummyTime >= 30 && !hasMilestoneBeenAchieved(.tummyTimeChampion, for: baby) {
            return .tummyTimeChampion
        }

        return nil
    }

    private func hasMilestoneBeenAchieved(_ milestone: BabyMilestone, for baby: Baby) -> Bool {
        let key = "milestone_\(milestone.rawValue)_\(baby.id.uuidString)"
        return UserDefaults.standard.bool(forKey: key)
    }

    private func hasConsistentFeedingPattern(_ feedEvents: [Event]) -> Bool {
        // Check if there are feeds over at least 3 days with reasonable intervals
        guard feedEvents.count >= 6 else { return false } // Need at least 6 feeds

        let daysWithFeeds = Set(feedEvents.map {
            Calendar.current.startOfDay(for: $0.startTime)
        })

        return daysWithFeeds.count >= 3
    }

    func markMilestoneAchieved(_ milestone: BabyMilestone, for baby: Baby) {
        let key = "milestone_\(milestone.rawValue)_\(baby.id.uuidString)"
        UserDefaults.standard.set(true, forKey: key)
    }
}
