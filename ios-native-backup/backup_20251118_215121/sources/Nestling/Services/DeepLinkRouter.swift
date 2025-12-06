import Foundation
import SwiftUI

enum DeepLinkRoute {
    case logFeed(amount: Double?, unit: String?)
    case logDiaper(type: String?)
    case logTummy(duration: Double?)
    case sleepStart
    case sleepStop
    case openHome
    case openPredictions
    case openHistory
    case openSettings
    case unknown
}

class DeepLinkRouter {
    static func parse(url: URL) -> DeepLinkRoute {
        guard url.scheme == "nestling" else { return .unknown }
        
        let path = url.pathComponents
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        
        switch path.first {
        case "log":
            if path.count > 1 {
                switch path[1] {
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
            if path.count > 1 {
                switch path[1] {
                case "start": return .sleepStart
                case "stop": return .sleepStop
                default: break
                }
            }
        case "open":
            if path.count > 1 {
                switch path[1] {
                case "home": return .openHome
                case "predictions": return .openPredictions
                case "history": return .openHistory
                case "settings": return .openSettings
                default: break
                }
            }
        default:
            break
        }
        
        return .unknown
    }
}

