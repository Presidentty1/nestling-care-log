import Foundation

import Foundation

struct DateUtils {
    /// Calendar instance for date operations (uses current timezone)
    private static var calendar: Calendar {
        var cal = Calendar.current
        cal.timeZone = TimeZone.current // Explicit timezone handling
        return cal
    }
    
    /// Format time as "2:30 PM" (respects locale and 12/24h setting)
    static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }
    
    /// Format date as "Nov 15, 2024" (respects locale)
    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }
    
    /// Format relative time: "2h ago", "5m ago", "Just now"
    static func formatRelativeTime(_ date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
    
    /// Format duration: "2h 15m" or "45m"
    static func formatDuration(minutes: Int) -> String {
        guard minutes > 0 else { return "0m" }
        
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(mins)m"
            }
        }
    }
    
    /// Calculate duration between two dates in minutes (DST-safe)
    static func durationMinutes(from start: Date, to end: Date) -> Int {
        let components = calendar.dateComponents([.minute], from: start, to: end)
        return abs(components.minute ?? 0)
    }
    
    /// Get start of day (DST-safe, uses local timezone)
    static func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }
    
    /// Get end of day (DST-safe, uses local timezone)
    static func endOfDay(for date: Date) -> Date {
        let start = startOfDay(for: date)
        return calendar.date(byAdding: .day, value: 1, to: start) ?? date
    }
    
    /// Get date bucket for grouping events by local day (handles DST transitions)
    static func dayBucket(for date: Date) -> Date {
        startOfDay(for: date)
    }
    
    /// Check if date is today (in local timezone)
    static func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }
    
    /// Check if date is yesterday (in local timezone)
    static func isYesterday(_ date: Date) -> Bool {
        calendar.isDateInYesterday(date)
    }
    
    /// Get last N days including today (in local timezone)
    static func lastNDays(_ n: Int) -> [Date] {
        let today = Date()
        return (0..<n).compactMap { daysAgo in
            calendar.date(byAdding: .day, value: -daysAgo, to: today)
        }
    }
    
    /// Check if two dates are on the same local day (DST-safe)
    static func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        calendar.isDate(date1, inSameDayAs: date2)
    }
    
    /// Get midnight rollover time for a given date (handles DST)
    static func midnight(for date: Date) -> Date {
        startOfDay(for: date)
    }
    
    /// Adjust date for timezone changes (useful when traveling)
    static func adjustForTimezone(_ date: Date, from oldTimezone: TimeZone, to newTimezone: TimeZone) -> Date {
        let offset = newTimezone.secondsFromGMT(for: date) - oldTimezone.secondsFromGMT(for: date)
        return date.addingTimeInterval(TimeInterval(offset))
    }
}

