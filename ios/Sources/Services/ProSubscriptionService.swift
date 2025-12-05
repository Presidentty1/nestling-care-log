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
    case smartSuggestions = "smart_suggestions"
    case intelligentReminders = "intelligent_reminders"
    case cryAnalysis = "cry_analysis"
    case advancedExport = "advanced_export"
    case csvExport = "csv_export"
    case familySharing = "family_sharing"
    case prioritySupport = "priority_support"

    var displayName: String {
        switch self {
        case .smartSuggestions: return "Smarter nap & feed suggestions"
        case .intelligentReminders: return "Gentle reminders for feeds and naps"
        case .cryAnalysis: return "Experimental cry insights (Beta)"
        case .advancedExport: return "Advanced export options"
        case .csvExport: return "Basic export"
        case .familySharing: return "Family sharing"
        case .prioritySupport: return "Priority support"
        }
    }

    var description: String {
        switch self {
        case .smartSuggestions: return "AI-powered predictions and insights"
        case .intelligentReminders: return "Smart notifications based on your baby's patterns"
        case .cryAnalysis: return "Advanced cry pattern analysis"
        case .advancedExport: return "Doctor-ready summaries and reports"
        case .csvExport: return "Export your data as CSV"
        case .familySharing: return "Share access with caregivers"
        case .prioritySupport: return "Faster response times and premium support"
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

    // Delegate to RevenueCat service
    private let revenueCatService = RevenueCatService.shared

    private init() {
        // Subscribe to RevenueCat changes
        Task {
            await setupRevenueCatBindings()
            await loadProducts()
            await checkSubscriptionStatus()
        }
    }

    private func setupRevenueCatBindings() async {
        // Bind RevenueCat properties to our published properties
        Task { @MainActor in
            // This would be set up with Combine publishers in a real implementation
            await revenueCatService.checkSubscriptionStatus()
            self.subscriptionStatus = revenueCatService.subscriptionStatus
            self.isProUser = revenueCatService.isProUser
        }
    }
    
    /// Load available products from RevenueCat
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        await revenueCatService.loadOfferings()
        Logger.info("[Pro] Loaded \(revenueCatService.offerings.count) offerings")
    }

    /// Check current subscription status
    func checkSubscriptionStatus() async {
        await revenueCatService.checkSubscriptionStatus()
        subscriptionStatus = revenueCatService.subscriptionStatus
        isProUser = revenueCatService.isProUser
    }
    
    /// Purchase subscription
    /// - Parameter packageId: Package ID to purchase
    /// - Returns: Success status
    func purchase(packageId: String) async -> Bool {
        return await revenueCatService.purchase(packageId: packageId)
    }
    
    /// Restore purchases
    func restorePurchases() async -> Bool {
        return await revenueCatService.restorePurchases()
    }
    
    /// Check if user has access to a specific feature
    /// - Parameter feature: Feature to check
    /// - Returns: True if user has access
    func hasAccess(to feature: ProFeature) -> Bool {
        // Free tier includes basic features
        let freeFeatures: [ProFeature] = [
            // Basic logging is always free
            // Age-based wake windows are free (basic predictions)
        ]

        if freeFeatures.contains(feature) {
            return true
        }

        // Pro-gated features
        let proFeatures: [ProFeature] = [
            .smartSuggestions,    // AI-powered predictions
            .intelligentReminders, // Smart notifications
            .cryAnalysis,         // AI cry analysis
            .advancedExport,      // Advanced export options
            .familySharing,       // Multi-caregiver
            .prioritySupport      // Premium support
        ]

        if proFeatures.contains(feature) {
            return isProUser
        }

        // Default to free for unknown features
        return true
    }
    
    /// Get available subscription offerings
    func getOfferings() -> [RevenueCatOffering] {
        return revenueCatService.offerings
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


