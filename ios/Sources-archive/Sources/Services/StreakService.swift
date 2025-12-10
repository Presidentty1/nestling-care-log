import Foundation

class StreakService {
    private let dataStore: DataStore
    
    init(dataStore: DataStore) {
        self.dataStore = dataStore
    }
    
    func calculateCurrentStreak(for baby: Baby) async throws -> Int {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        while true {
            let events = try await dataStore.fetchEvents(for: baby, on: currentDate)
            
            if events.isEmpty {
                break
            }
            
            streak += 1
            guard let previousDate = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            currentDate = previousDate
        }
        
        return streak
    }
    
    func calculateLongestStreak(for baby: Baby) async throws -> Int {
        // Calculate longest streak in the last 90 days
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -90, to: endDate) ?? endDate
        
        let events = try await dataStore.fetchEvents(for: baby, from: startDate, to: endDate)
        
        // Group events by day
        let calendar = Calendar.current
        let eventsByDay = Dictionary(grouping: events) { event in
            calendar.startOfDay(for: event.startTime)
        }
        
        var longestStreak = 0
        var currentStreak = 0
        var currentDate = calendar.startOfDay(for: startDate)
        
        while currentDate <= calendar.startOfDay(for: endDate) {
            if eventsByDay[currentDate] != nil && !eventsByDay[currentDate]!.isEmpty {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                currentStreak = 0
            }
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }
        
        return longestStreak
    }
}


