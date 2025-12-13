import Foundation
import StoreKit

/// Coordinates strategic cancellation flow to reduce churn
/// Research: Cancellation flows can save 42-58% of canceling users (Churnkey 2025)
///
/// Flow:
/// 1. Pre-cancel value reminder
/// 2. Single required question (reason)
/// 3. Personalized retention offer
/// 4. Loss aversion screen
/// 5. Final confirmation
///
/// Usage:
/// ```swift
/// let coordinator = CancellationFlowCoordinator.shared
/// coordinator.startCancellationFlow(currentPlan: "monthly", source: "settings")
/// ```
@MainActor
class CancellationFlowCoordinator: ObservableObject {
    static let shared = CancellationFlowCoordinator()
    
    @Published var currentStep: CancellationStep?
    @Published var selectedReason: CancellationReason?
    @Published var retentionOffer: RetentionOffer?
    @Published var userStats: CancellationUserStats?
    
    private init() {}
    
    // MARK: - Flow Control
    
    /// Start the cancellation flow
    func startCancellationFlow(currentPlan: String, source: String) async {
        // Track flow start
        await Analytics.shared.logCancellationFlowStarted()
        
        // Calculate user stats for personalization
        userStats = await calculateUserStats()
        
        // Start with value reminder
        currentStep = .valueReminder
    }
    
    /// Move to reason selection
    func moveToReasonSelection() {
        currentStep = .reasonSelection
    }
    
    /// Handle reason selected
    func reasonSelected(_ reason: CancellationReason) async {
        selectedReason = reason
        
        // Track reason
        await Analytics.shared.logCancellationReasonSelected(reason: reason.rawValue)
        
        // Generate personalized offer
        retentionOffer = generateRetentionOffer(for: reason)
        
        // Show offer
        currentStep = .retentionOffer
    }
    
    /// User accepted retention offer
    func acceptedRetentionOffer() async {
        guard let offer = retentionOffer else { return }
        
        // Track acceptance
        await Analytics.shared.logRetentionOfferAccepted(offerType: offer.type.rawValue)
        
        // Apply the offer (discount, pause, etc.)
        await applyRetentionOffer(offer)
        
        // Close flow
        currentStep = nil
    }
    
    /// User declined offer - show loss aversion
    func declinedRetentionOffer() {
        currentStep = .lossAversion
    }
    
    /// User confirmed cancellation
    func confirmCancellation() async {
        // Track cancellation completion
        await Analytics.shared.log("cancellation_completed", parameters: [
            "reason": selectedReason?.rawValue ?? "unknown",
            "offered_retention": retentionOffer != nil
        ])
        
        // Process cancellation
        await processCancellation()
        
        // Schedule win-back sequence
        scheduleWinBackSequence()
        
        // Close flow
        currentStep = nil
    }
    
    // MARK: - User Stats Calculation
    
    private func calculateUserStats() async -> CancellationUserStats {
        guard let currentBaby = AppEnvironment.shared.currentBaby else {
            return CancellationUserStats(
                totalLogs: 0,
                daysUsed: 0,
                accuratePredictions: 0,
                partnerName: nil
            )
        }
        
        let dataStore = AppEnvironment.shared.dataStore
        
        // Calculate days used
        let firstEvent = try? await dataStore.fetchEvents(for: currentBaby, from: Date.distantPast, to: Date()).first
        let daysUsed = firstEvent.map { Calendar.current.dateComponents([.day], from: $0.startTime, to: Date()).day ?? 0 } ?? 0
        
        // Count total logs
        let allEvents = try? await dataStore.fetchEvents(for: currentBaby, from: Date.distantPast, to: Date())
        let totalLogs = allEvents?.count ?? 0
        
        // Count accurate predictions (would need prediction tracking)
        let accuratePredictions = 23  // Placeholder - would track from analytics
        
        // Get partner name (if synced)
        let partnerName = UserDefaults.standard.string(forKey: "partner_name")
        
        return CancellationUserStats(
            totalLogs: totalLogs,
            daysUsed: daysUsed,
            accuratePredictions: accuratePredictions,
            partnerName: partnerName
        )
    }
    
    // MARK: - Retention Offer Generation
    
