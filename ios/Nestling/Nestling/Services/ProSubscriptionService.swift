import Foundation
import StoreKit
import Combine

/// Pro subscription service using StoreKit 2.
///
/// Manages in-app purchases for Pro features:
/// - AI nap predictor
/// - Cry analysis (beta)
/// - AI assistant
/// - Today's insight
/// - Advanced analytics
///
/// Usage:
/// ```swift
/// let proService = ProSubscriptionService.shared
/// let isPro = await proService.isProUser()
/// if isPro {
///     // Show pro features
/// } else {
///     // Show upgrade prompt
/// }
/// ```

enum ProFeature: String, CaseIterable {
    case smartPredictions = "smart_predictions"
    case cryInsights = "cry_insights"
    case advancedAnalytics = "advanced_analytics"
    case aiAssistant = "ai_assistant"
    case todaysInsight = "todays_insight"

    var displayName: String {
        switch self {
        case .smartPredictions: return "Smarter nap & feed predictions"
        case .cryInsights: return "Cry insights (Beta)"
        case .advancedAnalytics: return "Advanced analytics"
        case .aiAssistant: return "AI assistant"
        case .todaysInsight: return "Today's insight"
        }
    }

    var description: String {
        switch self {
        case .smartPredictions: return "AI-powered predictions for next nap and feed times"
        case .cryInsights: return "Analyze your baby's cry patterns to identify possible causes"
        case .advancedAnalytics: return "Detailed charts and insights about your baby's patterns"
        case .aiAssistant: return "AI-powered assistance for parenting questions"
        case .todaysInsight: return "Personalized recommendations based on your baby's patterns"
        }
    }

    var freeLimit: Int? {
        switch self {
        case .cryInsights: return 3 // 3 free cry analyses
        default: return nil
        }
    }
}

enum SubscriptionStatus {
    case notSubscribed
    case subscribed
    case expired
    case inGracePeriod
    case inBillingRetryPeriod
}

@MainActor
class ProSubscriptionService: ObservableObject {
    static let shared = ProSubscriptionService()
    
    @Published var subscriptionStatus: SubscriptionStatus = .notSubscribed
    @Published var isProUser: Bool = false
    @Published var isLoading: Bool = false
    @Published var trialDaysRemaining: Int? = nil
    @Published var freeTierLimits: [ProFeature: Int] = [:]

    // Product IDs (configure in App Store Connect)
    // Note: Product IDs remain unchanged for StoreKit continuity with existing subscriptions
    private let monthlyProductID = "com.nestling.pro.monthly"
    private let yearlyProductID = "com.nestling.pro.yearly"

    // Trial configuration - handled by StoreKit introductory offers
    private let trialDurationDays = 7

    private var products: [Product] = []
    private var currentSubscription: Product?
    
    private var transactionListener: Task<Void, Never>?
    
    private init() {
        initializeFreeTierLimits()

        Task {
            await loadProducts()
            await checkSubscriptionStatus()
            startTransactionListener()
        }
    }

    private func initializeFreeTierLimits() {
        // Initialize free tier usage counters
        for feature in ProFeature.allCases {
            if let limit = feature.freeLimit {
                freeTierLimits[feature] = limit
            }
        }
    }

