import Foundation

enum EventTypeFilter: String, CaseIterable {
    case all = "All"
    case feeds = "Feeds"
    case diapers = "Diapers"
    case sleep = "Sleep"
    case tummy = "Tummy"
    
    var displayName: String {
        rawValue
    }
    
    var iconName: String {
        switch self {
        case .all: return "list.bullet"
        case .feeds: return "drop.fill"
        case .diapers: return "drop.circle.fill"
        case .sleep: return "moon.fill"
        case .tummy: return "figure.child"
        }
    }
}


