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

/// First-party, privacy-respecting analytics service
/// No third-party SDKs, no PII, can be disabled by user, aggregate data only
class AnalyticsService {
    static let shared = AnalyticsService()
    
    private var events: [AnalyticsEvent] = []
    private let maxEventsInMemory = 1000
    
    private var isEnabled: Bool {
        UserDefaults.standard.object(forKey: "analytics_enabled") as? Bool ?? true
    }
    
    private init() {}
    
    /// Enable/disable analytics (user preference)
    func setEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "analytics_enabled")
        
        if !enabled {
            // Clear stored events when disabled
            events.removeAll()
        }
    }
    
    /// Track an event with properties (no PII)
    func track(event: String, properties: [String: Any] = [:]) {
        guard isEnabled else { return }
        
        let analyticsEvent = AnalyticsEvent(name: event, properties: sanitizeProperties(properties))
        events.append(analyticsEvent)
        
        // Trim old events to prevent memory growth
        if events.count > maxEventsInMemory {
            events.removeFirst(events.count - maxEventsInMemory)
        }
        
        #if DEBUG
        let propsString = properties.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
        print("[Analytics] \(event) { \(propsString) }")
        #endif
        
        // In production, could batch send to first-party endpoint
        // For MVP, just log locally for privacy
    }
    
    /// Sanitize properties to remove PII
    private func sanitizeProperties(_ properties: [String: Any]) -> [String: Any] {
        var sanitized = properties
        
        // Remove any keys that might contain PII
        let piiKeys = ["email", "name", "phone", "address", "baby_name"]
        for key in piiKeys {
            sanitized.removeValue(forKey: key)
        }
        
        return sanitized
    }
    
    // MARK: - Funnel Tracking
    
    /// Onboarding funnel
    func trackOnboardingStarted() {
        track(event: "onboarding_started")
    }
    
    func trackOnboardingCompleted(durationSeconds: Int, stepsCompleted: Int) {
        track(event: "onboarding_completed", properties: [
            "duration_seconds": durationSeconds,
            "steps_completed": stepsCompleted
        ])
    }
    
    func trackOnboardingStepSkipped(stepId: String) {
        track(event: "onboarding_step_skipped", properties: [
            "step_id": stepId
        ])
    }
    
    func trackOnboardingDropoff(stepId: String, timeSpentSeconds: Int) {
        track(event: "onboarding_dropoff", properties: [
            "step_id": stepId,
            "time_spent_seconds": timeSpentSeconds
        ])
    }
    
    /// First log completion
    func trackFirstLog(timeFromOnboarding: Int) {
        track(event: "first_log_completed", properties: [
            "time_from_onboarding_seconds": timeFromOnboarding
        ])
    }
    
    /// 7-day retention
    func track7DayRetention() {
        track(event: "day_7_retention")
    }
    
    // MARK: - Navigation Events
    
    func trackScreenView(screenName: String) {
        track(event: "screen_view", properties: [
            "screen_name": screenName
        ])
    }
    
    func trackNavigation(fromScreen: String, toScreen: String, action: String) {
        track(event: "navigation", properties: [
            "from_screen": fromScreen,
            "to_screen": toScreen,
            "action": action
        ])
    }
    
    // MARK: - Core UX Metrics
    
    func trackTimeOnScreen(screenName: String, durationSeconds: Int) {
        track(event: "time_on_screen", properties: [
            "screen_name": screenName,
            "duration_seconds": durationSeconds
        ])
    }
    
    func trackPrimaryActionTaps(actionName: String, tapCount: Int) {
        track(event: "primary_action_taps", properties: [
            "action_name": actionName,
            "tap_count": tapCount
        ])
    }
    
    func trackUndoAction(actionType: String) {
        track(event: "undo_action", properties: [
            "action_type": actionType
        ])
    }
    
    // MARK: - AI Features
    
    func trackAIQuestionSent(questionLength: Int, usedContext: Bool) {
        track(event: "ai_question_sent", properties: [
            "question_length": questionLength,
            "used_context": usedContext
        ])
    }
    
    func trackAIAnswerShown(containsRedFlag: Bool) {
        track(event: "ai_answer_shown", properties: [
            "contains_red_flag_topic": containsRedFlag
        ])
    }
    
    func trackAIError(errorType: String) {
        track(event: "ai_error", properties: [
            "error_type": errorType
        ])
    }
    
    // MARK: - Cry Analysis
    
    func trackCryRecordStarted() {
        track(event: "cry_record_started")
    }
    
    func trackCryRecordCancelled() {
        track(event: "cry_record_cancelled")
    }
    
    func trackCryAnalysisCompleted(duration: Int, predictedLabel: String, confidenceBucket: String) {
        track(event: "cry_analysis_completed", properties: [
            "duration": duration,
            "predicted_label": predictedLabel,
            "confidence_bucket": confidenceBucket
        ])
    }
    
    func trackCryAnalysisFailed(errorType: String) {
        track(event: "cry_analysis_failed", properties: [
            "error_type": errorType
        ])
    }
    
    // MARK: - Nap Predictions
    
    func trackNapSuggestionShown(babyAgeWeeks: Int, hasRecentWake: Bool) {
        track(event: "nap_suggestion_shown", properties: [
            "baby_age_weeks": babyAgeWeeks,
            "has_recent_wake": hasRecentWake
        ])
    }
    
    func trackNapSuggestionAccepted() {
        track(event: "nap_suggestion_accepted")
    }
    
    func trackNapSuggestionIgnored() {
        track(event: "nap_suggestion_ignored")
    }
    
    // MARK: - Notifications
    
    func trackNotifTypeEnabled(notifType: String) {
        track(event: "notif_type_enabled", properties: [
            "notif_type": notifType
        ])
    }
    
    func trackNotifFired(notifType: String) {
        track(event: "notif_fired", properties: [
            "notif_type": notifType
        ])
    }
    
    func trackNotifTapOpened(notifType: String) {
        track(event: "notif_tap_opened", properties: [
            "notif_type": notifType
        ])
    }
    
    func trackNotifSnoozed(notifType: String) {
        track(event: "notif_snoozed", properties: [
            "notif_type": notifType
        ])
    }
    
    // MARK: - Caregiver Sharing
    
    func trackCaregiverInvited(invitedRole: String) {
        track(event: "caregiver_invited", properties: [
            "invited_role": invitedRole
        ])
    }
    
    func trackCaregiverJoined(role: String) {
        track(event: "caregiver_joined", properties: [
            "role": role
        ])
    }
    
    func trackCaregiverRevoked() {
        track(event: "caregiver_revoked")
    }
    
    func trackSharedLogCreated(role: String) {
        track(event: "shared_log_created", properties: [
            "role": role
        ])
    }
    
    // MARK: - Sync Events
    
    func trackSyncAttempt() {
        track(event: "sync_attempt")
    }
    
    func trackSyncSuccess() {
        track(event: "sync_success")
    }
    
    func trackSyncFailure(reason: String) {
        track(event: "sync_failure", properties: [
            "reason": reason
        ])
    }
    
    // MARK: - Timeline/History
    
    func trackTimelineViewed(dateOffsetFromToday: Int) {
        track(event: "timeline_viewed", properties: [
            "date_offset_from_today": dateOffsetFromToday
        ])
    }
    
    func trackTimelineEntryOpened(entryType: String) {
        track(event: "timeline_entry_opened", properties: [
            "entry_type": entryType
        ])
    }
    
    // MARK: - Home Dashboard
    
    func trackHomeViewed(hasActiveSleep: Bool, hasNapSuggestion: Bool, logsTodayCount: Int) {
        track(event: "home_viewed", properties: [
            "has_active_sleep": hasActiveSleep,
            "has_nap_suggestion": hasNapSuggestion,
            "logs_today_count": logsTodayCount
        ])
    }
    
    // MARK: - Accessibility
    
    func trackAccessibilityEnabled() {
        track(event: "accessibility_enabled")
    }
    
    func trackCaregiverModeEnabled(entryPoint: String) {
        track(event: "caregiver_mode_enabled", properties: [
            "entry_point": entryPoint
        ])
    }
    
    func trackCaregiverModeDisabled() {
        track(event: "caregiver_mode_disabled")
    }
    
    func trackVoiceOverSessionStarted() {
        track(event: "voiceover_session_started")
    }
    
    // MARK: - Delight Events
    
    func trackDelightEvent(type: String) {
        track(event: "delight_event_triggered", properties: [
            "type": type
        ])
    }
    
    // MARK: - Export
    
    func trackExportStarted(format: String, dateRangeLengthDays: Int) {
        track(event: "export_started", properties: [
            "format": format,
            "date_range_length_days": dateRangeLengthDays
        ])
    }
    
    func trackExportCompleted() {
        track(event: "export_completed")
    }
    
    func trackExportShared() {
        track(event: "export_shared")
    }
    
    // MARK: - Multiple Babies
    
    func trackBabyCreated(babyCountAfterAction: Int) {
        track(event: "baby_created", properties: [
            "baby_count_after_action": babyCountAfterAction
        ])
    }
    
    func trackBabySwitched() {
        track(event: "baby_switched")
    }
    
    func trackBabyDeleted(babyCountAfterAction: Int) {
        track(event: "baby_deleted", properties: [
            "baby_count_after_action": babyCountAfterAction
        ])
    }
    
    // MARK: - Subscription
    
    func trackSubscriptionPurchased(productId: String, price: String) {
        track(event: "subscription_purchased", properties: [
            "product_id": productId,
            "price": price
        ])
    }
    
    func trackSubscriptionRestored() {
        track(event: "subscription_restored")
    }
    
    func trackSubscriptionExpired() {
        track(event: "subscription_expired")
    }
    
    func trackUpgradePromptShown(feature: String, location: String) {
        track(event: "upgrade_prompt_shown", properties: [
            "feature": feature,
            "location": location
        ])
    }
    
    // MARK: - Analytics Aggregation
    
    /// Get event counts for key funnels (for dev dashboard)
    func getEventCounts() -> [String: Int] {
        var counts: [String: Int] = [:]
        
        for event in events {
            counts[event.name, default: 0] += 1
        }
        
        return counts
    }
    
    /// Get funnel conversion rates
    func getFunnelMetrics() -> FunnelMetrics {
        let onboardingStarted = events.filter { $0.name == "onboarding_started" }.count
        let onboardingCompleted = events.filter { $0.name == "onboarding_completed" }.count
        let firstLog = events.filter { $0.name == "first_log_completed" }.count
        let day7Retention = events.filter { $0.name == "day_7_retention" }.count
        
        return FunnelMetrics(
            onboardingStarted: onboardingStarted,
            onboardingCompleted: onboardingCompleted,
            onboardingCompletionRate: onboardingStarted > 0 ? Double(onboardingCompleted) / Double(onboardingStarted) : 0,
            firstLogCount: firstLog,
            firstLogRate: onboardingCompleted > 0 ? Double(firstLog) / Double(onboardingCompleted) : 0,
            day7RetentionCount: day7Retention,
            day7RetentionRate: firstLog > 0 ? Double(day7Retention) / Double(firstLog) : 0
        )
    }
}

