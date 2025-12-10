import Foundation

struct Achievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let unlockedAt: Date?
    
    init(id: String, title: String, description: String, icon: String, unlockedAt: Date? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.unlockedAt = unlockedAt
    }
    
    var isUnlocked: Bool {
        unlockedAt != nil
    }
    
    static let allAchievements: [Achievement] = [
        Achievement(id: "first_week", title: "First Week", description: "Logged events for 7 days in a row", icon: "calendar"),
        Achievement(id: "first_month", title: "First Month", description: "Logged events for 30 days in a row", icon: "calendar.badge.clock"),
        Achievement(id: "tummy_time_10", title: "Tummy Time Pro", description: "Completed 10 tummy time sessions", icon: "figure.child"),
        Achievement(id: "feed_master", title: "Feed Master", description: "Logged 100 feeds", icon: "drop.fill"),
        Achievement(id: "sleep_expert", title: "Sleep Expert", description: "Tracked 200 sleep sessions", icon: "moon.fill"),
        Achievement(id: "diaper_champion", title: "Diaper Champion", description: "Logged 500 diaper changes", icon: "drop.circle.fill"),
        Achievement(id: "streak_3", title: "3 Day Streak", description: "Logged events 3 days in a row", icon: "flame.fill"),
        Achievement(id: "streak_7", title: "7 Day Streak", description: "Logged events 7 days in a row", icon: "flame.fill"),
        Achievement(id: "streak_30", title: "30 Day Streak", description: "Logged events 30 days in a row", icon: "flame.fill"),
    ]
}


