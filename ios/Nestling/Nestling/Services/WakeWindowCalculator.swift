import Foundation

/// Calculates wake windows based on baby's age.
struct WakeWindowCalculator {
    /// Age-based wake window ranges (in minutes).
    /// Key: age in weeks, Value: (min, max) wake window in minutes
    static let wakeWindows: [Int: (min: Int, max: Int)] = [
        0: (45, 60),      // Newborn
        4: (60, 90),      // 1 month
        8: (75, 105),     // 2 months
        12: (90, 120),    // 3 months
        16: (105, 135),   // 4 months
        20: (120, 150),   // 5 months
        24: (135, 165),   // 6 months
        28: (150, 180),   // 7 months
        32: (165, 195),   // 8 months
        36: (180, 210),   // 9 months
        40: (195, 225),   // 10 months
        44: (210, 240),   // 11 months
        48: (225, 255)    // 12 months
    ]
    
    /// Calculate wake window for a baby based on their age.
    static func wakeWindow(for baby: Baby) -> (min: Int, max: Int) {
        let ageInWeeks = Calendar.current.dateComponents([.weekOfYear], from: baby.dateOfBirth, to: Date()).weekOfYear ?? 0
        
        // Find the closest age bracket
        var closestAge = 0
        var minDiff = Int.max
        
        for age in wakeWindows.keys.sorted() {
            let diff = abs(age - ageInWeeks)
            if diff < minDiff {
                minDiff = diff
                closestAge = age
            }
        }
        
        return wakeWindows[closestAge] ?? (90, 120) // Default for older babies
    }
    
    /// Calculate next nap time based on last sleep and wake window.
    static func nextNapTime(lastSleepEnd: Date, wakeWindow: (min: Int, max: Int)) -> Date {
        let timeSinceWake = Date().timeIntervalSince(lastSleepEnd)
        let minWakeWindowSeconds = Double(wakeWindow.min * 60)
        let maxWakeWindowSeconds = Double(wakeWindow.max * 60)
        
        // If we're past the minimum wake window, suggest nap soon
        if timeSinceWake >= minWakeWindowSeconds {
            // Suggest nap within next 15-30 minutes
            return Date().addingTimeInterval(15 * 60)
        } else {
            // Suggest nap when minimum wake window is reached
            return lastSleepEnd.addingTimeInterval(minWakeWindowSeconds)
        }
    }
}