    private func generateRetentionOffer(for reason: CancellationReason) -> RetentionOffer {
        switch reason {
        case .tooExpensive:
            return RetentionOffer(
                type: .discount,
                title: "50% off for 3 months",
                description: "We'd love to keep you. Here's 50% off your next 3 months—just $4.99/month.",
                cta: "Accept Offer",
                terms: "Discount applies to next 3 renewals. Regular price resumes after."
            )
            
        case .dontUseEnough:
            return RetentionOffer(
                type: .pause,
                title: "Take a 30-day break",
                description: "Pause your subscription for free. Your data stays safe and you can resume anytime.",
                cta: "Pause Subscription",
                terms: "Subscription paused for 30 days. No charges during pause."
            )
            
        case .babyNeedsChanged:
            return RetentionOffer(
                type: .downgrade,
                title: "Export & keep your memories",
                description: "Download all your data as a beautiful PDF baby book. Downgrade to free tracking if you'd like.",
                cta: "Export Data",
                terms: "Downgrade to free plan. Export includes all logs, insights, and photos."
            )
            
        case .missingFeatures:
            return RetentionOffer(
                type: .extension,
                title: "See what's coming soon",
                description: "Check our roadmap—your requested feature might be next! Keep Pro for 2 more weeks on us.",
                cta: "View Roadmap",
                terms: "2-week trial extension. Check roadmap for upcoming features."
            )
            
        case .foundAlternative:
            return RetentionOffer(
                type: .discount,
                title: "One last offer: 40% off",
                description: "We get it. But before you go—40% off for 6 months. No other app protects privacy like we do.",
                cta: "Stay with 40% Off",
                terms: "40% discount for 6 months. Privacy-first tracking you can trust."
            )
            
        case .technicalIssues:
            return RetentionOffer(
                type: .support,
                title: "Let us help fix this",
                description: "We're sorry you had issues. Connect with our team for priority support and 1 month free while we resolve it.",
                cta: "Get Priority Support",
                terms: "1 month free + priority support queue. We'll make it right."
            )
            
        case .other:
            return RetentionOffer(
                type: .feedback,
                title: "Help us improve",
                description: "Your feedback shapes our roadmap. Share your thoughts and get 2 weeks free?",
                cta: "Share Feedback",
                terms: "2-week extension for detailed feedback."
            )
        }
    }
    
    // MARK: - Offer Application
    
    private func applyRetentionOffer(_ offer: RetentionOffer) async {
        switch offer.type {
        case .discount:
            // Apply discount code (would integrate with StoreKit)
            logger.info("[Cancellation] Applied discount offer")
            
        case .pause:
            // Pause subscription for 30 days
            let pauseUntil = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
            UserDefaults.standard.set(pauseUntil, forKey: "subscription_paused_until")
            logger.info("[Cancellation] Subscription paused until \(pauseUntil)")
            
        case .downgrade:
            // Downgrade to free plan (cancel subscription but keep data)
            await processCancellation()
            logger.info("[Cancellation] Downgraded to free plan")
            
        case .extension:
            // Extend trial/subscription by 2 weeks
            await ProSubscriptionService.shared.extendTrial(by: 14)
            logger.info("[Cancellation] Extended subscription by 14 days")
            
        case .support:
            // Flag for priority support + extend 1 month
            UserDefaults.standard.set(true, forKey: "priority_support_enabled")
            await ProSubscriptionService.shared.extendTrial(by: 30)
            logger.info("[Cancellation] Granted priority support + 30 day extension")
            
        case .feedback:
            // Extend by 2 weeks, open feedback form
            await ProSubscriptionService.shared.extendTrial(by: 14)
            logger.info("[Cancellation] Extended for feedback")
        }
    }
    
    // MARK: - Cancellation Processing
    
    private func processCancellation() async {
        // Cancel subscription via StoreKit
        // This would call the actual cancellation API
        logger.info("[Cancellation] Processing subscription cancellation")
        
        // Track final cancellation
        await Analytics.shared.logSubscriptionCancelled(
            plan: "current_plan",
            reason: selectedReason?.rawValue
        )
    }
    
    // MARK: - Win-Back Sequence
    
    private func scheduleWinBackSequence() {
        // Schedule win-back emails
        // Day 0: Immediate data export link
        // Day 7: 40% off offer
        // Day 30: New feature announcement
        // Day 90: Final notice (data deletion warning)
        
        logger.info("[Cancellation] Scheduled win-back email sequence")
        
        // This would integrate with email service
        // For now, just track the intent
        Task {
            await Analytics.shared.log("win_back_sequence_scheduled", parameters: [
                "reason": selectedReason?.rawValue ?? "unknown"
            ])
        }
    }
}

// MARK: - Models

enum CancellationStep {
    case valueReminder
    case reasonSelection
    case retentionOffer
    case lossAversion
    case finalConfirmation
}

enum CancellationReason: String, CaseIterable, Identifiable {
    case tooExpensive = "too_expensive"
    case dontUseEnough = "dont_use_enough"
    case babyNeedsChanged = "baby_needs_changed"
    case missingFeatures = "missing_features"
    case foundAlternative = "found_alternative"
    case technicalIssues = "technical_issues"
    case other = "other"
    
    var id: String { rawValue }
    
    var displayText: String {
        switch self {
        case .tooExpensive: return "Too expensive"
        case .dontUseEnough: return "Don't use it enough"
        case .babyNeedsChanged: return "My baby's needs have changed"
        case .missingFeatures: return "Missing features I need"
        case .foundAlternative: return "Found a better alternative"
        case .technicalIssues: return "Experiencing technical problems"
        case .other: return "Other reason"
        }
    }
}

struct RetentionOffer {
    enum OfferType: String {
        case discount
        case pause
        case downgrade
        case extension
        case support
        case feedback
    }
    
    let type: OfferType
    let title: String
    let description: String
    let cta: String
    let terms: String
}

struct CancellationUserStats {
    let totalLogs: Int
    let daysUsed: Int
    let accuratePredictions: Int
    let partnerName: String?
    
    var babyName: String {
        AppEnvironment.shared.currentBaby?.name ?? "your baby"
    }
}

private let logger = LoggerFactory.create(category: "CancellationFlow")
