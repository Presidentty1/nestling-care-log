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
    // TODO: Update bundle identifier from com.nestling.* to com.nuzzle.* when ready
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
        
        // Restore dev mode if it was previously enabled
        if UserDefaults.standard.bool(forKey: "dev_pro_mode_enabled") {
            isProUser = true
            subscriptionStatus = .subscribed
            trialDaysRemaining = 999
            print("[Pro] Dev mode restored from UserDefaults")
        }

        Task {
            // Only check real subscription status if dev mode is not enabled
            if !UserDefaults.standard.bool(forKey: "dev_pro_mode_enabled") {
                await loadProducts()
                await checkSubscriptionStatus()
                startTransactionListener()
            }
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
                        // For StoreKit 2, trials are detected by checking if purchase date is recent
                        // and expiration date exists (for subscriptions with trials)
                        if let expirationDate = transaction.expirationDate {
                            let purchaseDate = transaction.originalPurchaseDate
                            let daysSincePurchase = Calendar.current.dateComponents([.day], from: purchaseDate, to: Date()).day ?? 0
                            
                            // If subscription is within first 7 days and not expired, it's likely a trial
                            if daysSincePurchase <= trialDurationDays && expirationDate > Date() {
                                let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0
                                if daysRemaining > 0 {
                                    await MainActor.run {
                                        trialDaysRemaining = daysRemaining
                                        // During trial, user has Pro access
                                        isProUser = true
                                        subscriptionStatus = .subscribed
                                    }

                                    // Analytics: trial started (if this is the first time we detect it)
                                    let hasLoggedTrial = UserDefaults.standard.bool(forKey: "trial_started_logged_\(transaction.productID)")
                                    if !hasLoggedTrial {
                                        UserDefaults.standard.set(true, forKey: "trial_started_logged_\(transaction.productID)")
                                        Task {
                                            await Analytics.shared.logSubscriptionTrialStarted(
                                                plan: transaction.productID.contains("yearly") ? "yearly" : "monthly",
                                                source: "storekit_introductory_offer"
                                            )
                                        }
                                    }
                                    return
                                }
                            }
                        }
                    }
                }
            }

            // No active trial found
            await MainActor.run {
                trialDaysRemaining = nil
            }
        } catch {
            print("[Pro] Failed to check trial status: \(error)")
            await MainActor.run {
                trialDaysRemaining = nil
            }
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
                if _ = transaction.expirationDate {
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
                        // Check expiration
                        if let expirationDate = transaction.expirationDate {
                            if expirationDate < Date() {
                                // Subscription expired
                                await MainActor.run {
                                    subscriptionStatus = .expired
                                    isProUser = false
                                }
                            } else {
                                // Subscription is active
                                await MainActor.run {
                                    subscriptionStatus = .subscribed
                                    isProUser = true
                                }
                                
                                // Check if this is a trial (first 7 days)
                                let purchaseDate = transaction.originalPurchaseDate
                                let daysSincePurchase = Calendar.current.dateComponents([.day], from: purchaseDate, to: Date()).day ?? 0
                                if daysSincePurchase <= trialDurationDays {
                                    let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0
                                    await MainActor.run {
                                        trialDaysRemaining = max(0, daysRemaining)
                                    }
                                }
                            }
                        } else {
                            // No expiration date - assume active subscription
                            await MainActor.run {
                                subscriptionStatus = .subscribed
                                isProUser = true
                            }
                        }

                        return
                    }
                }
            }

            // No active subscription - check trial status
            await checkTrialStatus()

            // If no trial and no subscription, user is not Pro
            await MainActor.run {
                if trialDaysRemaining == nil || trialDaysRemaining! <= 0 {
                    subscriptionStatus = .notSubscribed
                    isProUser = false
                }
            }
        } catch {
            print("[Pro] Failed to check subscription: \(error)")
            await MainActor.run {
                subscriptionStatus = .notSubscribed
                isProUser = false
            }
        }
    }
    
    /// Purchase subscription
    /// - Parameter productID: Product ID to purchase
    /// - Returns: Success status
    func purchase(productID: String) async -> Bool {
        // Ensure products are loaded
        if products.isEmpty {
            print("[Pro] Products not loaded, loading now...")
            await loadProducts()
        }
        
        guard let product = products.first(where: { $0.id == productID }) else {
            print("[Pro] Product not found: \(productID)")
            print("[Pro] Available products: \(products.map { $0.id })")
            return false
        }
        
        print("[Pro] Starting purchase for product: \(product.displayName) (\(productID))")
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    print("[Pro] Purchase verified successfully")
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
                    print("[Pro] Unverified transaction: \(error.localizedDescription)")
                    return false
                }
            case .userCancelled:
                print("[Pro] User cancelled purchase")
                return false
            case .pending:
                print("[Pro] Purchase pending (requires approval)")
                // For pending purchases, we should still return true as the purchase is in progress
                // The transaction listener will handle the completion
                return true
            @unknown default:
                print("[Pro] Unknown purchase result")
                return false
            }
        } catch {
            print("[Pro] Purchase failed with error: \(error.localizedDescription)")
            print("[Pro] Error details: \(error)")
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
        // This would integrate with the actual data store
        // For now, return placeholder stats
        // TODO: Integrate with CoreDataStore to get real stats
        return UsageStats(
            totalEvents: 47,
            daysTracked: 12,
            timeSaved: "1.5h" // 47 events * 2 minutes each = 94 minutes = 1.5 hours
        )
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

