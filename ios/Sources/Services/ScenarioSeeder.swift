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

    /// Create sample data for demo purposes (realistic 24 hours)
    func createSampleData() async throws {
        // Clear existing data first
        try await clearAllData()

        // Create sample baby
        let calendar = Calendar.current
        let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: Date()) ?? Date().addingTimeInterval(-7776000) // ~90 days ago
        let sampleBaby = Baby(
            name: "Avery",
            dateOfBirth: threeMonthsAgo, // 3 months old
            sex: .female,
            timezone: TimeZone.current.identifier
        )
        try await dataStore.addBaby(sampleBaby)

        // Generate 24 hours of realistic activity
        try await generateRealisticDay(for: sampleBaby, hoursAgo: 24)
    }

    /// Clear sample data (only removes sample baby)
    func clearSampleData() async throws {
        // Find and remove the sample baby (Avery)
        let babies = try await dataStore.fetchBabies()
        for baby in babies where baby.name == "Avery" {
            try await dataStore.deleteBaby(baby)
        }
    }

    // MARK: - Sample Data Generation

    private func generateRealisticDay(for baby: Baby, hoursAgo: Int) async throws {
        let now = Date()
        let calendar = Calendar.current

        // Start from hoursAgo hours ago
        guard var currentTime = calendar.date(byAdding: .hour, value: -hoursAgo, to: now) else {
            Logger.dataError("Failed to calculate start time for sample data generation")
            return
        }

        // Generate feeds (every 2-4 hours)
        var feedTimes: [Date] = []
        while currentTime < now {
            if Double.random(in: 0...1) < 0.4 { // 40% chance of feed every hour
                feedTimes.append(currentTime)
                // Skip 2-4 hours for next feed
                let skipHours = Int.random(in: 2...4)
                guard let nextTime = calendar.date(byAdding: .hour, value: skipHours, to: currentTime) else {
                    Logger.dataError("Failed to calculate next feed time")
                    break
                }
                currentTime = nextTime
            } else {
                guard let nextTime = calendar.date(byAdding: .hour, value: 1, to: currentTime) else {
                    Logger.dataError("Failed to increment time for feed generation")
                    break
                }
                currentTime = nextTime
            }
        }

        // Create feed events
        for feedTime in feedTimes.prefix(6) { // Limit to reasonable number
            let amount = Double.random(in: 100...150) // 100-150ml
            let event = Event(
                babyId: baby.id,
                type: .feed,
                subtype: "bottle",
                amount: amount,
                unit: "ml",
                startTime: feedTime,
                note: nil
            )
            try await dataStore.addEvent(event)
        }

        // Generate diaper changes (every 2-4 hours)
        guard var currentTime = calendar.date(byAdding: .hour, value: -hoursAgo, to: now) else {
            Logger.dataError("Failed to calculate start time for diaper generation")
            return
        }
        var diaperTimes: [Date] = []
        while currentTime < now {
            if Double.random(in: 0...1) < 0.3 { // 30% chance of diaper every hour
                diaperTimes.append(currentTime)
                // Skip 2-4 hours for next diaper
                let skipHours = Int.random(in: 2...4)
                guard let nextTime = calendar.date(byAdding: .hour, value: skipHours, to: currentTime) else {
                    Logger.dataError("Failed to calculate next diaper time")
                    break
                }
                currentTime = nextTime
            } else {
                guard let nextTime = calendar.date(byAdding: .hour, value: 1, to: currentTime) else {
                    Logger.dataError("Failed to increment time for diaper generation")
                    break
                }
                currentTime = nextTime
            }
        }

        // Create diaper events
        for diaperTime in diaperTimes.prefix(4) { // Limit to reasonable number
            let subtypes = ["wet", "dirty", "both"]
            let subtype = subtypes.randomElement()!
            let event = Event(
                babyId: baby.id,
                type: .diaper,
                subtype: subtype,
                startTime: diaperTime,
                note: nil
            )
            try await dataStore.addEvent(event)
        }

        // Generate sleep blocks (naps during day, longer sleep at night)
        let sleepBlocks = [
            (start: -22, duration: 60), // Long morning sleep
            (start: -16, duration: 90), // Afternoon nap
            (start: -12, duration: 45), // Short nap
            (start: -6, duration: 480), // Overnight sleep
        ]

        for (hoursAgoStart, durationMinutes) in sleepBlocks {
            let startTime = calendar.date(byAdding: .hour, value: hoursAgoStart, to: now) ?? now.addingTimeInterval(TimeInterval(hoursAgoStart * 3600))
            let endTime = calendar.date(byAdding: .minute, value: durationMinutes, to: startTime) ?? startTime.addingTimeInterval(TimeInterval(durationMinutes * 60))

            // Only create if end time is in the past
            if endTime < now {
                let event = Event(
                    babyId: baby.id,
                    type: .sleep,
                    subtype: durationMinutes > 300 ? "overnight" : "nap",
                    startTime: startTime,
                    endTime: endTime,
                    durationMinutes: durationMinutes,
                    note: nil
                )
                try await dataStore.addEvent(event)
            }
        }

        // Generate some tummy time (short sessions)
        let tummyTimes = [-20, -14, -10, -4] // Hours ago
        for hoursAgoStart in tummyTimes {
            guard let startTime = calendar.date(byAdding: .hour, value: hoursAgoStart, to: now) else {
                Logger.dataError("Failed to calculate tummy time start")
                continue
            }
            let durationMinutes = Int.random(in: 3...8)
            guard let endTime = calendar.date(byAdding: .minute, value: durationMinutes, to: startTime) else {
                Logger.dataError("Failed to calculate tummy time end")
                continue
            }

            let event = Event(
                babyId: baby.id,
                type: .tummyTime,
                startTime: startTime,
                endTime: endTime,
                durationMinutes: durationMinutes,
                note: nil
            )
            try await dataStore.addEvent(event)
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
        let calendar = Calendar.current
        for dayOffset in 0..<3 {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                Logger.dataError("Failed to calculate day offset \(dayOffset)")
                continue
            }
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
        let calendar = Calendar.current
        for dayOffset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                Logger.dataError("Failed to calculate day offset \(dayOffset) for heavy user scenario")
                continue
            }
            
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


