import Foundation

enum HistoryRange: String, CaseIterable, Identifiable {
    case last24Hours = "24h"
    case last7Days = "7 days"
    case last30Days = "30 days"

    var id: String { rawValue }

    var daysToFetch: Int {
        switch self {
        case .last24Hours: return 1
        case .last7Days: return 7
        case .last30Days: return 30
        }
    }
}

struct HistoryDay: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let events: [Event]
    let summary: HistoryDaySummary
    
    static func == (lhs: HistoryDay, rhs: HistoryDay) -> Bool {
        lhs.id == rhs.id
    }
}

struct HistoryDaySummary: Hashable {
    let totalSleepMinutes: Int
    let napCount: Int
    let feedCount: Int
    let diaperCount: Int
    let wetDiaperCount: Int
    let dirtyDiaperCount: Int
    let tummyTimeCount: Int
    let cryCount: Int
}

struct HistoryRangeSummary: Hashable {
    let range: HistoryRange
    let totalDays: Int
    let totalFeeds: Int
    let totalDiapers: Int
    let totalSleepMinutes: Int
    let totalCries: Int

    var avgFeedsPerDay: Double { guard totalDays > 0 else { return 0 }; return Double(totalFeeds) / Double(totalDays) }
    var avgDiapersPerDay: Double { guard totalDays > 0 else { return 0 }; return Double(totalDiapers) / Double(totalDays) }
    var avgSleepHoursPerDay: Double { guard totalDays > 0 else { return 0 }; return Double(totalSleepMinutes) / 60.0 / Double(totalDays) }
}


