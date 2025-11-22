import Foundation

/// Calculates feed spacing based on baby's age and recent feed patterns.
struct FeedSpacingCalculator {
    /// Age-based typical feed intervals (in hours).
    /// Key: age in weeks, Value: typical interval in hours
    static let feedIntervals: [Int: Double] = [
        0: 2.0,      // Newborn: every 2 hours
        4: 2.5,      // 1 month: every 2.5 hours
        8: 3.0,      // 2 months: every 3 hours
        12: 3.5,     // 3 months: every 3.5 hours
        16: 4.0,     // 4 months: every 4 hours
        20: 4.0,     // 5 months: every 4 hours
        24: 4.5,     // 6 months: every 4.5 hours
        28: 5.0,     // 7+ months: every 5 hours
    ]
    
    /// Calculate next feed time based on last feed and baby's age.
    static func nextFeedTime(lastFeed: Date, baby: Baby) -> Date {
        let ageInWeeks = Calendar.current.dateComponents([.weekOfYear], from: baby.dateOfBirth, to: Date()).weekOfYear ?? 0
        
        // Find feed interval for age
        var feedIntervalHours: Double = 3.0 // Default
        
        for age in feedIntervals.keys.sorted(by: >) {
            if ageInWeeks >= age {
                feedIntervalHours = feedIntervals[age] ?? 3.0
                break
            }
        }
        
        return lastFeed.addingTimeInterval(feedIntervalHours * 60 * 60)
    }
    
    /// Calculate confidence based on time since last feed and age.
    static func confidence(lastFeed: Date, baby: Baby) -> Double {
        let ageInWeeks = Calendar.current.dateComponents([.weekOfYear], from: baby.dateOfBirth, to: Date()).weekOfYear ?? 0
        let feedIntervalHours = feedIntervals[ageInWeeks] ?? 3.0
        let timeSinceLastFeed = Date().timeIntervalSince(lastFeed) / 3600.0 // Convert to hours
        
        // High confidence if we're close to typical interval
        let timeUntilNextFeed = feedIntervalHours - timeSinceLastFeed
        
        if timeUntilNextFeed <= 0 {
            return 0.9 // Overdue, high confidence
        } else if timeUntilNextFeed <= 0.5 {
            return 0.8 // Very soon
        } else if timeUntilNextFeed <= 1.0 {
            return 0.6 // Soon
        } else {
            return 0.4 // Further out, lower confidence
        }
    }
}

