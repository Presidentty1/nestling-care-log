import Foundation

/// Feature flags for controlled rollout of new UX enhancements
/// Allows gradual rollout and A/B testing of major features
///
/// Usage:
/// ```swift
/// if PolishFeatureFlags.shared.shareCardsEnabled {
///     // Show share buttons on celebrations
/// }
/// ```
class PolishFeatureFlags {
    static let shared = PolishFeatureFlags()

    private let userDefaults = UserDefaults.standard

    // MARK: - Viral Growth Features

    /// Enable shareable milestone cards on celebrations
    var shareCardsEnabled: Bool {
        get { userDefaults.bool(forKey: #function) }
        set { userDefaults.set(newValue, forKey: #function) }
    }

    /// Enable referral program with attribution tracking
    var referralsV1Enabled: Bool {
        get { userDefaults.bool(forKey: #function) }
        set { userDefaults.set(newValue, forKey: #function) }
    }

    /// Enable OMG moment detection and enhanced celebrations
    var omgMomentsEnabled: Bool {
        get { userDefaults.bool(forKey: #function) }
        set { userDefaults.set(newValue, forKey: #function) }
    }

    /// Enable mom group one-tap sharing
    var momGroupShareEnabled: Bool {
        get { userDefaults.bool(forKey: #function) }
        set { userDefaults.set(newValue, forKey: #function) }
    }

    /// Enable widget onboarding prompts
    var widgetOnboardingEnabled: Bool {
        get { userDefaults.bool(forKey: #function) }
        set { userDefaults.set(newValue, forKey: #function) }
    }

    // MARK: - Trust & Education Features

    /// Enable AAP citations on predictions and cards
    var citationsEnabled: Bool {
        get { userDefaults.bool(forKey: #function) }
        set { userDefaults.set(newValue, forKey: #function) }
    }

    /// Enable educational tooltips explaining tracking benefits
    var educationalTooltipsEnabled: Bool {
        get { userDefaults.bool(forKey: #function) }
        set { userDefaults.set(newValue, forKey: #function) }
    }

    /// Enable structured first 72 hours journey
    var first72hJourneyEnabled: Bool {
        get { userDefaults.bool(forKey: #function) }
        set { userDefaults.set(newValue, forKey: #function) }
    }

    /// Enable reassurance system for difficult patterns
    var reassuranceSystemEnabled: Bool {
        get { userDefaults.bool(forKey: #function) }
        set { userDefaults.set(newValue, forKey: #function) }
    }

    /// Enable churn prevention detection and interventions
    var churnPreventionEnabled: Bool {
        get { userDefaults.bool(forKey: #function) }
        set { userDefaults.set(newValue, forKey: #function) }
    }

    /// Enable trial extension triggers
    var trialExtensionEnabled: Bool {
        get { userDefaults.bool(forKey: #function) }
        set { userDefaults.set(newValue, forKey: #function) }
    }

    /// Enable weeks 2-4 retention bridge system
    var retentionBridgeEnabled: Bool {
        get { userDefaults.bool(forKey: #function) }
        set { userDefaults.set(newValue, forKey: #function) }
    }

    // MARK: - Cognitive Load Features

    /// Enable predictive single-tap logging
    var predictiveLoggingEnabled: Bool {
        get { userDefaults.bool(forKey: #function) }
        set { userDefaults.set(newValue, forKey: #function) }
    }

    /// Enable skeleton loading screens
    var skeletonLoadingEnabled: Bool {
        get { userDefaults.bool(forKey: #function) }
        set { userDefaults.set(newValue, forKey: #function) }
    }

    /// Enable voice-first mode enhancements
    var voiceFirstEnabled: Bool {
        get { userDefaults.bool(forKey: #function) }
        set { userDefaults.set(newValue, forKey: #function) }
    }

    /// Enable smart notification timing
    var smartNotificationsEnabled: Bool {
        get { userDefaults.bool(forKey: #function) }
        set { userDefaults.set(newValue, forKey: #function) }
    }

    /// Enable proactive feature discovery
    var proactiveDiscoveryEnabled: Bool {
        get { userDefaults.bool(forKey: #function) }
        set { userDefaults.set(newValue, forKey: #function) }
    }

    /// Enable data export and portability features
    var dataExportEnabled: Bool {
        get { userDefaults.bool(forKey: #function) }
        set { userDefaults.set(newValue, forKey: #function) }
    }

    /// Enable streak freeze/protection mechanics
    var streakProtectionEnabled: Bool {
        get { userDefaults.bool(forKey: #function) }
        set { userDefaults.set(newValue, forKey: #function) }
    }

    // MARK: - Initialization & Defaults

    private init() {
        // Set development defaults (enable most features for testing)
        #if DEBUG
        setDevelopmentDefaults()
        #else
        setProductionDefaults()
        #endif
    }

    /// Development defaults - enable most features for testing
    private func setDevelopmentDefaults() {
        shareCardsEnabled = true
        referralsV1Enabled = true
        omgMomentsEnabled = true
        momGroupShareEnabled = true
        widgetOnboardingEnabled = true
        citationsEnabled = true
        educationalTooltipsEnabled = true
        first72hJourneyEnabled = true
        reassuranceSystemEnabled = true
        churnPreventionEnabled = true
        trialExtensionEnabled = true
        retentionBridgeEnabled = true
        predictiveLoggingEnabled = true
        skeletonLoadingEnabled = true
        voiceFirstEnabled = true
        smartNotificationsEnabled = true
        proactiveDiscoveryEnabled = true
        dataExportEnabled = true
        streakProtectionEnabled = true
    }

    /// Production defaults - conservative rollout
    private func setProductionDefaults() {
        // Start with core viral features enabled
        shareCardsEnabled = true
        referralsV1Enabled = true
        omgMomentsEnabled = true
        momGroupShareEnabled = true

        // Trust features enabled
        citationsEnabled = true
        educationalTooltipsEnabled = true

        // Safety features enabled
        reassuranceSystemEnabled = true

        // Performance features enabled
        skeletonLoadingEnabled = true

        // New features disabled by default for gradual rollout
        widgetOnboardingEnabled = false
        first72hJourneyEnabled = false
        churnPreventionEnabled = false
        trialExtensionEnabled = false
        retentionBridgeEnabled = false
        predictiveLoggingEnabled = false
        voiceFirstEnabled = false
        smartNotificationsEnabled = false
        proactiveDiscoveryEnabled = false
        dataExportEnabled = false
        streakProtectionEnabled = false
    }

    // MARK: - Remote Configuration Support

    /// Update flags from remote configuration (for gradual rollout)
    func updateFromRemoteConfig(_ config: [String: Bool]) {
        for (key, value) in config {
            switch key {
            case "shareCardsEnabled": shareCardsEnabled = value
            case "referralsV1Enabled": referralsV1Enabled = value
            case "omgMomentsEnabled": omgMomentsEnabled = value
            case "momGroupShareEnabled": momGroupShareEnabled = value
            case "widgetOnboardingEnabled": widgetOnboardingEnabled = value
            case "citationsEnabled": citationsEnabled = value
            case "educationalTooltipsEnabled": educationalTooltipsEnabled = value
            case "first72hJourneyEnabled": first72hJourneyEnabled = value
            case "reassuranceSystemEnabled": reassuranceSystemEnabled = value
            case "churnPreventionEnabled": churnPreventionEnabled = value
            case "trialExtensionEnabled": trialExtensionEnabled = value
            case "retentionBridgeEnabled": retentionBridgeEnabled = value
            case "predictiveLoggingEnabled": predictiveLoggingEnabled = value
            case "skeletonLoadingEnabled": skeletonLoadingEnabled = value
            case "voiceFirstEnabled": voiceFirstEnabled = value
            case "smartNotificationsEnabled": smartNotificationsEnabled = value
            case "proactiveDiscoveryEnabled": proactiveDiscoveryEnabled = value
            case "dataExportEnabled": dataExportEnabled = value
            case "streakProtectionEnabled": streakProtectionEnabled = value
            default: break
            }
        }
    }

    // MARK: - Analytics Integration

    /// Track feature flag state changes for analytics
    func trackFlagChange(flagName: String, newValue: Bool) {
        // This would integrate with your analytics system
        // AnalyticsService.shared.track(event: "feature_flag_changed",
        //                              properties: ["flag": flagName, "enabled": newValue])
    }

    // MARK: - Debug Support

    /// Get all flag states for debugging
    var debugAllFlags: [String: Bool] {
        [
            "shareCardsEnabled": shareCardsEnabled,
            "referralsV1Enabled": referralsV1Enabled,
            "omgMomentsEnabled": omgMomentsEnabled,
            "momGroupShareEnabled": momGroupShareEnabled,
            "widgetOnboardingEnabled": widgetOnboardingEnabled,
            "citationsEnabled": citationsEnabled,
            "educationalTooltipsEnabled": educationalTooltipsEnabled,
            "first72hJourneyEnabled": first72hJourneyEnabled,
            "reassuranceSystemEnabled": reassuranceSystemEnabled,
            "churnPreventionEnabled": churnPreventionEnabled,
            "trialExtensionEnabled": trialExtensionEnabled,
            "retentionBridgeEnabled": retentionBridgeEnabled,
            "predictiveLoggingEnabled": predictiveLoggingEnabled,
            "skeletonLoadingEnabled": skeletonLoadingEnabled,
            "voiceFirstEnabled": voiceFirstEnabled,
            "smartNotificationsEnabled": smartNotificationsEnabled,
            "proactiveDiscoveryEnabled": proactiveDiscoveryEnabled,
            "dataExportEnabled": dataExportEnabled,
            "streakProtectionEnabled": streakProtectionEnabled
        ]
    }
}
