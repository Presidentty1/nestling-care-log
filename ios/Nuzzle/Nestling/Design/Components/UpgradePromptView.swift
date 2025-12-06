import SwiftUI

/// Upgrade prompt view for Pro features
/// Shows feature benefits and pricing with clear CTA
struct UpgradePromptView: View {
    let feature: ProFeature
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: SubscriptionPlan = .yearly
    
    enum SubscriptionPlan {
        case monthly, yearly
        
        var price: String {
            switch self {
            case .monthly: return "$5.99"
            case .yearly: return "$44.99"
            }
        }
        
        var period: String {
            switch self {
            case .monthly: return "month"
            case .yearly: return "year"
            }
        }
        
        var savings: String? {
            switch self {
            case .monthly: return nil
            case .yearly: return "Save 37%"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacing2XL) {
                    // Header
                    VStack(spacing: .spacingMD) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.primary)
                        
                        Text("Upgrade to Premium")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.foreground)
                        
                        Text("Unlock \(feature.displayName.lowercased()) and all premium features")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.mutedForeground)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, .spacingLG)
                    }
                    .padding(.top, .spacingXL)
                    
                    // Plan Selection
                    VStack(spacing: .spacingMD) {
                        PlanCard(
                            plan: .monthly,
                            isSelected: selectedPlan == .monthly,
                            onSelect: { selectedPlan = .monthly }
                        )
                        
                        PlanCard(
                            plan: .yearly,
                            isSelected: selectedPlan == .yearly,
                            onSelect: { selectedPlan = .yearly }
                        )
                    }
                    .padding(.horizontal, .spacingLG)
                    
                    // Premium Features List
                    VStack(alignment: .leading, spacing: .spacingMD) {
                        Text("What's Included")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.foreground)
                        
                        PremiumFeatureRow(icon: "brain.head.profile", title: "Unlimited AI Predictions", description: "Nap windows and feeding suggestions")
                        PremiumFeatureRow(icon: "calendar.badge.clock", title: "Full Calendar View", description: "See patterns with monthly heatmap")
                        PremiumFeatureRow(icon: "chart.xyaxis.line", title: "Growth Tracking", description: "WHO percentile charts")
                        PremiumFeatureRow(icon: "photo.on.rectangle", title: "Photo Attachments", description: "Capture moments with events")
                        PremiumFeatureRow(icon: "doc.text.fill", title: "PDF Reports", description: "Share with pediatrician")
                        PremiumFeatureRow(icon: "person.2.fill", title: "Family Sharing", description: "Sync with up to 5 caregivers")
                        PremiumFeatureRow(icon: "bell.badge.fill", title: "Smart Reminders", description: "Adaptive feed and nap alerts")
                    }
                    .padding(.spacingLG)
                    .background(Color.surface)
                    .cornerRadius(.radiusLG)
                    .padding(.horizontal, .spacingLG)
                    
                    // Trust Signals
                    VStack(spacing: .spacingSM) {
                        TrustSignal(icon: "checkmark.shield.fill", text: "7-day free trial")
                        TrustSignal(icon: "arrow.clockwise", text: "Cancel anytime")
                        TrustSignal(icon: "lock.shield.fill", text: "Secure payment via Apple")
                    }
                    .padding(.horizontal, .spacingLG)
                    
                    Spacer(minLength: 80)
                }
            }
            .background(Color.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.mutedForeground)
                }
            }
            .safeAreaInset(edge: .bottom) {
                // CTA Button
                VStack(spacing: .spacingSM) {
                    Button(action: {
                        startTrial()
                    }) {
                        VStack(spacing: 4) {
                            Text("Start 7-Day Free Trial")
                                .font(.system(size: 17, weight: .semibold))
                            Text("Then \(selectedPlan.price)/\(selectedPlan.period)")
                                .font(.system(size: 13, weight: .regular))
                                .opacity(0.9)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.primary)
                        .cornerRadius(.radiusXL)
                        .shadow(color: Color.primary.opacity(0.4), radius: 16, x: 0, y: 8)
                    }
                    
                    Text("No credit card required • Cancel anytime")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.mutedForeground)
                        .multilineTextAlignment(.center)
                }
                .padding(.spacingLG)
                .background(Color.background.opacity(0.95))
            }
        }
    }
    
    private func startTrial() {
        Task {
            let productID = selectedPlan == .monthly ? "com.nestling.pro.monthly" : "com.nestling.pro.yearly"
            let success = await ProSubscriptionService.shared.purchase(productID: productID)
            if success {
                dismiss()
            }
        }
    }
}

// MARK: - Plan Card
struct PlanCard: View {
    let plan: UpgradePromptView.SubscriptionPlan
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: {
            onSelect()
            Haptics.selection()
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: .spacingSM) {
                        Text(plan == .monthly ? "Monthly" : "Yearly")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(isSelected ? .white : .foreground)
                        
                        if let savings = plan.savings {
                            Text(savings)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(isSelected ? .white : .primary)
                                .padding(.horizontal, .spacingSM)
                                .padding(.vertical, 2)
                                .background(isSelected ? Color.white.opacity(0.2) : Color.primary.opacity(0.1))
                                .cornerRadius(.radiusSM)
                        }
                    }
                    
                    Text("\(plan.price)/\(plan.period)")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .mutedForeground)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .mutedForeground)
            }
            .padding(.spacingLG)
            .background(isSelected ? Color.primary : Color.surface)
            .cornerRadius(.radiusLG)
            .overlay(
                RoundedRectangle(cornerRadius: .radiusLG)
                    .stroke(isSelected ? Color.primary : Color.cardBorder, lineWidth: isSelected ? 2 : 1)
            )
            .shadow(
                color: isSelected ? Color.primary.opacity(0.2) : .clear,
                radius: isSelected ? 8 : 0,
                x: 0,
                y: isSelected ? 4 : 0
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Premium Feature Row
struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: .spacingMD) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.primary)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.foreground)
                Text(description)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.mutedForeground)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.success)
        }
    }
}

// MARK: - Trust Signal
struct TrustSignal: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: .spacingSM) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.primary)
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.foreground)
        }
    }
}

#Preview {
    UpgradePromptView(feature: .smartPredictions)
}

