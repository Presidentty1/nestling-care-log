import Foundation
import OSLog

/// Help center service for in-app self-service support
/// Research: 81% try self-service first; good knowledge base deflects 20-50% of tickets
///
/// Goal: Keep contact rate <5% of monthly active users
///
/// Usage:
/// ```swift
/// let articles = HelpCenterService.shared.searchArticles(query: "sync")
/// let article = HelpCenterService.shared.getArticle(id: "how-to-log-feed")
/// ```
@MainActor
class HelpCenterService: ObservableObject {
    static let shared = HelpCenterService()
    
    @Published var articles: [HelpArticle] = []
    @Published var recentlyViewed: [HelpArticle] = []
    @Published var searchResults: [HelpArticle] = []
    
    private init() {
        loadArticles()
    }
    
    // MARK: - Article Management
    
    func getArticle(id: String) -> HelpArticle? {
        articles.first { $0.id == id }
    }
    
    func searchArticles(query: String) -> [HelpArticle] {
        guard !query.isEmpty else { return [] }
        
        let lowercasedQuery = query.lowercased()
        return articles.filter { article in
            article.title.lowercased().contains(lowercasedQuery) ||
            article.content.lowercased().contains(lowercasedQuery) ||
            article.searchKeywords.contains(where: { $0.lowercased().contains(lowercasedQuery) })
        }
    }
    
    func getArticlesByCategory(_ category: HelpCategory) -> [HelpArticle] {
        articles.filter { $0.category == category }
    }
    
    func trackArticleView(_ article: HelpArticle) {
        // Track view for analytics
        Task {
            await Analytics.shared.log("help_article_viewed", parameters: [
                "article_id": article.id,
                "article_title": article.title,
                "category": article.category.rawValue
            ])
        }
        
        // Add to recently viewed
        if !recentlyViewed.contains(where: { $0.id == article.id }) {
            recentlyViewed.insert(article, at: 0)
            if recentlyViewed.count > 5 {
                recentlyViewed = Array(recentlyViewed.prefix(5))
            }
        }
    }
    
    func trackArticleHelpful(_ article: HelpArticle, wasHelpful: Bool) {
        Task {
            await Analytics.shared.log("help_article_feedback", parameters: [
                "article_id": article.id,
                "was_helpful": wasHelpful
            ])
        }
    }
    
    // MARK: - Contextual Help
    
    /// Get contextual help for a specific screen or scenario
    func getContextualHelp(for context: HelpContext) -> HelpArticle? {
        switch context {
        case .feedForm:
            return getArticle(id: "how-to-log-feed")
        case .sleepForm:
            return getArticle(id: "how-to-log-sleep")
        case .diaperForm:
            return getArticle(id: "how-to-log-diaper")
        case .predictions:
            return getArticle(id: "how-predictions-work")
        case .partnerSync:
            return getArticle(id: "how-to-invite-partner")
        case .subscription:
            return getArticle(id: "how-to-cancel-subscription")
        case .dataExport:
            return getArticle(id: "how-to-export-data")
        }
    }
    
    // MARK: - Article Loading
    
    private func loadArticles() {
        articles = createDefaultArticles()
    }
    
