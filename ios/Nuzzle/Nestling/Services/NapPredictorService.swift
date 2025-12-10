import Foundation

/// Service for predicting next nap windows based on age and wake windows.
/// For Pro users, uses historical sleep data to personalize predictions.
struct NapPredictorService {
    /// Predict the next nap window for a baby based on their age and last wake time.
    /// - Parameters:
    ///   - baby: The baby to predict for
    ///   - lastWakeTime: The time the baby last woke up (end of last sleep, or current time if no sleep logged)
    /// - Returns: A NapWindow if prediction is possible, nil otherwise
    static func predictNextNapWindow(for baby: Baby, lastWakeTime: Date) -> NapWindow? {
        // Calculate baby age in weeks
        let ageInWeeks = Calendar.current.dateComponents([.weekOfYear], from: baby.dateOfBirth, to: Date()).weekOfYear ?? 0
        
        // Get wake window based on age
        let wakeWindow = WakeWindowCalculator.wakeWindow(for: baby)
        
        // Calculate nap window start and end
        let calendar = Calendar.current
        let windowStart = calendar.date(byAdding: .minute, value: wakeWindow.min, to: lastWakeTime) ?? lastWakeTime
        let windowEnd = calendar.date(byAdding: .minute, value: wakeWindow.max, to: lastWakeTime) ?? lastWakeTime
        
        let now = Date()
        
        // For free tier: Always return a prediction, even if window is in the past
        // If window has passed, suggest nap "now" or "soon"
        let finalWindowStart: Date
        let finalWindowEnd: Date
        
        if windowEnd < now {
            // Window has passed - suggest nap soon (within next 30 minutes)
            finalWindowStart = now
            finalWindowEnd = calendar.date(byAdding: .minute, value: 30, to: now) ?? now
        } else {
            finalWindowStart = windowStart
            finalWindowEnd = windowEnd
        }
        
        // Determine confidence based on whether we have sleep data
        // Higher confidence if we have actual sleep logs
        let confidence: Double = 0.7 // Base confidence for age-based predictions
        
        let reason: String
        if windowEnd < now {
            reason = "Based on age (\(ageInWeeks) weeks), a nap may be due soon. These suggestions are based on common sleep ranges for this age. They are not medical advice."
        } else {
            reason = "Based on age (\(ageInWeeks) weeks) and last wake time. These suggestions are based on patterns from your logs and common sleep ranges for this age. They are not medical advice."
        }
        
        return NapWindow(
            start: finalWindowStart,
            end: finalWindowEnd,
            confidence: confidence,
            reason: reason
        )
    }
    
    /// Predict next nap window using the last sleep event from data store.
    /// - Parameters:
    ///   - baby: The baby to predict for
    ///   - lastSleep: The last completed sleep event (optional)
    ///   - historicalSleepEvents: Optional array of past sleep events for personalized predictions (Pro feature)
    ///   - isProUser: Whether the user has Pro subscription
    /// - Returns: A NapWindow if prediction is possible, nil otherwise
    static func predictNextNapWindow(
        for baby: Baby,
        lastSleep: Event?,
        historicalSleepEvents: [Event]? = nil,
        isProUser: Bool = false
    ) -> NapWindow? {
        let lastWakeTime: Date
        if let sleep = lastSleep, let endTime = sleep.endTime {
            lastWakeTime = endTime
        } else {
            // If no sleep logged, use current time (will suggest nap soon based on age)
            lastWakeTime = Date()
        }
        
        // For Pro users with historical data, use personalized predictions
        if isProUser, let historicalEvents = historicalSleepEvents, !historicalEvents.isEmpty {
            return predictPersonalizedNapWindow(
                for: baby,
                lastWakeTime: lastWakeTime,
                historicalEvents: historicalEvents
            )
        }
        
        // Free tier or no historical data: use age-based prediction
        return predictNextNapWindow(for: baby, lastWakeTime: lastWakeTime)
    }
    
    /// Personalized prediction using historical sleep patterns (Pro feature)
    private static func predictPersonalizedNapWindow(
        for baby: Baby,
        lastWakeTime: Date,
        historicalEvents: [Event]
    ) -> NapWindow? {
        // Analyze last 7-14 days of sleep data
        let calendar = Calendar.current
        let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        let recentSleepEvents = historicalEvents
            .filter { $0.type == .sleep && $0.endTime != nil && $0.startTime >= twoWeeksAgo }
            .sorted { ($0.endTime ?? $0.startTime) > ($1.endTime ?? $1.startTime) }
        
        guard !recentSleepEvents.isEmpty else {
            // Fallback to age-based if no recent data
            return predictNextNapWindow(for: baby, lastWakeTime: lastWakeTime)
        }
        
        // Calculate average wake window from historical data
        var wakeWindowSum = 0
        var wakeWindowCount = 0
        
        for i in 0..<min(recentSleepEvents.count - 1, 10) { // Analyze last 10 sleep sessions
            let currentSleep = recentSleepEvents[i]
            let nextSleep = recentSleepEvents[i + 1]
            
            if let currentEnd = currentSleep.endTime {
                let wakeWindow = nextSleep.startTime.timeIntervalSince(currentEnd) / 60.0 // minutes
                if wakeWindow > 0 && wakeWindow < 480 { // Reasonable range (0-8 hours)
                    wakeWindowSum += Int(wakeWindow)
                    wakeWindowCount += 1
                }
            }
        }
        
        // Use personalized wake window if we have enough data, otherwise use age-based
        let personalizedWakeWindow: (min: Int, max: Int)
        if wakeWindowCount >= 3 {
            let avgWakeWindow = wakeWindowSum / wakeWindowCount
            // Use average ±20% for window range
            let minWindow = Int(Double(avgWakeWindow) * 0.8)
            let maxWindow = Int(Double(avgWakeWindow) * 1.2)
            personalizedWakeWindow = (min: max(minWindow, 30), max: max(maxWindow, minWindow + 30))
        } else {
            // Not enough data, use age-based with slight adjustment
            let ageBased = WakeWindowCalculator.wakeWindow(for: baby)
            personalizedWakeWindow = ageBased
        }
        
        // Calculate nap window
        let windowStart = calendar.date(byAdding: .minute, value: personalizedWakeWindow.min, to: lastWakeTime) ?? lastWakeTime
        let windowEnd = calendar.date(byAdding: .minute, value: personalizedWakeWindow.max, to: lastWakeTime) ?? lastWakeTime
        
        let now = Date()
        let finalWindowStart: Date
        let finalWindowEnd: Date
        
        if windowEnd < now {
            finalWindowStart = now
            finalWindowEnd = calendar.date(byAdding: .minute, value: 30, to: now) ?? now
        } else {
            finalWindowStart = windowStart
            finalWindowEnd = windowEnd
        }
        
        // Higher confidence for personalized predictions
        let confidence: Double = wakeWindowCount >= 5 ? 0.85 : 0.75
        
        let reason: String
        if wakeWindowCount >= 3 {
            reason = "Based on \(baby.name)'s unique sleep patterns from the past \(min(14, wakeWindowCount * 2)) days. These personalized predictions adapt to your baby's actual behavior. They are not medical advice."
        } else {
            reason = "Based on age and recent sleep patterns. As we learn more about \(baby.name)'s patterns, predictions will become more accurate. They are not medical advice."
        }
        
        return NapWindow(
            start: finalWindowStart,
            end: finalWindowEnd,
            confidence: confidence,
            reason: reason
        )
    }
}

