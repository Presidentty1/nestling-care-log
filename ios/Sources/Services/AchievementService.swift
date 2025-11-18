import Foundation

class AchievementService {
    private let dataStore: DataStore
    private let streakService: StreakService
    
    init(dataStore: DataStore) {
        self.dataStore = dataStore
        self.streakService = StreakService(dataStore: dataStore)
    }
    
    func checkAchievements(for baby: Baby) async throws -> [Achievement] {
        var unlockedAchievements: [Achievement] = []
        
        // Check streak achievements
        let currentStreak = try await streakService.calculateCurrentStreak(for: baby)
        let longestStreak = try await streakService.calculateLongestStreak(for: baby)
        
        if currentStreak >= 3 {
            unlockedAchievements.append(Achievement.allAchievements.first { $0.id == "streak_3" }!)
        }
        if currentStreak >= 7 {
            unlockedAchievements.append(Achievement.allAchievements.first { $0.id == "streak_7" }!)
        }
        if longestStreak >= 30 {
            unlockedAchievements.append(Achievement.allAchievements.first { $0.id == "streak_30" }!)
        }
        
        // Check event count achievements
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .year, value: -1, to: endDate) ?? endDate
        let events = try await dataStore.fetchEvents(for: baby, from: startDate, to: endDate)
        
        let feedCount = events.filter { $0.type == .feed }.count
        let sleepCount = events.filter { $0.type == .sleep }.count
        let diaperCount = events.filter { $0.type == .diaper }.count
        let tummyTimeCount = events.filter { $0.type == .tummyTime }.count
        
        if feedCount >= 100 {
            unlockedAchievements.append(Achievement.allAchievements.first { $0.id == "feed_master" }!)
        }
        if sleepCount >= 200 {
            unlockedAchievements.append(Achievement.allAchievements.first { $0.id == "sleep_expert" }!)
        }
        if diaperCount >= 500 {
            unlockedAchievements.append(Achievement.allAchievements.first { $0.id == "diaper_champion" }!)
        }
        if tummyTimeCount >= 10 {
            unlockedAchievements.append(Achievement.allAchievements.first { $0.id == "tummy_time_10" }!)
        }
        
        // Check day-based achievements
        if currentStreak >= 7 {
            unlockedAchievements.append(Achievement.allAchievements.first { $0.id == "first_week" }!)
        }
        if longestStreak >= 30 {
            unlockedAchievements.append(Achievement.allAchievements.first { $0.id == "first_month" }!)
        }
        
        return unlockedAchievements
    }
}