    private func createDefaultArticles() -> [HelpArticle] {
        return [
            // Top 10 articles per plan
            
            // 1. How do I log a feed?
            HelpArticle(
                id: "how-to-log-feed",
                title: "How do I log a feed?",
                content: """
                Logging a feed is easy:
                
                1. Tap the "Feed" button on the Home screen
                2. Enter the amount (if bottle)
                3. Select the time (defaults to now)
                4. Tap "Save"
                
                That's it! The feed is logged and syncs automatically.
                
                Pro tip: You can also log from the timeline by tapping the + button.
                """,
                category: .logging,
                searchKeywords: ["log", "feed", "bottle", "breast", "nursing", "feeding"],
                videoUrl: nil,
                relatedArticles: ["how-to-log-sleep", "how-predictions-work"]
            ),
            
            // 2. How do nap predictions work?
            HelpArticle(
                id: "how-predictions-work",
                title: "How do nap predictions work?",
                content: """
                Nuzzle's AI analyzes three key factors:
                
                1. Your baby's age (wake windows change as babies grow)
                2. Last wake time (how long baby has been awake)
                3. Recent sleep patterns (your baby's unique rhythms)
                
                The confidence score shows how certain we are:
                • 80%+ = High confidence (typical patterns)
                • 60-80% = Medium confidence (patterns emerging)
                • <60% = Low confidence (need more data)
                
                Predictions improve as you track more!
                """,
                category: .predictions,
                searchKeywords: ["prediction", "nap", "window", "AI", "confidence", "accuracy"],
                videoUrl: nil,
                relatedArticles: ["why-prediction-wrong", "how-to-improve-accuracy"]
            ),
            
            // 3. How do I invite my partner?
            HelpArticle(
                id: "how-to-invite-partner",
                title: "How do I invite my partner?",
                content: """
                Share tracking with your co-parent:
                
                1. Go to Settings
                2. Tap "Partner & Caregivers"
                3. Tap "Invite Partner"
                4. Enter their email or phone
                5. They'll receive an invitation link
                
                Once accepted, all logs sync in real-time!
                
                Your data is encrypted and only visible to people you invite.
                """,
                category: .partnerSync,
                searchKeywords: ["partner", "invite", "sync", "share", "caregiver", "family"],
                videoUrl: nil,
                relatedArticles: ["sync-troubleshooting", "privacy-security"]
            ),
            
            // 4. Why isn't my data syncing?
            HelpArticle(
                id: "sync-troubleshooting",
                title: "Why isn't my data syncing?",
                content: """
                If data isn't syncing with your partner:
                
                1. Check internet connection
                2. Verify both users are signed in to iCloud
                3. Ensure CloudKit sync is enabled (Settings → iCloud)
                4. Check that partner accepted the invitation
                
                Note: Syncs happen in seconds, but if you're offline, they'll catch up when reconnected.
                
                Your data is always safe locally even if sync is delayed.
                """,
                category: .troubleshooting,
                searchKeywords: ["sync", "not working", "partner", "icloud", "offline"],
                videoUrl: nil,
                relatedArticles: ["how-to-invite-partner", "offline-mode"]
            ),
            
            // 5. How do I cancel my subscription?
            HelpArticle(
                id: "how-to-cancel-subscription",
                title: "How do I cancel my subscription?",
                content: """
                To cancel your Nuzzle Pro subscription:
                
                1. Go to Settings
                2. Tap "Subscription"
                3. Tap "Cancel Subscription"
                4. Follow the prompts
                
                You'll keep Pro features until the end of your billing period.
                
                After canceling, you can still use free tracking features.
                
                Want to export your data first? Go to Settings → Data & Privacy → Export Data.
                """,
                category: .subscription,
                searchKeywords: ["cancel", "subscription", "stop", "refund", "unsubscribe"],
                videoUrl: nil,
                relatedArticles: ["how-to-export-data", "subscription-plans"]
            ),
            
            // 6. What does the prediction confidence mean?
            HelpArticle(
                id: "prediction-confidence-explained",
                title: "What does the prediction confidence mean?",
                content: """
                The confidence score tells you how reliable a prediction is:
                
                **High (80%+)**
                Your baby has consistent patterns. Prediction is very likely accurate.
                
                **Medium (60-80%)**
                Patterns are emerging but still variable. Prediction is a good guide.
                
                **Low (<60%)**
                Still learning your baby's rhythms. Prediction is a rough estimate.
                
                Confidence improves as you track more days!
                """,
                category: .predictions,
                searchKeywords: ["confidence", "accuracy", "prediction", "percentage", "reliable"],
                videoUrl: nil,
                relatedArticles: ["how-predictions-work", "why-prediction-wrong"]
            ),
            
            // 7. How do I export my data?
            HelpArticle(
                id: "how-to-export-data",
                title: "How do I export my data?",
                content: """
                Export all your tracking data:
                
                1. Go to Settings
                2. Tap "Data & Privacy"
                3. Tap "Export Data"
                4. Choose format (JSON or PDF)
                5. Share or save the file
                
                The export includes all logs, photos, notes, and insights.
                
                Perfect for doctor visits or keeping a permanent record!
                """,
                category: .dataPrivacy,
                searchKeywords: ["export", "download", "data", "backup", "doctor", "pdf"],
                videoUrl: nil,
                relatedArticles: ["how-to-delete-account", "privacy-security"]
            ),
            
            // 8. How do I change my subscription plan?
            HelpArticle(
                id: "change-subscription-plan",
                title: "How do I change my subscription plan?",
                content: """
                Switch between monthly and annual plans:
                
                1. Go to Settings
                2. Tap "Subscription"
                3. Tap "Change Plan"
                4. Select new plan
                5. Confirm change
                
                Changes take effect at your next billing date.
                
                Annual plans save you $69 per year!
                """,
                category: .subscription,
                searchKeywords: ["change", "plan", "monthly", "annual", "upgrade", "downgrade"],
                videoUrl: nil,
                relatedArticles: ["subscription-plans", "how-to-cancel-subscription"]
            ),
            
            // 9. Why is my prediction wrong?
            HelpArticle(
                id: "why-prediction-wrong",
                title: "Why is my prediction wrong?",
                content: """
                Predictions aren't always perfect because:
                
                • Every baby is unique
                • Patterns change (growth spurts, teething, illness)
                • Life happens (travel, visitors, schedule changes)
                
                To improve accuracy:
                • Track consistently for 7+ days
                • Log wake times accurately
                • Note unusual circumstances
                
                Predictions are guidance, not guarantees. Trust your parental intuition!
                """,
                category: .troubleshooting,
                searchKeywords: ["wrong", "inaccurate", "prediction", "incorrect", "bad"],
                videoUrl: nil,
                relatedArticles: ["how-predictions-work", "prediction-confidence-explained"]
            ),
            
            // 10. How do I delete my account?
            HelpArticle(
                id: "how-to-delete-account",
                title: "How do I delete my account?",
                content: """
                To permanently delete your account and all data:
                
                1. Go to Settings
                2. Tap "Data & Privacy"
                3. Scroll to bottom
                4. Tap "Delete Account"
                5. Confirm deletion
                
                ⚠️ This is permanent and cannot be undone.
                
                Consider exporting your data first (Settings → Data & Privacy → Export Data).
                
                After deletion, all data is removed from your device and iCloud within 24 hours.
                """,
                category: .dataPrivacy,
                searchKeywords: ["delete", "account", "remove", "data", "permanent"],
                videoUrl: nil,
                relatedArticles: ["how-to-export-data", "privacy-security"]
            )
        ]
    }
}

