import Foundation

/// Types of log entries supported by the app
enum LogEntryType: String, Codable, CaseIterable {
    case feed
    case diaper
    case sleep
    case tummyTime

    /// Display name for UI
    var displayName: String {
        switch self {
        case .feed: return "Feed"
        case .diaper: return "Diaper"
        case .sleep: return "Sleep"
        case .tummyTime: return "Tummy Time"
        }
    }

    /// Icon name for UI
    var iconName: String {
        switch self {
        case .feed: return "drop.fill"
        case .diaper: return "drop.circle.fill"
        case .sleep: return "moon.fill"
        case .tummyTime: return "figure.child"
        }
    }

    /// Accent color for UI (using NuzzleTheme colors)
    var accentColor: String {
        switch self {
        case .feed: return "nuzzlePrimary" // Teal/mint
        case .sleep: return "nuzzleAccentSleep" // Indigo
        case .diaper: return "nuzzleAccentDiaper" // Amber
        case .tummyTime: return "nuzzleAccentTummy" // Green
        }
    }
}

/// Source of the log entry
enum LogEntrySource: String, Codable {
    case manual
    case reminder
    case aiSuggestion
    case quickAction
}



