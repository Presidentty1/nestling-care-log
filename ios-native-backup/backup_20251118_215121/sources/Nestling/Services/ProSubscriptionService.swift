import Foundation
import StoreKit

/// Pro subscription service using StoreKit 2.
/// 
/// Manages in-app purchases for Pro features:
/// - Advanced analytics
/// - Unlimited babies
/// - Family sharing (caregiver invites)
/// - Priority support
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
    case advancedAnalytics = "advanced_analytics"
    case unlimitedBabies = "unlimited_babies"
    case caregiverInvites = "caregiver_invites"
    case prioritySupport = "priority_support"
    case csvExport = "csv_export"
    case pdfReports = "pdf_reports"
    
    var displayName: String {
        switch self {
        case .advancedAnalytics: return "Advanced Analytics"
        case .unlimitedBabies: return "Unlimited Babies"
        case .caregiverInvites: return "Family Sharing"
        case .prioritySupport: return "Priority Support"
        case .csvExport: return "CSV Export"
        case .pdfReports: return "PDF Reports"
        }
    }
    
    var description: String {
        switch self {
        case .advancedAnalytics: return "Detailed charts and insights"
        case .unlimitedBabies: return "Track multiple babies"
        case .caregiverInvites: return "Share with family members"
        case .prioritySupport: return "Faster response times"
        case .csvExport: return "Export data as CSV"
        case .pdfReports: return "Generate PDF reports"
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
    
    // Product IDs (configure in App Store Connect)
    private let monthlyProductID = "com.nestling.pro.monthly"
    private let yearlyProductID = "com.nestling.pro.yearly"
    
    private var products: [Product] = []
    private var currentSubscription: Product?
    
    private init() {
        Task {
            await loadProducts()
            await checkSubscriptionStatus()
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
            
            // No active subscription
            subscriptionStatus = .notSubscribed
            isProUser = false
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
        // Free tier includes basic features
        let freeFeatures: [ProFeature] = [.csvExport]
        
        if freeFeatures.contains(feature) {
            return true
        }
        
        return isProUser
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