// MARK: - Models

enum HelpCategory: String, CaseIterable, Identifiable {
    case gettingStarted = "getting_started"
    case logging = "logging"
    case predictions = "predictions"
    case partnerSync = "partner_sync"
    case troubleshooting = "troubleshooting"
    case subscription = "subscription"
    case dataPrivacy = "data_privacy"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .gettingStarted: return "Getting Started"
        case .logging: return "Logging Events"
        case .predictions: return "Predictions & Insights"
        case .partnerSync: return "Partner & Family"
        case .troubleshooting: return "Troubleshooting"
        case .subscription: return "Subscription & Billing"
        case .dataPrivacy: return "Data & Privacy"
        }
    }
    
    var icon: String {
        switch self {
        case .gettingStarted: return "star.fill"
        case .logging: return "square.and.pencil"
        case .predictions: return "sparkles"
        case .partnerSync: return "person.2.fill"
        case .troubleshooting: return "wrench.and.screwdriver.fill"
        case .subscription: return "creditcard.fill"
        case .dataPrivacy: return "lock.shield.fill"
        }
    }
}

enum HelpContext {
    case feedForm
    case sleepForm
    case diaperForm
    case predictions
    case partnerSync
    case subscription
    case dataExport
}

struct HelpArticle: Identifiable {
    let id: String
    let title: String
    let content: String
    let category: HelpCategory
    let searchKeywords: [String]
    let videoUrl: String?
    let relatedArticles: [String]
    var viewCount: Int = 0
    var helpfulVotes: Int = 0
    var notHelpfulVotes: Int = 0
    
    var helpfulnessRatio: Double {
        let total = helpfulVotes + notHelpfulVotes
        guard total > 0 else { return 0 }
        return Double(helpfulVotes) / Double(total)
    }
}

// Uses global logger instance
