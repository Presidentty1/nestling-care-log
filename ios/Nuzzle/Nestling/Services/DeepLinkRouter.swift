import Foundation
import SwiftUI

enum DeepLinkRoute: Equatable {
    // Logging actions
    case logFeed(amount: Double?, unit: String?)
    case logDiaper(type: String?)
    case logTummy(duration: Double?)
    case sleepStart
    case sleepStop
    
    // Navigation
    case openHome
    case openPredictions
    case openHistory
    case openSettings
    
    // Extended routes for rich notifications
    case openHomeSummary
    case openHistoryInsights
    case openMilestones
    case openPaywall(source: String?)
    case openHelpCenter
    case openPrivacy
    case shareWeeklySummary(weekNumber: Int?)
    
    // Widget routes
    case widgetQuickLog(type: String)
    
    case unknown
}

class DeepLinkRouter {
    static func parse(url: URL) -> DeepLinkRoute {
        guard url.scheme == "nestling" else { return .unknown }

        // For custom schemes, we treat host as the first segment.
        // Example: nestling://log/feed?amount=120&unit=ml
        // - host = "log"
        // - path = "/feed"
        let host = url.host ?? ""
        let pathSegments = url.path
            .split(separator: "/")
            .map { String($0) }
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []

        switch host {
        case "log":
            if let first = pathSegments.first {
                switch first {
                case "feed":
                    let amount = queryItems.first(where: { $0.name == "amount" })?.value.flatMap { Double($0) }
                    let unit = queryItems.first(where: { $0.name == "unit" })?.value
                    return .logFeed(amount: amount, unit: unit)
                case "diaper":
                    let type = queryItems.first(where: { $0.name == "type" })?.value
                    return .logDiaper(type: type)
                case "tummy":
                    let duration = queryItems.first(where: { $0.name == "duration" })?.value.flatMap { Double($0) }
                    return .logTummy(duration: duration)
                default:
                    break
                }
            }
        case "sleep":
            if let first = pathSegments.first {
                switch first {
                case "start": return .sleepStart
                case "stop": return .sleepStop
                default: break
                }
            }
        case "open":
            if let first = pathSegments.first {
                switch first {
                case "home": 
                    // Check for sub-routes like /home/summary
                    if pathSegments.count > 1, pathSegments[1] == "summary" {
                        return .openHomeSummary
                    }
                    return .openHome
                case "predictions": return .openPredictions
                case "history":
                    // Check for sub-routes like /history/insights
                    if pathSegments.count > 1, pathSegments[1] == "insights" {
                        return .openHistoryInsights
                    }
                    return .openHistory
                case "settings": return .openSettings
                case "milestones": return .openMilestones
                case "paywall":
                    let source = queryItems.first(where: { $0.name == "source" })?.value
                    return .openPaywall(source: source)
                case "help": return .openHelpCenter
                case "privacy": return .openPrivacy
                default: break
                }
            }
        case "share":
            if let first = pathSegments.first, first == "weekly" {
                let weekNumber = queryItems.first(where: { $0.name == "week" })?.value.flatMap { Int($0) }
                return .shareWeeklySummary(weekNumber: weekNumber)
            }
        case "widget":
            if let first = pathSegments.first {
                return .widgetQuickLog(type: first)
            }
        case "home":
            // Handle shorthand like nestling://home/summary
            if pathSegments.first == "summary" {
                return .openHomeSummary
            }
            return .openHome
        case "history":
            // Handle shorthand like nestling://history/insights
            if pathSegments.first == "insights" {
                return .openHistoryInsights
            }
            return .openHistory
        default:
            break
        }

        return .unknown
    }
    
    /// Build a deep link URL from a route
    static func url(for route: DeepLinkRoute) -> URL? {
        switch route {
        case .logFeed(let amount, let unit):
            var urlString = "nestling://log/feed"
            var params: [String] = []
            if let amount = amount { params.append("amount=\(amount)") }
            if let unit = unit { params.append("unit=\(unit)") }
            if !params.isEmpty { urlString += "?\(params.joined(separator: "&"))" }
            return URL(string: urlString)
            
        case .logDiaper(let type):
            var urlString = "nestling://log/diaper"
            if let type = type { urlString += "?type=\(type)" }
            return URL(string: urlString)
            
        case .logTummy(let duration):
            var urlString = "nestling://log/tummy"
            if let duration = duration { urlString += "?duration=\(duration)" }
            return URL(string: urlString)
            
        case .sleepStart: return URL(string: "nestling://sleep/start")
        case .sleepStop: return URL(string: "nestling://sleep/stop")
        case .openHome: return URL(string: "nestling://open/home")
        case .openHomeSummary: return URL(string: "nestling://open/home/summary")
        case .openPredictions: return URL(string: "nestling://open/predictions")
        case .openHistory: return URL(string: "nestling://open/history")
        case .openHistoryInsights: return URL(string: "nestling://open/history/insights")
        case .openSettings: return URL(string: "nestling://open/settings")
        case .openMilestones: return URL(string: "nestling://open/milestones")
        case .openPaywall(let source):
            var urlString = "nestling://open/paywall"
            if let source = source { urlString += "?source=\(source)" }
            return URL(string: urlString)
        case .openHelpCenter: return URL(string: "nestling://open/help")
        case .openPrivacy: return URL(string: "nestling://open/privacy")
        case .shareWeeklySummary(let weekNumber):
            var urlString = "nestling://share/weekly"
            if let week = weekNumber { urlString += "?week=\(week)" }
            return URL(string: urlString)
        case .widgetQuickLog(let type): return URL(string: "nestling://widget/\(type)")
        case .unknown: return nil
        }
    }
}

