import Foundation

/// On-device predictions engine using deterministic heuristics.
/// No networking required; all calculations are local.
class PredictionsEngine {
    private let dataStore: DataStore
    
    init(dataStore: DataStore) {
        self.dataStore = dataStore
    }
    
    /// Generate a prediction for next nap.
    func predictNextNap(for baby: Baby) async throws -> Prediction {
        // Fetch recent sleep events
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        let events = try await dataStore.fetchEvents(for: baby, from: startDate, to: endDate)
        
        let sleepEvents = events.filter { $0.type == .sleep && $0.endTime != nil }
            .sorted { ($0.endTime ?? Date()) > ($1.endTime ?? Date()) }
        
        guard let lastSleep = sleepEvents.first,
              let lastSleepEnd = lastSleep.endTime else {
            // No recent sleep data, use age-based default
            let wakeWindow = WakeWindowCalculator.wakeWindow(for: baby)
            let predictedTime = Date().addingTimeInterval(Double(wakeWindow.min * 60))
            return Prediction(
                babyId: baby.id,
                type: .nextNap,
                predictedTime: predictedTime,
                confidence: 0.5,
                explanation: "Based on typical wake windows for \(ageDescription(for: baby))"
            )
        }
        
        let wakeWindow = WakeWindowCalculator.wakeWindow(for: baby)
        let predictedTime = WakeWindowCalculator.nextNapTime(lastSleepEnd: lastSleepEnd, wakeWindow: wakeWindow)
        
        let timeSinceWake = Date().timeIntervalSince(lastSleepEnd)
        let minWakeWindowSeconds = Double(wakeWindow.min * 60)
        
        var confidence: Double = 0.6
        var explanation: String
        
        if timeSinceWake >= minWakeWindowSeconds {
            confidence = 0.8
            explanation = "Baby has been awake for \(Int(timeSinceWake / 60)) minutes. Typical wake window for \(ageDescription(for: baby)) is \(wakeWindow.min)-\(wakeWindow.max) minutes."
        } else {
            let minutesUntilNap = Int((minWakeWindowSeconds - timeSinceWake) / 60)
            explanation = "Based on wake window patterns, next nap likely in about \(minutesUntilNap) minutes."
        }
        
        return Prediction(
            babyId: baby.id,
            type: .nextNap,
            predictedTime: predictedTime,
            confidence: confidence,
            explanation: explanation
        )
    }
    
    /// Generate a prediction for next feed.
    func predictNextFeed(for baby: Baby) async throws -> Prediction {
        // Fetch recent feed events
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        let events = try await dataStore.fetchEvents(for: baby, from: startDate, to: endDate)
        
        let feedEvents = events.filter { $0.type == .feed }
            .sorted { $0.startTime > $1.startTime }
        
        guard let lastFeed = feedEvents.first else {
            // No recent feed data, use age-based default
            let feedIntervalHours = FeedSpacingCalculator.feedIntervals[0] ?? 2.0
            let predictedTime = Date().addingTimeInterval(feedIntervalHours * 60 * 60)
            return Prediction(
                babyId: baby.id,
                type: .nextFeed,
                predictedTime: predictedTime,
                confidence: 0.5,
                explanation: "Based on typical feed intervals for \(ageDescription(for: baby))"
            )
        }
        
        let predictedTime = FeedSpacingCalculator.nextFeedTime(lastFeed: lastFeed.startTime, baby: baby)
        let confidence = FeedSpacingCalculator.confidence(lastFeed: lastFeed.startTime, baby: baby)
        
        let timeSinceLastFeed = Date().timeIntervalSince(lastFeed.startTime) / 3600.0
        let hoursUntilNextFeed = (predictedTime.timeIntervalSinceNow) / 3600.0
        
        var explanation: String
        if hoursUntilNextFeed <= 0 {
            explanation = "Feed is due now based on typical spacing for \(ageDescription(for: baby))."
        } else {
            explanation = "Based on last feed \(String(format: "%.1f", timeSinceLastFeed)) hours ago, next feed likely in about \(String(format: "%.1f", hoursUntilNextFeed)) hours."
        }
        
        return Prediction(
            babyId: baby.id,
            type: .nextFeed,
            predictedTime: predictedTime,
            confidence: confidence,
            explanation: explanation
        )
    }
    
    // MARK: - Helpers
    
    private func ageDescription(for baby: Baby) -> String {
        let ageInWeeks = Calendar.current.dateComponents([.weekOfYear], from: baby.dateOfBirth, to: Date()).weekOfYear ?? 0
        
        if ageInWeeks < 4 {
            return "newborn"
        } else if ageInWeeks < 8 {
            return "1 month old"
        } else if ageInWeeks < 12 {
            return "2 months old"
        } else if ageInWeeks < 16 {
            return "3 months old"
        } else if ageInWeeks < 20 {
            return "4 months old"
        } else if ageInWeeks < 24 {
            return "5 months old"
        } else if ageInWeeks < 28 {
            return "6 months old"
        } else {
            return "\(ageInWeeks / 4) months old"
        }
    }
}


