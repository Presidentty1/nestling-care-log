import Foundation

/// Manages Cry Insights quota tracking for free users
struct CryInsightsQuotaManager {
    static let freeUserWeeklyLimit = 3
    
    /// Check if quota has been reset (new week started)
    static func shouldResetQuota(weekStart: Date?) -> Bool {
        guard let weekStart = weekStart else {
            return true // No week start recorded, reset
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Get start of current week (Monday)
        let currentWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        
        // Reset if week has changed
        return !calendar.isDate(weekStart, inSameDayAs: currentWeekStart)
    }
    
    /// Get start of current week (Monday)
    static func getCurrentWeekStart() -> Date {
        let calendar = Calendar.current
        let now = Date()
        return calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
    }
    
    /// Check if user can record (has quota remaining)
    static func canRecord(isPro: Bool, weeklyCount: Int, weekStart: Date?) -> Bool {
        if isPro {
            return true // Pro users have unlimited
        }
        
        // Check if week has reset
        if shouldResetQuota(weekStart: weekStart) {
            return true // New week, quota resets
        }
        
        return weeklyCount < freeUserWeeklyLimit
    }
    
    /// Get remaining quota for free users
    static func getRemainingQuota(isPro: Bool, weeklyCount: Int, weekStart: Date?) -> Int? {
        if isPro {
            return nil // Unlimited
        }
        
        if shouldResetQuota(weekStart: weekStart) {
            return freeUserWeeklyLimit // New week
        }
        
        return max(0, freeUserWeeklyLimit - weeklyCount)
    }
    
    /// Increment quota count and update week start if needed
    static func incrementQuota(currentCount: Int, currentWeekStart: Date?) -> (count: Int, weekStart: Date) {
        let newWeekStart = getCurrentWeekStart()
        
        if shouldResetQuota(weekStart: currentWeekStart) {
            // New week, reset count
            return (count: 1, weekStart: newWeekStart)
        } else {
            // Same week, increment
            return (count: currentCount + 1, weekStart: currentWeekStart ?? newWeekStart)
        }
    }
}

