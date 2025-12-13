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
    @Published var productLoadError: String? = nil
    
    // 7-day time-based trial (starts on first app launch)
    private let trialDurationDays = 7
    private var trialStartDate: Date? {
        get {
            UserDefaults.standard.object(forKey: "trial_start_date") as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "trial_start_date")
        }
    }

    // Product IDs (configure in App Store Connect)
    // TODO: Update bundle identifier from com.nestling.* to com.nuzzle.* when ready
    // Note: Product IDs remain unchanged for StoreKit continuity with existing subscriptions
    private let monthlyProductID = "com.nestling.pro.monthly"
    private let yearlyProductID = "com.nestling.pro.yearly"

    private var products: [Product] = []
    private var currentSubscription: Product?
    
    private var transactionListener: Task<Void, Never>?
    
    private init() {
        initializeFreeTierLimits()
        initializeTimeBasedTrial()
        
        // Restore dev mode if it was previously enabled
        if UserDefaults.standard.bool(forKey: "dev_pro_mode_enabled") {
            isProUser = true
            subscriptionStatus = .subscribed
            trialDaysRemaining = 999
            logger.debug("[Pro] Dev mode restored from UserDefaults")
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
    
    /// Initialize 7-day time-based trial on first launch
    private func initializeTimeBasedTrial() {
        // Start trial on first app launch
        if trialStartDate == nil {
            trialStartDate = Date()
            logger.debug("[Pro] Started 7-day trial at \(Date())")
            
            // Schedule Day 5 warning notification
            NotificationScheduler.shared.scheduleTrialWarningNotification(trialStartDate: Date())
        }
        
        // Calculate remaining days
        updateTrialDaysRemaining()
    }
    
    /// Update trial days remaining based on start date
    private func updateTrialDaysRemaining() {
        guard let startDate = trialStartDate else {
            trialDaysRemaining = nil
            return
        }
        
        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: .day, value: trialDurationDays, to: startDate)!
        let daysRemaining = calendar.dateComponents([.day], from: Date(), to: endDate).day ?? 0
        
        if daysRemaining > 0 {
            trialDaysRemaining = daysRemaining
            // During trial, user has Pro access
            if !isProUser && subscriptionStatus != .subscribed {
                isProUser = true
                logger.debug("[Pro] Time-based trial active: \(daysRemaining) days remaining")
            }
        } else {
            trialDaysRemaining = 0
            // Trial ended, revoke Pro access if no subscription
            if subscriptionStatus != .subscribed {
                isProUser = false
                logger.debug("[Pro] Time-based trial expired")
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
                        if #available(iOS 17.2, *), let offerType = transaction.offer?.type, offerType == .introductory,
                           let expirationDate = transaction.expirationDate {
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
                        } else if let expirationDate = transaction.expirationDate {
                            let purchaseDate = transaction.originalPurchaseDate
                            let daysSincePurchase = Calendar.current.dateComponents([.day], from: purchaseDate, to: Date()).day ?? 0
                            
                            // If subscription is within first 7 days and not expired, treat as trial
                            if daysSincePurchase <= trialDurationDays && expirationDate > Date() {
                                let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0
                                if daysRemaining > 0 {
                                    await MainActor.run {
                                        trialDaysRemaining = daysRemaining
                                        isProUser = true
                                        subscriptionStatus = .subscribed
                                    }

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
            logger.debug("[Pro] Failed to check trial status: \(error)")
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
                    logger.debug("[Pro] Transaction verification failed: \(error)")
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
                if let _ = transaction.expirationDate {
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
        productLoadError = nil
        defer { isLoading = false }
        
        do {
            products = try await Product.products(for: [monthlyProductID, yearlyProductID])
            logger.debug("[Pro] Loaded \(products.count) products")
            
            if products.isEmpty {
                productLoadError = "No subscription products found. Please check your internet connection and try again."
                logger.debug("[Pro] Warning: Product array is empty")
            }
        } catch {
            productLoadError = "Unable to load subscription options. Please check your internet connection and try again."
            logger.debug("[Pro] Failed to load products: \(error.localizedDescription)")
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
                                subscriptionStatus = .expired
                                isProUser = false
                            } else {
                                subscriptionStatus = .subscribed
                                isProUser = true

                                // If within the introductory period, surface trial days remaining
                                let purchaseDate = transaction.originalPurchaseDate
                                let daysSincePurchase = Calendar.current.dateComponents([.day], from: purchaseDate, to: Date()).day ?? 0
                                if daysSincePurchase <= trialDurationDays {
                                    let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0
                                    trialDaysRemaining = max(0, daysRemaining)
                                }
                            }
                        } else {
                            // No expiration date - assume active subscription
                            subscriptionStatus = .subscribed
                            isProUser = true
                        }

                        return
                    }
                }
            }

            // No active subscription - check time-based trial
            updateTrialDaysRemaining()

            // If trial expired and no subscription, user is not Pro
            if trialDaysRemaining == nil || trialDaysRemaining! <= 0 {
                subscriptionStatus = .notSubscribed
                isProUser = false
            }
        } catch {
            logger.debug("[Pro] Failed to check subscription: \(error)")
            // Even if subscription check fails, honor the time-based trial
            updateTrialDaysRemaining()
            if trialDaysRemaining == nil || trialDaysRemaining! <= 0 {
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
            logger.debug("[Pro] Products not loaded, loading now...")
            await loadProducts()
        }
        
        guard let product = products.first(where: { $0.id == productID }) else {
            logger.debug("[Pro] Product not found: \(productID)")
            logger.debug("[Pro] Available products: \(products.map { $0.id })")
            return false
        }
        
        logger.debug("[Pro] Starting purchase for product: \(product.displayName) (\(productID))")
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    logger.debug("[Pro] Purchase verified successfully")
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
                    logger.debug("[Pro] Unverified transaction: \(error.localizedDescription)")
                    return false
                }
            case .userCancelled:
                logger.debug("[Pro] User cancelled purchase")
                return false
            case .pending:
                logger.debug("[Pro] Purchase pending (requires approval)")
                // For pending purchases, we should still return true as the purchase is in progress
                // The transaction listener will handle the completion
                return true
            @unknown default:
                logger.debug("[Pro] Unknown purchase result")
                return false
            }
        } catch {
            logger.debug("[Pro] Purchase failed with error: \(error.localizedDescription)")
            logger.debug("[Pro] Error details: \(error)")
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
            logger.debug("[Pro] Restore failed: \(error)")
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
                logger.debug("[Pro] Failed to get expiration date: \(error)")
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
    - Add monthly subscription ($5.99/month)
    - Add yearly subscription ($39.99/year, save $32)
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

