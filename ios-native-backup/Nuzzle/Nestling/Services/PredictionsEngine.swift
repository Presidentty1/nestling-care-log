import Foundation

/// On-device predictions engine using deterministic heuristics.
/// No networking required; all calculations are local.
class PredictionsEngine {
    private let dataStore: DataStore
    
    init(dataStore: DataStore) {
        self.dataStore = dataStore
    }
    
    /// Generate a prediction for next nap.
    func predictNextNap(for baby: Baby, isPro: Bool = false) async throws -> Prediction {
        // Fetch recent sleep events (more data for Pro users)
        let endDate = Date()
        let daysBack = isPro ? 14 : 7 // Pro users get 14 days of data
        let startDate = Calendar.current.date(byAdding: .day, value: -daysBack, to: endDate) ?? endDate
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
        
        // Pro users get personalized predictions based on actual patterns
        var predictedTime: Date
        var confidence: Double
        var explanation: String
        
        if isPro && sleepEvents.count >= 3 {
            // Analyze patterns: typical nap duration, typical times of day
            let napDurations = sleepEvents.compactMap { event -> TimeInterval? in
                guard let endTime = event.endTime else { return nil }
                return endTime.timeIntervalSince(event.startTime)
            }
            let avgNapDuration = napDurations.isEmpty ? 0 : napDurations.reduce(0, +) / Double(napDurations.count)
            
            // Find typical nap times (group by hour of day)
            let calendar = Calendar.current
            let napHours = sleepEvents.compactMap { event -> Int? in
                guard let endTime = event.endTime else { return nil }
                return calendar.component(.hour, from: endTime)
            }
            
            // Use personalized wake window if we have enough data
            let personalizedWindow = calculatePersonalizedWakeWindow(
                sleepEvents: sleepEvents,
                defaultWindow: wakeWindow
            )
            
            predictedTime = WakeWindowCalculator.nextNapTime(
                lastSleepEnd: lastSleepEnd,
                wakeWindow: personalizedWindow
            )
            
            let timeSinceWake = Date().timeIntervalSince(lastSleepEnd)
            let minWakeWindowSeconds = Double(personalizedWindow.min * 60)
            
            if timeSinceWake >= minWakeWindowSeconds {
                confidence = 0.85
                let typicalDuration = Int(avgNapDuration / 60)
                explanation = "Based on \(baby.name)'s patterns, they usually nap around \(typicalDuration) min at this time. Wake window adjusted to \(personalizedWindow.min)-\(personalizedWindow.max) min based on recent naps."
            } else {
                let minutesUntilNap = Int((minWakeWindowSeconds - timeSinceWake) / 60)
                explanation = "Based on \(baby.name)'s recent patterns, next nap likely in about \(minutesUntilNap) minutes."
                confidence = 0.75
            }
        } else {
            // Free users get basic age-based predictions
            predictedTime = WakeWindowCalculator.nextNapTime(lastSleepEnd: lastSleepEnd, wakeWindow: wakeWindow)
            
            let timeSinceWake = Date().timeIntervalSince(lastSleepEnd)
            let minWakeWindowSeconds = Double(wakeWindow.min * 60)
            
            if timeSinceWake >= minWakeWindowSeconds {
                confidence = 0.7
                explanation = "Baby has been awake for \(Int(timeSinceWake / 60)) minutes. Typical wake window for \(ageDescription(for: baby)) is \(wakeWindow.min)-\(wakeWindow.max) minutes."
            } else {
                let minutesUntilNap = Int((minWakeWindowSeconds - timeSinceWake) / 60)
                explanation = "Based on age-based wake windows, next nap likely in about \(minutesUntilNap) minutes."
                confidence = 0.6
            }
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
    func predictNextFeed(for baby: Baby, isPro: Bool = false) async throws -> Prediction {
        // Fetch recent feed events (more data for Pro users)
        let endDate = Date()
        let daysBack = isPro ? 14 : 7 // Pro users get 14 days of data
        let startDate = Calendar.current.date(byAdding: .day, value: -daysBack, to: endDate) ?? endDate
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
        
        var predictedTime: Date
        var confidence: Double
        var explanation: String
        
        if isPro && feedEvents.count >= 5 {
            // Pro: Analyze patterns - cluster feeding, overnight patterns, typical intervals
            let intervals = zip(feedEvents, feedEvents.dropFirst()).map { feed1, feed2 in
                feed2.startTime.timeIntervalSince(feed1.startTime) / 3600.0 // hours
            }
            let avgInterval = intervals.isEmpty ? 3.0 : intervals.reduce(0, +) / Double(intervals.count)
            
            // Detect cluster feeding (multiple feeds within 2 hours)
            let recentFeeds = feedEvents.prefix(3)
            let isClusterFeeding = recentFeeds.count >= 2 && 
                recentFeeds[0].startTime.timeIntervalSince(recentFeeds[1].startTime) < 2 * 3600
            
            // Adjust prediction based on patterns
            if isClusterFeeding {
                predictedTime = lastFeed.startTime.addingTimeInterval(1.5 * 3600) // Shorter interval during cluster
                confidence = 0.8
                explanation = "Detected cluster feeding pattern. \(baby.name) typically feeds more frequently during these times. Next feed likely in about 1.5 hours."
            } else {
                predictedTime = lastFeed.startTime.addingTimeInterval(avgInterval * 3600)
                confidence = 0.75
                let timeSinceLastFeed = Date().timeIntervalSince(lastFeed.startTime) / 3600.0
                let hoursUntilNextFeed = (predictedTime.timeIntervalSinceNow) / 3600.0
                if hoursUntilNextFeed <= 0 {
                    explanation = "Based on \(baby.name)'s typical \(String(format: "%.1f", avgInterval))-hour feeding pattern, feed is due now."
                } else {
                    explanation = "Based on \(baby.name)'s patterns, next feed likely in about \(String(format: "%.1f", hoursUntilNextFeed)) hours (typical interval: \(String(format: "%.1f", avgInterval)) hours)."
                }
            }
        } else {
            // Free: Basic age-based prediction
            predictedTime = FeedSpacingCalculator.nextFeedTime(lastFeed: lastFeed.startTime, baby: baby)
            confidence = FeedSpacingCalculator.confidence(lastFeed: lastFeed.startTime, baby: baby)
            
            let timeSinceLastFeed = Date().timeIntervalSince(lastFeed.startTime) / 3600.0
            let hoursUntilNextFeed = (predictedTime.timeIntervalSinceNow) / 3600.0
            
            if hoursUntilNextFeed <= 0 {
                explanation = "Feed is due now based on typical spacing for \(ageDescription(for: baby))."
            } else {
                explanation = "Based on last feed \(String(format: "%.1f", timeSinceLastFeed)) hours ago, next feed likely in about \(String(format: "%.1f", hoursUntilNextFeed)) hours."
            }
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
    
    /// Calculate personalized wake window based on actual sleep patterns (Pro feature)
    private func calculatePersonalizedWakeWindow(
        sleepEvents: [Event],
        defaultWindow: (min: Int, max: Int)
    ) -> (min: Int, max: Int) {
        guard sleepEvents.count >= 3 else {
            return defaultWindow
        }
        
        // Calculate average time between sleep end and next sleep start
        let calendar = Calendar.current
        var wakeDurations: [TimeInterval] = []
        
        for i in 0..<sleepEvents.count - 1 {
            guard let endTime = sleepEvents[i].endTime else { continue }
            let nextStartTime = sleepEvents[i + 1].startTime
            let wakeDuration = nextStartTime.timeIntervalSince(endTime) / 60.0 // minutes
            if wakeDuration > 0 && wakeDuration < 480 { // Reasonable range: 0-8 hours
                wakeDurations.append(wakeDuration)
            }
        }
        
        guard !wakeDurations.isEmpty else {
            return defaultWindow
        }
        
        let avgWakeDuration = wakeDurations.reduce(0, +) / Double(wakeDurations.count)
        let minWake = max(30, Int(avgWakeDuration * 0.8)) // 80% of average, min 30 min
        let maxWake = Int(avgWakeDuration * 1.2) // 120% of average
        
        // Ensure within reasonable bounds
        return (
            min: min(minWake, defaultWindow.max),
            max: max(maxWake, defaultWindow.min)
        )
    }
}

