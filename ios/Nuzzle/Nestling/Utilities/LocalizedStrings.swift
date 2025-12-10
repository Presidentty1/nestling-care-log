import Foundation

/// Localized strings with supportive, non-judgmental language
/// Voice guide: calm, direct, warm, never blame/guilt
struct LocalizedStrings {
    // MARK: - Onboarding
    
    static let onboardingWelcomeTitle = "Welcome to Nuzzle"
    static let onboardingWelcomeMessage = "Track feeds, sleep, and diapers with ease. Get AI-powered insights to support you."
    
    static let onboardingBabySetupTitle = "Tell us about your baby"
    static let onboardingBabySetupMessage = "We'll use this to personalize predictions and insights"
    
    static let onboardingPreferencesTitle = "Customize your experience"
    static let onboardingPreferencesMessage = "Choose what works best for you and your family"
    
    static let onboardingReadyTitle = "You're all set!"
    static let onboardingReadyMessage = "Let's log your first event to get started"
    
    // MARK: - Empty States
    
    static let noEventsTitle = "No events logged yet"
    static let noEventsMessage = "Tap + to log your first feed, sleep, or diaper change"
    
    static let noFeedsTitle = "No feeds logged yet"
    static let noFeedsMessage = "Start logging feeds to see patterns and predictions"
    
    static let noSleepsTitle = "No naps logged yet"
    static let noSleepsMessage = "Start your first nap when baby falls asleep"
    
    static let noDiapersTitle = "No diapers logged yet"
    static let noDiapersMessage = "Log diaper changes to track daily patterns"
    
    static let noHistoryTitle = "Nothing logged this day"
    static let noHistoryMessage = "Babies have calm days too! It's perfectly normal to have quiet stretches."
    
    // MARK: - Notifications (Non-judgmental)
    
    static func feedReminderBody(hours: Int) -> String {
        "It's been about \(hours) hours since the last feed"
    }
    
    static let napWindowBody = "Nap window is starting soon based on your baby's age and patterns"
    
    static func diaperReminderBody(hours: Int) -> String {
        "It's been about \(hours) hours since the last diaper change"
    }
    
    // MARK: - Time Language (Neutral, no guilt)
    
    static func timeSince(hours: Int) -> String {
        "About \(hours) hours ago"
    }
    
    static func timeSince(minutes: Int) -> String {
        if minutes < 60 {
            return "About \(minutes) minutes ago"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "About \(hours) hours ago"
            } else {
                return "About \(hours)h \(remainingMinutes)m ago"
            }
        }
    }
    
    // MARK: - Predictions (Probabilistic language)
    
    static let napSuggestionPrefix = "Your baby may be ready for a nap"
    static let napSuggestionNote = "These suggestions are based on age and patterns, not medical advice"
    
    static let feedSuggestionPrefix = "Your baby might be getting hungry"
    static let feedSuggestionNote = "Based on typical feeding patterns for this age"
    
    // MARK: - AI Assistant
    
    static let aiDisclaimerShort = "General guidance only; not a replacement for your pediatrician"
    static let aiDisclaimerFull = "This is AI-powered guidance only, not medical advice. Contact your pediatrician if you have concerns about your baby's health."
    
    static let aiOfflineMessage = "AI Assistant requires an internet connection"
    static let aiThinkingMessage = "Thinking..."
    
    // MARK: - Cry Analysis
    
    static let cryAnalysisBetaDisclaimer = "Cry analysis is in beta and may be inaccurate. Always trust your instincts and consult a doctor if concerned."
    static let cryAnalysisOffline = "Analysis requires internet. You can manually label the cry or try again when online."
    
    // MARK: - Errors (Supportive, not scary)
    
    static let errorGenericTitle = "Something went wrong"
    static let errorGenericMessage = "We couldn't complete that action. Check your connection and try again?"
    
    static let errorNetworkTitle = "Connection issue"
    static let errorNetworkMessage = "Check your internet connection and try again"
    
    static let errorSyncTitle = "Sync paused"
    static let errorSyncMessage = "Your changes are saved locally and will sync when connection is restored"
    
    // MARK: - Privacy
    
    static let privacyExplanationTitle = "Your data stays private"
    static let privacyExplanationMessage = "All your data is stored on your device. iCloud sync only happens when you invite a caregiver. We never sell your data or use third-party tracking."
    
    static let analyticsOptOutMessage = "We collect minimal, privacy-respecting analytics to improve the app. No personal information is tracked. You can turn this off at any time."
    
    // MARK: - Confirmations
    
    static func deleteEventConfirmation(eventType: String) -> String {
        "Are you sure you want to delete this \(eventType.lowercased())? This action cannot be undone."
    }
    
    static func deleteBabyConfirmation(babyName: String) -> String {
        "This will permanently delete all data for \(babyName), including all logged events. This action cannot be undone."
    }
    
    static let deleteAllDataConfirmation = "This will permanently delete ALL baby profiles, events, and settings from this device. Your iCloud data (if synced) will remain until deleted separately."
    
    static func revokeCaregiverConfirmation(caregiverName: String) -> String {
        "\(caregiverName) will no longer be able to view or edit data. Their existing local data will remain on their device but will stop syncing."
    }
    
    // MARK: - Success Messages
    
    static let eventSavedMessage = "Saved!"
    static let eventUpdatedMessage = "Updated!"
    static let eventDeletedMessage = "Removed"
    
    // MARK: - Caregiver Sharing
    
    static let inviteCaregiverExplanation = "When you invite a caregiver, they will be able to view and log events. All data syncs automatically via iCloud."
    
    static let acceptInviteExplanation = "You're about to join a shared family. You'll be able to view and log events for the baby."
    
    static let caregiverWelcomeTitle = "Welcome to shared care"
    static let caregiverWelcomeMessage = "You can now view and log events for this baby. All changes sync automatically across devices."
}

/// Style guide for copy
enum CopyStyleGuide {
    // MARK: - Voice Guidelines
    
    /// Single voice: calm, direct, warm
    /// - Calm: No urgency or pressure
    /// - Direct: Clear, concise, actionable
    /// - Warm: Supportive, encouraging
    
    /// Examples of GOOD copy:
    /// - "It's been about 3 hours since the last feed"
    /// - "Your baby may be ready for a nap soon"
    /// - "Start your first nap when baby falls asleep"
    
    /// Examples of BAD copy:
    /// - "You missed a feed!" (judgmental)
    /// - "Baby is definitely hungry" (too certain)
    /// - "You're late for a nap" (guilt-inducing)
    
    // MARK: - Time Language
    
    /// Avoid: "late", "missed", "behind", "overdue"
    /// Use: "about", "around", "roughly", "approximately"
    
    // MARK: - Suggestions vs Commands
    
    /// Avoid: "You must feed now", "Put baby to sleep"
    /// Use: "Your baby may be ready for...", "Consider trying..."
    
    // MARK: - Localization
    
    /// Use String.localizedStringWithFormat for numbers
    /// Avoid concatenation that breaks grammar
    /// Mark all placeholders clearly
}
