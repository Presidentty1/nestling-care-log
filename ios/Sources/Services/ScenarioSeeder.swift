import Foundation

/// Predefined data scenarios for QA and testing
enum ScenarioType: String, CaseIterable {
    case demo = "Demo"
    case light = "Light Usage"
    case heavy = "Heavy Usage"
    case newborn = "Newborn (0-1 month)"
    case threeMonths = "3 Months"
    case sixMonths = "6 Months"
    
    var displayName: String {
        rawValue
    }
}

/// Seeds the DataStore with predefined scenarios
@MainActor
class ScenarioSeeder {
    private let dataStore: DataStore
    
    init(dataStore: DataStore) {
        self.dataStore = dataStore
    }
    
    /// Apply a scenario to the data store
    func applyScenario(_ scenario: ScenarioType) async throws {
        // Clear existing data
        try await clearAllData()
        
        switch scenario {
        case .demo:
            try await seedDemo()
        case .light:
            try await seedLight()
        case .heavy:
            try await seedHeavy()
        case .newborn:
            try await seedNewborn()
        case .threeMonths:
            try await seedThreeMonths()
        case .sixMonths:
            try await seedSixMonths()
        }
    }
    
    // MARK: - Scenario Implementations
    
    private func seedDemo() async throws {
        let baby = Baby(
            id: UUID(),
            name: "Demo Baby",
            dateOfBirth: Date().addingTimeInterval(-90 * 24 * 3600), // 3 months ago
            sex: nil
        )
        try await dataStore.addBaby(baby)
        
        // Add today's events
        let today = Date()
        try await addFeed(baby: baby, time: today.addingTimeInterval(-2 * 3600), amount: 120)
        try await addSleep(baby: baby, start: today.addingTimeInterval(-3 * 3600), duration: 45)
        try await addDiaper(baby: baby, time: today.addingTimeInterval(-1 * 3600))
    }
    
    private func seedLight() async throws {
        let baby = Baby(
            id: UUID(),
            name: "Light User",
            dateOfBirth: Date().addingTimeInterval(-60 * 24 * 3600),
            sex: nil
        )
        try await dataStore.addBaby(baby)
        
        // 2-3 events per day for last 3 days
        let today = Date()
        for dayOffset in 0..<3 {
            let day = Calendar.current.date(byAdding: .day, value: -dayOffset, to: today)!
            try await addFeed(baby: baby, time: day.addingTimeInterval(-4 * 3600), amount: 100)
            if dayOffset < 2 {
                try await addDiaper(baby: baby, time: day.addingTimeInterval(-2 * 3600))
            }
        }
    }
    
    private func seedHeavy() async throws {
        let baby = Baby(
            id: UUID(),
            name: "Heavy User",
            dateOfBirth: Date().addingTimeInterval(-120 * 24 * 3600),
            sex: nil
        )
        try await dataStore.addBaby(baby)
        
        // 10+ events per day for last 7 days
        let today = Date()
        for dayOffset in 0..<7 {
            let day = Calendar.current.date(byAdding: .day, value: -dayOffset, to: today)!
            
            // Multiple feeds
            for feedHour in [2, 5, 8, 11, 14, 17, 20] {
                try await addFeed(baby: baby, time: day.addingTimeInterval(-Double(feedHour) * 3600), amount: 120)
            }
            
            // Multiple diapers
            for diaperHour in [3, 6, 9, 12, 15, 18] {
                try await addDiaper(baby: baby, time: day.addingTimeInterval(-Double(diaperHour) * 3600))
            }
            
            // Sleep sessions
            try await addSleep(baby: baby, start: day.addingTimeInterval(-14 * 3600), duration: 60)
            try await addSleep(baby: baby, start: day.addingTimeInterval(-10 * 3600), duration: 90)
        }
    }
    
