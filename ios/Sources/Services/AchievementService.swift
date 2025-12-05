import Foundation

/// Service for tracking and unlocking parental achievements and milestones
@MainActor
class AchievementService {
    static let shared = AchievementService()

    private let unlockedAchievementsKey = "unlocked_achievements"
    private var unlockedAchievements: Set<String> = []

    private init() {
        loadUnlockedAchievements()
    }

    // MARK: - Achievement Management

    /// Check for newly unlocked achievements and return them
    func checkForNewAchievements(baby: Baby, dataStore: DataStore) async -> [Achievement] {
        var newAchievements: [Achievement] = []

        for achievement in Achievement.allAchievements {
            if unlockedAchievements.contains(achievement.id) {
                continue // Already unlocked
            }

            if await achievement.isUnlocked(for: baby, dataStore: dataStore) {
                unlockedAchievements.insert(achievement.id)
                newAchievements.append(achievement)

                // Log achievement unlock
                Logger.info("Achievement unlocked: \(achievement.title)")
                await Analytics.shared.log("achievement_unlocked", parameters: [
                    "achievement_id": achievement.id,
                    "baby_id": baby.id.uuidString
                ])
            }
        }

        // Save updated achievements
        if !newAchievements.isEmpty {
            saveUnlockedAchievements()
        }

        return newAchievements
    }

    /// Get all unlocked achievements
    func getUnlockedAchievements() -> [Achievement] {
        return Achievement.allAchievements.filter { unlockedAchievements.contains($0.id) }
    }

    /// Check if achievement is unlocked
    func isAchievementUnlocked(_ achievementId: String) -> Bool {
        return unlockedAchievements.contains(achievementId)
    }

    private func loadUnlockedAchievements() {
        if let data = UserDefaults.standard.data(forKey: unlockedAchievementsKey),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            unlockedAchievements = decoded
        }
    }

    private func saveUnlockedAchievements() {
        if let data = try? JSONEncoder().encode(unlockedAchievements) {
            UserDefaults.standard.set(data, forKey: unlockedAchievementsKey)
        }
    }
}

struct Achievement: Identifiable {
    let id: String
    let title: String
    let description: String
    let iconName: String
    let rarity: Rarity
    let unlockCondition: String
    let isUnlocked: (Baby, DataStore) async -> Bool

    enum Rarity {
        case common
        case rare
        case epic
        case legendary

        var color: String {
            switch self {
            case .common: return "gray"
            case .rare: return "blue"
            case .epic: return "purple"
            case .legendary: return "gold"
            }
        }
    }

