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

    // MARK: - Pricing Experiment Analytics

    func logPricingExperimentAssigned(variant: String) {
        log("pricing_experiment_assigned", parameters: ["variant": variant])
    }

    func logPricingTrialStarted(variant: String, trialDays: Int) {
        log("pricing_trial_started", parameters: [
            "variant": variant,
            "trial_days": trialDays
        ])
    }

    func logPricingTrialConverted(variant: String, revenue: Double, monthlyPrice: Double) {
        log("pricing_trial_converted", parameters: [
            "variant": variant,
            "revenue": revenue,
            "monthly_price": monthlyPrice
        ])
    }

    func logPricingTrialExpired(variant: String, converted: Bool, trialDays: Int) {
        log("pricing_trial_expired", parameters: [
            "variant": variant,
            "converted": converted,
            "trial_days": trialDays
        ])
    }

    func logPricingPaywallViewed(variant: String) {
        log("pricing_paywall_viewed", parameters: ["variant": variant])
    }

    // MARK: - Widget Analytics

    func logWidgetOnboardingShown() {
        log("widget_onboarding_shown")
    }

    func logWidgetOnboardingCompleted() {
        log("widget_onboarding_completed")
    }

    func logWidgetPromptShown() {
        log("widget_prompt_shown")
    }

    func logWidgetPromptDismissed() {
        log("widget_prompt_dismissed")
    }

    func logWidgetPromptClicked() {
        log("widget_prompt_clicked")
    }

    func logWidgetImpression(widgetType: String) {
        log("widget_impression", parameters: ["widget_type": widgetType])
    }

    func logWidgetTapped(widgetType: String) {
        log("widget_tapped", parameters: ["widget_type": widgetType])
    }

    func logWidgetLogCompleted(widgetType: String, eventType: String) {
        log("widget_log_completed", parameters: [
            "widget_type": widgetType,
            "event_type": eventType
        ])
    }

    // MARK: - Referral Analytics

    func logReferralLinkShared(channel: String) {
        log("referral_link_shared", parameters: ["channel": channel])
    }

    func logReferralInviteAccepted(referralCode: String) {
        log("referral_invite_accepted", parameters: ["referral_code": referralCode])
    }

    func logReferralRefereeActivated(referralCode: String) {
        log("referral_referee_activated", parameters: ["referral_code": referralCode])
    }

    func logReferralRewardClaimed(reward: String) {
        log("referral_reward_claimed", parameters: ["reward": reward])
    }

    // MARK: - Medical Citation Analytics

    func logCitationBadgeTapped(feature: String) {
        log("citation_badge_tapped", parameters: ["feature": feature])
    }

    func logCitationTooltipViewed(feature: String) {
        log("citation_tooltip_viewed", parameters: ["feature": feature])
    }

    func logCitationLinkClicked(feature: String, url: String) {
        log("citation_link_clicked", parameters: ["feature": feature, "url": url])
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

