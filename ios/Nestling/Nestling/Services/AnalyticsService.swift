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

    // MARK: - Key Analytics Events

    func logOnboardingCompleted(babyId: String) {
        log("onboarding_completed", parameters: ["baby_id": babyId])
    }

    func logFirstLogCreated(eventType: String, babyId: String) {
        log("first_log_created", parameters: ["event_type": eventType, "baby_id": babyId])
    }

    func logPredictionShown(type: String, isPro: Bool, babyId: String) {
        log("prediction_shown", parameters: ["type": type, "is_pro": isPro, "baby_id": babyId])
    }

    func logPaywallViewed(source: String) {
        log("paywall_viewed", parameters: ["source": source])
    }

    func logSubscriptionStarted(productId: String, price: String) {
        log("subscription_started", parameters: ["product_id": productId, "price": price])
    }

    func logCaregiverInviteSent(method: String) {
        log("caregiver_invite_sent", parameters: ["method": method])
    }

    func logCaregiverInviteAccepted() {
        log("caregiver_invite_accepted")
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

