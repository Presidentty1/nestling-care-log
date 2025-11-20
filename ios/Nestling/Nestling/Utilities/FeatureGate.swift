import Foundation
import SwiftUI

/// Helper for feature gating throughout the app.
/// 
/// Usage:
/// ```swift
/// FeatureGate.check(.unlimitedBabies) {
///     // Show feature
/// } paywall: {
///     // Show paywall
/// }
/// ```
struct FeatureGate {
    private static let proService = ProSubscriptionService.shared
    
    /// Check if feature is accessible
    /// - Parameter feature: Feature to check
    /// - Returns: True if user has access
    static func hasAccess(to feature: ProFeature) -> Bool {
        return proService.hasAccess(to: feature)
    }
    
    /// Check if feature requires Pro
    /// - Parameter feature: Feature to check
    /// - Returns: True if Pro is required
    static func requiresPro(_ feature: ProFeature) -> Bool {
        return proService.requiresPro(feature)
    }
    
    /// Execute block if feature is accessible, otherwise show paywall
    /// - Parameters:
    ///   - feature: Feature to check
    ///   - accessible: Block to execute if accessible
    ///   - paywall: Block to execute if Pro is required
    @ViewBuilder
    static func check<Content: View, Paywall: View>(
        _ feature: ProFeature,
        @ViewBuilder accessible: () -> Content,
        @ViewBuilder paywall: () -> Paywall
    ) -> some View {
        if hasAccess(to: feature) {
            accessible()
        } else {
            paywall()
        }
    }
    
    /// Execute block if feature is accessible, otherwise execute paywall block
    /// - Parameters:
    ///   - feature: Feature to check
    ///   - accessible: Block to execute if accessible
    ///   - paywall: Block to execute if Pro is required
    static func check(
        _ feature: ProFeature,
        accessible: () -> Void,
        paywall: () -> Void
    ) {
        if hasAccess(to: feature) {
            accessible()
        } else {
            paywall()
        }
    }
}

/// View modifier for feature gating
struct FeatureGateModifier<Paywall: View>: ViewModifier {
    let feature: ProFeature
    let paywall: () -> Paywall
    
    func body(content: Content) -> some View {
        FeatureGate.check(feature, accessible: { content }, paywall: paywall)
    }
}

extension View {
    /// Gate a view behind a Pro feature
    /// - Parameters:
    ///   - feature: Feature to check
    ///   - paywall: Paywall view to show if Pro is required
    /// - Returns: View or paywall
    func featureGate<Paywall: View>(
        _ feature: ProFeature,
        @ViewBuilder paywall: @escaping () -> Paywall
    ) -> some View {
        modifier(FeatureGateModifier(feature: feature, paywall: paywall))
    }
}

/// Feature gating for babies limit (free tier: 1 baby)
struct BabyLimitGate {
    private static let proService = ProSubscriptionService.shared
    
    /// Check if user can add another baby
    /// - Parameter currentBabyCount: Current number of babies
    /// - Returns: True if user can add another baby
    static func canAddBaby(currentBabyCount: Int) -> Bool {
        // Free tier: 1 baby max
        // Pro: unlimited
        if proService.isProUser {
            return true
        }
        return currentBabyCount < 1
    }
    
    /// Check if user can access full history (free tier: 7 days)
    /// - Parameter daysRequested: Number of days requested
    /// - Returns: True if accessible
    static func canAccessHistory(daysRequested: Int) -> Bool {
        // Free tier: 7 days max
        // Pro: unlimited
        if proService.isProUser {
            return true
        }
        return daysRequested <= 7
    }
}

