import Foundation

/// Analytics event structure
struct AnalyticsEvent {
    let name: String
    let properties: [String: Any]
    let timestamp: Date
    
    init(name: String, properties: [String: Any] = [:]) {
        self.name = name
        self.properties = properties
        self.timestamp = Date()
    }
}

/// Protocol for analytics services
protocol AnalyticsService {
    func logEvent(_ event: String, parameters: [String: Any]?)
}

/// Shared analytics instance
actor Analytics {
    static let shared = Analytics()
    
    private var service: AnalyticsService = ConsoleAnalytics()
    
    private init() {}
    
    func setService(_ service: AnalyticsService) {
        self.service = service
    }
    
    func log(_ event: String, parameters: [String: Any]? = nil) {
        service.logEvent(event, parameters: parameters)
    }
}

/// Console-based analytics (development)
class ConsoleAnalytics: AnalyticsService {
    func logEvent(_ event: String, parameters: [String: Any]?) {
        if let params = parameters {
            print("[Analytics] \(event): \(params)")
        } else {
            print("[Analytics] \(event)")
        }
    }
}

/// Test analytics sink for unit tests
class TestAnalytics: AnalyticsService {
    var events: [AnalyticsEvent] = []
    
    func logEvent(_ event: String, parameters: [String: Any]?) {
        let analyticsEvent = AnalyticsEvent(
            name: event,
            properties: parameters ?? [:]
        )
        events.append(analyticsEvent)
    }
    
    func clear() {
        events.removeAll()
    }
}