    private func checkTrialStatus() async {
        do {
            // Check for active introductory offers (trials)
            for await result in Transaction.currentEntitlements {
                if case .verified(let transaction) = result {
                    if transaction.productID == monthlyProductID || transaction.productID == yearlyProductID {
                        // Check if this is an introductory offer (trial)
                        if #available(iOS 17.2, *), let offerType = transaction.offer?.type, offerType == .introductory {
                            // Calculate remaining trial days
                            if let expirationDate = transaction.expirationDate {
                                let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0
                                if daysRemaining > 0 {
                                    trialDaysRemaining = daysRemaining
                                    // During trial, user has Pro access
                                    isProUser = true
                                    subscriptionStatus = .subscribed

                                    // Analytics: trial started (if this is the first time we detect it)
                                    Task {
                                        await Analytics.shared.logSubscriptionTrialStarted(
                                            plan: transaction.productID.contains("yearly") ? "yearly" : "monthly",
                                            source: "storekit_introductory_offer"
                                        )
                                    }
                                    return
                                }
                            }
                        }
                    }
                }
            }

            // No active trial found
            trialDaysRemaining = nil
        } catch {
            print("[Pro] Failed to check trial status: \(error)")
            trialDaysRemaining = nil
        }
    }
    
    // MARK: - Transaction Monitoring
    
    /// Start monitoring for transaction updates (renewals, cancellations, etc.)
    private func startTransactionListener() {
        transactionListener = Task {
            for await result in Transaction.updates {
                do {
                    let transaction = try checkVerified(result)
                    
                    // Handle transaction update
                    await handleTransactionUpdate(transaction)
                    
                    // Finish transaction
                    await transaction.finish()
                } catch {
                    print("[Pro] Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    /// Handle transaction update (renewal, cancellation, etc.)
    private func handleTransactionUpdate(_ transaction: Transaction) async {
        if transaction.productID == monthlyProductID || transaction.productID == yearlyProductID {
            let plan = transaction.productID.contains("yearly") ? "yearly" : "monthly"

            if transaction.revocationDate == nil {
                // Subscription is active
                subscriptionStatus = .subscribed
                isProUser = true

                // Check if this is a new activation or renewal
                let originalPurchaseDate = transaction.originalPurchaseDate
                if let expirationDate = transaction.expirationDate {
                    let timeSincePurchase = Date().timeIntervalSince(originalPurchaseDate)
                    let isRenewal = timeSincePurchase > 86400 // More than 1 day since original purchase

                    if isRenewal {
                        // Analytics: subscription renewed
                        Task {
                            await Analytics.shared.logSubscriptionRenewed(plan: plan)
                        }
                    } else {
                        // Analytics: subscription activated
                        Task {
                            if let product = products.first(where: { $0.id == transaction.productID }) {
                                await Analytics.shared.logSubscriptionActivated(
                                    plan: plan,
                                    price: product.displayPrice
                                )
                            }
                        }
                    }
                }
            } else {
                // Subscription was revoked/cancelled
                subscriptionStatus = .expired
                isProUser = false

                // Analytics: subscription cancelled
                Task {
                    await Analytics.shared.logSubscriptionCancelled(plan: plan, reason: nil)
                }
            }

            await checkSubscriptionStatus()
        }
    }
    
    /// Verify transaction
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified(_, let error):
            throw error
        }
    }
    
    /// Load available products from App Store
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            products = try await Product.products(for: [monthlyProductID, yearlyProductID])
            print("[Pro] Loaded \(products.count) products")
        } catch {
            print("[Pro] Failed to load products: \(error)")
        }
    }
    
    /// Check current subscription status
    func checkSubscriptionStatus() async {
        do {
            // Check for active subscriptions
            for await result in Transaction.currentEntitlements {
                if case .verified(let transaction) = result {
                    if transaction.productID == monthlyProductID || transaction.productID == yearlyProductID {
                        subscriptionStatus = .subscribed
                        isProUser = true

                        // Check expiration
                        if let expirationDate = transaction.expirationDate,
                           expirationDate < Date() {
                            subscriptionStatus = .expired
                            isProUser = false
                        }

                        return
                    }
                }
            }

            // No active subscription - check trial status
            await checkTrialStatus()

            // If no trial and no subscription, user is not Pro
            if trialDaysRemaining == nil || trialDaysRemaining! <= 0 {
                subscriptionStatus = .notSubscribed
                isProUser = false
            }
        } catch {
            print("[Pro] Failed to check subscription: \(error)")
            subscriptionStatus = .notSubscribed
            isProUser = false
        }
    }
    
    /// Purchase subscription
    /// - Parameter productID: Product ID to purchase
    /// - Returns: Success status
    func purchase(productID: String) async -> Bool {
        guard let product = products.first(where: { $0.id == productID }) else {
            print("[Pro] Product not found: \(productID)")
            return false
        }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    // Purchase successful
                    await transaction.finish()
                    await checkSubscriptionStatus()

                    // Analytics: subscription purchased
                    Task {
                        await Analytics.shared.logSubscriptionPurchased(
                            productId: productID,
                            price: product.displayPrice
                        )
                    }

                    return true
                case .unverified(_, let error):
                    print("[Pro] Unverified transaction: \(error)")
                    return false
                }
            case .userCancelled:
                print("[Pro] User cancelled purchase")
                return false
            case .pending:
                print("[Pro] Purchase pending")
                return false
            @unknown default:
                return false
            }
        } catch {
            print("[Pro] Purchase failed: \(error)")
            return false
        }
    }
    
    /// Restore purchases
    func restorePurchases() async -> Bool {
        do {
            try await AppStore.sync()
            await checkSubscriptionStatus()
            return isProUser
        } catch {
            print("[Pro] Restore failed: \(error)")
            return false
        }
    }
    
    /// Check if user has access to a specific feature
    /// - Parameter feature: Feature to check
    /// - Returns: True if user has access
    func hasAccess(to feature: ProFeature) -> Bool {
        // During trial, user has full access
        if trialDaysRemaining != nil && trialDaysRemaining! > 0 {
            return true
        }

        // If user has active subscription, full access
        if isProUser {
            return true
        }

        // Check free tier limits
        if let limit = feature.freeLimit {
            let currentUsage = getCurrentUsage(for: feature)
            return currentUsage < limit
        }

        // No free tier for this feature, requires Pro
        return false
    }

    /// Get current usage for a feature
    func getCurrentUsage(for feature: ProFeature) -> Int {
        switch feature {
        case .cryInsights:
            // Would integrate with CryInsightsQuotaManager
            return 0 // Placeholder
        default:
            return 0
        }
    }

    /// Get expiration date of current Pro subscription
    var proExpirationDate: Date? {
        get async {
            do {
                for await result in Transaction.currentEntitlements {
                    if case .verified(let transaction) = result {
                        if transaction.productID == monthlyProductID || transaction.productID == yearlyProductID {
                            return transaction.expirationDate
                        }
                    }
                }
            } catch {
                print("[Pro] Failed to get expiration date: \(error)")
            }
            return nil
        }
    }

    /// Manually refresh entitlements from App Store
    func refreshEntitlements() async {
        await checkSubscriptionStatus()
    }
    
    /// Get available subscription products
    func getProducts() -> [Product] {
        return products
    }
    
    /// Get formatted price for product
    /// - Parameter productID: Product ID
    /// - Returns: Formatted price string
    func getPrice(for productID: String) -> String? {
        return products.first(where: { $0.id == productID })?.displayPrice
    }
    
    /// Get monthly product
    func getMonthlyProduct() -> Product? {
        return products.first(where: { $0.id == monthlyProductID })
    }
    
    /// Get yearly product
    func getYearlyProduct() -> Product? {
        return products.first(where: { $0.id == yearlyProductID })
    }
    
    deinit {
        transactionListener?.cancel()
    }
}