/// Funnel metrics for key user journeys
struct FunnelMetrics {
    let onboardingStarted: Int
    let onboardingCompleted: Int
    let onboardingCompletionRate: Double
    let firstLogCount: Int
    let firstLogRate: Double
    let day7RetentionCount: Int
    let day7RetentionRate: Double
}

// MARK: - Analytics Wrapper

/// Analytics wrapper that provides a consistent API for tracking events
/// Uses AnalyticsService under the hood
actor Analytics {
    static let shared = Analytics()
    
    private init() {}
    
    /// Log a generic event with parameters
    func log(_ event: String, parameters: [String: Any]? = nil) async {
        AnalyticsService.shared.track(event: event, properties: parameters ?? [:])
    }
    
    // MARK: - Subscription Analytics
    
    func logSubscriptionTrialStarted(plan: String, source: String) async {
        AnalyticsService.shared.track(event: "subscription_trial_started", properties: [
            "plan": plan,
            "source": source
        ])
    }
    
    func logSubscriptionRenewed(plan: String) async {
        AnalyticsService.shared.track(event: "subscription_renewed", properties: [
            "plan": plan
        ])
    }
    
    func logSubscriptionActivated(plan: String, price: String) async {
        AnalyticsService.shared.track(event: "subscription_activated", properties: [
            "plan": plan,
            "price": price
        ])
    }
    
    func logSubscriptionCancelled(plan: String, reason: String?) async {
        var properties: [String: Any] = ["plan": plan]
        if let reason = reason {
            properties["reason"] = reason
        }
        AnalyticsService.shared.track(event: "subscription_cancelled", properties: properties)
    }
    
    func logSubscriptionPurchased(plan: String, price: String) async {
        AnalyticsService.shared.track(event: "subscription_purchased", properties: [
            "plan": plan,
            "price": price
        ])
    }
    
    // MARK: - Onboarding Analytics
    
    func logOnboardingStepViewed(step: String) async {
        AnalyticsService.shared.track(event: "onboarding_step_viewed", properties: [
            "step": step
        ])
    }
    
    func logOnboardingStepSkipped(step: String) async {
        AnalyticsService.shared.track(event: "onboarding_step_skipped", properties: [
            "step": step
        ])
    }
    
    func logOnboardingGoalSelected(goal: String) async {
        AnalyticsService.shared.track(event: "onboarding_goal_selected", properties: [
            "goal": goal
        ])
    }
    
    func logOnboardingCompleted(babyId: String) async {
        AnalyticsService.shared.track(event: "onboarding_completed", properties: [
            "baby_id": babyId
        ])
    }
    
    // MARK: - Paywall Analytics
    
    func logPaywallViewed(source: String) async {
        AnalyticsService.shared.track(event: "paywall_viewed", properties: [
            "source": source
        ])
    }
    
    // MARK: - Prediction Analytics
    
    func logPredictionShown(type: String, isPro: Bool, babyId: String) async {
        AnalyticsService.shared.track(event: "prediction_shown", properties: [
            "type": type,
            "is_pro": isPro,
            "baby_id": babyId
        ])
    }
    
    // MARK: - First Log Analytics
    
    func logFirstLogCreated(eventType: String, babyId: String) async {
        AnalyticsService.shared.track(event: "first_log_created", properties: [
            "event_type": eventType,
            "baby_id": babyId
        ])
    }
    
    func logOnboardingStarted() async {
        AnalyticsService.shared.trackOnboardingStarted()
    }
    
}
