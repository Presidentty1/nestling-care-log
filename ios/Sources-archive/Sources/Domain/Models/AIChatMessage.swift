import Foundation

/// Represents a message in an AI chat conversation
struct AIChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let role: ChatRole
    let content: String
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        role: ChatRole,
        content: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.createdAt = createdAt
    }
}

enum ChatRole: String, Codable {
    case user
    case assistant
    case system
}

/// Baby context for AI assistant
struct BabyContext: Codable {
    let name: String
    let ageInMonths: Int
    let recentStats: RecentStats
    
    struct RecentStats: Codable {
        let feedsPerDay: String
        let avgSleepHoursPerNight: String
        let totalEventsTracked: Int
    }
}