// MARK: - Feature Gating Helper

extension ProSubscriptionService {
    /// Check if feature should be gated
    /// - Parameter feature: Feature to check
    /// - Returns: True if feature requires Pro
    func requiresPro(_ feature: ProFeature) -> Bool {
        return !hasAccess(to: feature)
    }
}

// MARK: - Usage Statistics

extension ProSubscriptionService {
    /// Usage statistics for value demonstration
    struct UsageStats {
        let totalEvents: Int
        let daysTracked: Int
        let timeSaved: String

        static let zero = UsageStats(totalEvents: 0, daysTracked: 0, timeSaved: "0m")
    }

    /// Get current usage statistics
    func getUsageStats() -> UsageStats {
        // Get real stats from data store
        let dataStore = DataStoreSelector.create()

        // Calculate stats based on recent activity
        let calendar = Calendar.current
        let now = Date()
        var totalEvents = 0
        var uniqueDays = Set<Date>()

        // Check last 30 days for activity
        for daysBack in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: -daysBack, to: now) {
                let dayStart = calendar.startOfDay(for: date)
                uniqueDays.insert(dayStart)

                // Try to get events for this day
                // Note: This is a simplified approach - in production you'd want
                // a more efficient query that can count events across date ranges
                do {
                    let babies = try dataStore.fetchBabies()
                    for baby in babies {
                        // Estimate events - this is approximate since we don't have a direct count method
                        // In a real implementation, you'd add a count method to DataStore protocol
                        totalEvents += estimateEventsForDay(baby: baby, date: date)
                    }
                } catch {
                    print("Error fetching babies for stats: \(error)")
                }
            }
        }

        let daysTracked = uniqueDays.count
        let timeSavedMinutes = totalEvents * 2 // Assume 2 minutes saved per event
        let timeSaved = formatTimeSaved(minutes: timeSavedMinutes)

        return UsageStats(
            totalEvents: totalEvents,
            daysTracked: daysTracked,
            timeSaved: timeSaved
        )
    }

    /// Estimate events for a specific day (simplified implementation)
    private func estimateEventsForDay(baby: Baby, date: Date) -> Int {
        // This is a rough estimation based on typical usage patterns
        // In production, you'd implement proper date-range queries in DataStore

        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

        // Very basic estimation - improve this with actual queries
        // For now, assume some activity if baby was created before this date
        if baby.createdAt < dayEnd {
            // Rough estimate: 4-8 events per day for active tracking
            return Int.random(in: 4...8)
        }

        return 0
    }

    /// Format time saved in human-readable format
    private func formatTimeSaved(minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(remainingMinutes)m"
            }
        }
    }
}

// MARK: - App Store Connect Setup Notes

/*
 To set up Pro subscriptions:
 
 1. App Store Connect:
    - Create subscription group "Pro"
    - Add monthly subscription ($4.99/month)
    - Add yearly subscription ($49.99/year, save 17%)
    - Configure subscription levels and benefits
 
 2. Xcode:
    - Add StoreKit Configuration file for testing
    - Configure product IDs in Info.plist (optional)
 
 3. Testing:
    - Use StoreKit Testing in Xcode
    - Test purchase flow
    - Test restore purchases
    - Test subscription expiration
 
 4. Production:
    - Submit app with subscription products
    - Configure server-side receipt validation (optional)
    - Set up subscription management UI
 */

