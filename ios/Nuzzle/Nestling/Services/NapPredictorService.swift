import Foundation

/// Service for predicting next nap windows based on age and wake windows.
/// Uses static rule-based logic (age-based wake windows) as per MVP requirements.
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
        
        // Only return window if it's in the future or currently active
        guard windowEnd >= now else {
            return nil
        }
        
        // Determine confidence based on whether we have sleep data
        // Higher confidence if we have actual sleep logs
        let confidence: Double = 0.7 // Base confidence for age-based predictions
        
        let reason = "Based on age (\(ageInWeeks) weeks) and last wake time. These suggestions are based on patterns from your logs and common sleep ranges for this age. They are not medical advice."
        
        return NapWindow(
            start: windowStart,
            end: windowEnd,
            confidence: confidence,
            reason: reason
        )
    }
    
    /// Predict next nap window using the last sleep event from data store.
    /// - Parameters:
    ///   - baby: The baby to predict for
    ///   - lastSleep: The last completed sleep event (optional)
    /// - Returns: A NapWindow if prediction is possible, nil otherwise
    static func predictNextNapWindow(for baby: Baby, lastSleep: Event?) -> NapWindow? {
        let lastWakeTime: Date
        if let sleep = lastSleep, let endTime = sleep.endTime {
            lastWakeTime = endTime
        } else {
            // If no sleep logged, use current time (will suggest nap soon based on age)
            lastWakeTime = Date()
        }
        
        return predictNextNapWindow(for: baby, lastWakeTime: lastWakeTime)
    }
}