    static let allAchievements: [Achievement] = [
        // Logging achievements
        Achievement(
            id: "first_log",
            title: "Getting Started",
            description: "Logged your first event",
            iconName: "star.fill",
            rarity: .common,
            unlockCondition: "Log your first event"
        ) { baby, dataStore in
            let events = try? await dataStore.fetchEvents(for: baby, from: Date.distantPast, to: Date.distantFuture)
            return (events?.count ?? 0) >= 1
        },

        Achievement(
            id: "hundred_logs",
            title: "Dedicated Parent",
            description: "Logged 100 events",
            iconName: "100.circle.fill",
            rarity: .rare,
            unlockCondition: "Log 100 events"
        ) { baby, dataStore in
            let events = try? await dataStore.fetchEvents(for: baby, from: Date.distantPast, to: Date.distantFuture)
            return (events?.count ?? 0) >= 100
        },

        Achievement(
            id: "thousand_logs",
            title: "Super Parent",
            description: "Logged 1,000 events",
            iconName: "1000.circle.fill",
            rarity: .epic,
            unlockCondition: "Log 1,000 events"
        ) { baby, dataStore in
            let events = try? await dataStore.fetchEvents(for: baby, from: Date.distantPast, to: Date.distantFuture)
            return (events?.count ?? 0) >= 1000
        },

        // Streak achievements
        Achievement(
            id: "week_streak",
            title: "Week Warrior",
            description: "Logged events for 7 consecutive days",
            iconName: "calendar.badge.clock",
            rarity: .rare,
            unlockCondition: "Log events for 7 days in a row"
        ) { baby, dataStore in
            await checkConsecutiveDays(baby: baby, dataStore: dataStore, requiredDays: 7)
        },

        Achievement(
            id: "month_streak",
            title: "Month Master",
            description: "Logged events for 30 consecutive days",
            iconName: "calendar.badge.exclamationmark",
            rarity: .epic,
            unlockCondition: "Log events for 30 days in a row"
        ) { baby, dataStore in
            await checkConsecutiveDays(baby: baby, dataStore: dataStore, requiredDays: 30)
        },

        // Age-based achievements
        Achievement(
            id: "first_month",
            title: "Month One Complete",
            description: "Your baby is one month old!",
            iconName: "moon.fill",
            rarity: .common,
            unlockCondition: "Reach 1 month of age"
        ) { baby, _ in
            let ageInDays = Calendar.current.dateComponents([.day], from: baby.dateOfBirth, to: Date()).day ?? 0
            return ageInDays >= 30
        },

        Achievement(
            id: "six_months",
            title: "Half Year Milestone",
            description: "Your baby is six months old!",
            iconName: "6.circle.fill",
            rarity: .rare,
            unlockCondition: "Reach 6 months of age"
        ) { baby, _ in
            let ageInDays = Calendar.current.dateComponents([.day], from: baby.dateOfBirth, to: Date()).day ?? 0
            return ageInDays >= 183
        },

        Achievement(
            id: "one_year",
            title: "First Birthday",
            description: "Your baby is one year old!",
            iconName: "birthday.cake.fill",
            rarity: .legendary,
            unlockCondition: "Reach 1 year of age"
        ) { baby, _ in
            let ageInDays = Calendar.current.dateComponents([.day], from: baby.dateOfBirth, to: Date()).day ?? 0
            return ageInDays >= 365
        },

        // Pattern achievements
        Achievement(
            id: "nap_predictor",
            title: "Nap Guru",
            description: "Used nap predictions for 30 days",
            iconName: "bed.double.fill",
            rarity: .rare,
            unlockCondition: "Use nap predictions for 30 days"
        ) { baby, dataStore in
            // This would need to track prediction usage - for now, check for consistent logging
            await checkConsecutiveDays(baby: baby, dataStore: dataStore, requiredDays: 30)
        },

        Achievement(
            id: "feeding_tracker",
            title: "Feeding Expert",
            description: "Logged 200 feeding events",
            iconName: "bottle.fill",
            rarity: .rare,
            unlockCondition: "Log 200 feeding events"
        ) { baby, dataStore in
            let events = try? await dataStore.fetchEvents(for: baby, from: Date.distantPast, to: Date.distantFuture)
            let feedEvents = events?.filter { $0.type == .feed } ?? []
            return feedEvents.count >= 200
        }
    ]

    // Helper function to check consecutive days of logging
    private static func checkConsecutiveDays(baby: Baby, dataStore: DataStore, requiredDays: Int) async -> Bool {
        do {
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -requiredDays, to: Date())!
            let events = try await dataStore.fetchEvents(for: baby, from: thirtyDaysAgo, to: Date())

            // Group events by date
            let calendar = Calendar.current
            var eventDates = Set<Date>()

            for event in events {
                let date = calendar.startOfDay(for: event.startTime)
                eventDates.insert(date)
            }

            // Check if we have events for each of the last N days
            for dayOffset in 0..<requiredDays {
                let checkDate = calendar.date(byAdding: .day, value: -dayOffset, to: Date())!
                let startOfDay = calendar.startOfDay(for: checkDate)

                if !eventDates.contains(startOfDay) {
                    return false
                }
            }

            return true
        } catch {
            return false
        }
    }
}