    private func seedNewborn() async throws {
        let baby = Baby(
            id: UUID(),
            name: "Newborn",
            dateOfBirth: Date().addingTimeInterval(-15 * 24 * 3600), // 15 days old
            sex: nil
        )
        try await dataStore.addBaby(baby)
        
        // Frequent feeds (every 2-3 hours)
        let today = Date()
        for hour in stride(from: 2, through: 22, by: 3) {
            try await addFeed(baby: baby, time: today.addingTimeInterval(-Double(hour) * 3600), amount: 60)
        }
        
        // Frequent diapers
        for hour in stride(from: 1, through: 23, by: 4) {
            try await addDiaper(baby: baby, time: today.addingTimeInterval(-Double(hour) * 3600))
        }
    }
    
    private func seedThreeMonths() async throws {
        let baby = Baby(
            id: UUID(),
            name: "3 Month Old",
            dateOfBirth: Date().addingTimeInterval(-90 * 24 * 3600),
            sex: nil
        )
        try await dataStore.addBaby(baby)
        
        // More spaced feeds
        let today = Date()
        for hour in [3, 7, 11, 15, 19] {
            try await addFeed(baby: baby, time: today.addingTimeInterval(-Double(hour) * 3600), amount: 150)
        }
        
        // Longer sleep sessions
        try await addSleep(baby: baby, start: today.addingTimeInterval(-14 * 3600), duration: 90)
        try await addSleep(baby: baby, start: today.addingTimeInterval(-10 * 3600), duration: 120)
    }
    
    private func seedSixMonths() async throws {
        let baby = Baby(
            id: UUID(),
            name: "6 Month Old",
            dateOfBirth: Date().addingTimeInterval(-180 * 24 * 3600),
            sex: nil
        )
        try await dataStore.addBaby(baby)
        
        // Even more spaced feeds
        let today = Date()
        for hour in [4, 9, 14, 19] {
            try await addFeed(baby: baby, time: today.addingTimeInterval(-Double(hour) * 3600), amount: 180)
        }
        
        // Tummy time
        try await addTummyTime(baby: baby, time: today.addingTimeInterval(-6 * 3600), duration: 15)
        
        // Longer naps
        try await addSleep(baby: baby, start: today.addingTimeInterval(-13 * 3600), duration: 120)
        try await addSleep(baby: baby, start: today.addingTimeInterval(-9 * 3600), duration: 90)
    }
    
    // MARK: - Helper Methods
    
    private func addFeed(baby: Baby, time: Date, amount: Double) async throws {
        let event = Event(
            babyId: baby.id,
            type: .feed,
            subtype: "bottle",
            amount: amount,
            unit: "ml",
            startTime: time
        )
        try await dataStore.addEvent(event)
    }
    
    private func addDiaper(baby: Baby, time: Date) async throws {
        let event = Event(
            babyId: baby.id,
            type: .diaper,
            subtype: "wet",
            startTime: time
        )
        try await dataStore.addEvent(event)
    }
    
    private func addSleep(baby: Baby, start: Date, duration: Int) async throws {
        let end = start.addingTimeInterval(TimeInterval(duration * 60))
        let event = Event(
            babyId: baby.id,
            type: .sleep,
            subtype: "nap",
            startTime: start,
            endTime: end,
            durationMinutes: duration
        )
        try await dataStore.addEvent(event)
    }
    
    private func addTummyTime(baby: Baby, time: Date, duration: Int) async throws {
        let event = Event(
            babyId: baby.id,
            type: .tummyTime,
            startTime: time,
            durationMinutes: duration
        )
        try await dataStore.addEvent(event)
    }
    
    private func clearAllData() async throws {
        let babies = try await dataStore.fetchBabies()
        for baby in babies {
            // Delete all events for baby
            let today = Date()
            let events = try await dataStore.fetchEvents(for: baby, from: today.addingTimeInterval(-365 * 24 * 3600), to: today)
            for event in events {
                try? await dataStore.deleteEvent(event)
            }
            try? await dataStore.deleteBaby(baby)
        }
    }
}


