import Foundation
import FirebaseAnalytics

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

    private var service: AnalyticsService = {
        // Try to initialize Firebase Analytics, fall back to console
        if let firebaseAnalytics = FirebaseAnalyticsService() {
            return firebaseAnalytics
        } else {
            return ConsoleAnalytics()
        }
    }()

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
    
    func logOnboardingGoalSelected(goal: String) {
        log("onboarding_goal_selected", parameters: ["goal": goal])
    }
    
    func logOnboardingStepViewed(step: String) {
        log("onboarding_step_viewed", parameters: ["step": step])
    }
    
    func logOnboardingStepSkipped(step: String) {
        log("onboarding_step_skipped", parameters: ["step": step])
    }
    
    func logOnboardingStarted() {
        log("onboarding_started", parameters: [:])
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

    // MARK: - Subscription Events

    func logSubscriptionTrialStarted(plan: String, source: String) {
        log("subscription_trial_started", parameters: ["plan": plan, "source": source])
    }

    func logSubscriptionActivated(plan: String, price: String) {
        log("subscription_activated", parameters: ["plan": plan, "price": price])
    }

    func logSubscriptionRenewed(plan: String) {
        log("subscription_renewed", parameters: ["plan": plan])
    }

    func logSubscriptionCancelled(plan: String, reason: String?) {
        var params: [String: Any] = ["plan": plan]
        if let reason = reason {
            params["reason"] = reason
        }
        log("subscription_cancelled", parameters: params)
    }

    func logSubscriptionPurchased(productId: String, price: String) {
        log("subscription_purchased", parameters: ["product_id": productId, "price": price])
    }

    // MARK: - Core Product Usage Events

    func logFeedLogged(babyId: String, quantity: Double?, type: String?) {
        var params: [String: Any] = ["baby_id": babyId]
        if let quantity = quantity {
            params["quantity"] = quantity
        }
        if let type = type {
            params["type"] = type
        }
        log("log_feed", parameters: params)
    }

    func logDiaperLogged(babyId: String, type: String) {
        log("log_diaper", parameters: ["baby_id": babyId, "type": type])
    }

    func logSleepStarted(babyId: String) {
        log("log_sleep_start", parameters: ["baby_id": babyId])
    }

    func logSleepStopped(babyId: String, durationMinutes: Int) {
        log("log_sleep_stop", parameters: ["baby_id": babyId, "duration_minutes": durationMinutes])
    }

    // MARK: - AI Feature Events

    func logNapPredictionRequested(babyId: String, isPro: Bool) {
        log("ai_nap_prediction_requested", parameters: ["baby_id": babyId, "is_pro": isPro])
    }

    func logCryAnalysisRequested(babyId: String, isPro: Bool) {
        log("ai_cry_analysis_requested", parameters: ["baby_id": babyId, "is_pro": isPro])
    }

    func logAIAssistantOpened(babyId: String, isPro: Bool) {
        log("ai_assistant_opened", parameters: ["baby_id": babyId, "is_pro": isPro])
    }

    // MARK: - Legacy/Updated Events

    func logSubscriptionStarted(productId: String, price: String) {
        // Deprecated: use logSubscriptionPurchased instead
        logSubscriptionPurchased(productId: productId, price: price)
    }

    func logCaregiverInviteSent(method: String) {
        log("caregiver_invite_sent", parameters: ["method": method])
    }

    func logCaregiverInviteAccepted() {
        log("caregiver_invite_accepted")
    }
}

/// Firebase Analytics implementation
class FirebaseAnalyticsService: AnalyticsService {
    private let isEnabled: Bool

    init?() {
        // Check if Firebase is properly configured
        guard let _ = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") else {
            print("[Analytics] Firebase not configured, using console analytics")
            return nil
        }

        // Check environment variable
        let firebaseEnabled = ProcessInfo.processInfo.environment["FIREBASE_ENABLED"] == "true"
        self.isEnabled = firebaseEnabled

        if isEnabled {
            print("[Analytics] Firebase Analytics initialized")
        } else {
            print("[Analytics] Firebase Analytics disabled via environment")
        }
    }

    func logEvent(_ event: String, parameters: [String: Any]?) {
        guard isEnabled else {
            // Fallback to console logging
            if let params = parameters {
                print("[Analytics] \(event): \(params)")
            } else {
                print("[Analytics] \(event)")
            }
            return
        }

        // Convert event name to Firebase-friendly format (alphanumeric + underscore, max 40 chars)
        let firebaseEventName = event
            .replacingOccurrences(of: "[^a-zA-Z0-9_]", with: "_", options: .regularExpression)
            .prefix(40)
            .description

        // Convert parameters to Firebase-compatible format
        var firebaseParameters: [String: Any] = [:]
        if let params = parameters {
            for (key, value) in params {
                let firebaseKey = key
                    .replacingOccurrences(of: "[^a-zA-Z0-9_]", with: "_", options: .regularExpression)
                    .prefix(40)
                    .description
                firebaseParameters[firebaseKey] = value
            }
        }

        FirebaseAnalytics.Analytics.logEvent(firebaseEventName, parameters: firebaseParameters.isEmpty ? nil : firebaseParameters)
    }

    func setUserId(_ userId: String) {
        guard isEnabled else { return }
        FirebaseAnalytics.Analytics.setUserID(userId)
    }

    func setUserProperty(_ name: String, value: String) {
        guard isEnabled else { return }
        FirebaseAnalytics.Analytics.setUserProperty(value, forName: name)
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

