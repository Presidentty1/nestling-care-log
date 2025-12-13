import SwiftUI

struct PaywallView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @StateObject private var proService = ProSubscriptionService.shared
    @State private var selectedPlan: SubscriptionPlan = .monthly
    
    enum SubscriptionPlan {
        case monthly
        case annual
        
        var displayPrice: String {
            switch self {
            case .monthly: return "$5.99/month"
            case .annual: return "$49.99/year"
            }
        }
        
        var effectiveMonthlyPrice: String {
            switch self {
            case .monthly: return "$5.99"
            case .annual: return "$4.17"
            }
        }
        
        var savingsText: String? {
            switch self {
            case .monthly: return nil
            case .annual: return "Save 30%"
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: .spacingXL) {
                VStack(spacing: .spacingSM) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 48))
                        .foregroundColor(.primary)
                    
                    Text("Unlock your AI baby copilot")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.foreground)
                        .multilineTextAlignment(.center)
                    
                    Text("Try all smart features free for 7 days.\nKeep basic tracking forever.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.mutedForeground)
                        .multilineTextAlignment(.center)

                    // AAP research mention
                    if PolishFeatureFlags.shared.citationsEnabled {
                        Text("Based on AAP research and pediatric guidelines")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.mutedForeground.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                }
                .padding(.top, .spacingXL)
                
                // Features list
                VStack(spacing: .spacingMD) {
                    PaywallFeatureRow(
                        icon: "moon.zzz.fill",
                        title: "Live nap & bedtime suggestions",
                        description: "Get predictions as you log, adapting to your baby's patterns"
                    )
                    
                    PaywallFeatureRow(
                        icon: "waveform",
                        title: "Cry recordings labeled (beta)",
                        description: "Possible reasons: hungry, tired, discomfort, pain"
                    )
                    
                    PaywallFeatureRow(
                        icon: "bubble.left.and.bubble.right.fill",
                        title: "Ask any question about your baby's day",
                        description: "Chat with AI about patterns, concerns, and next steps"
                    )
                    
                    PaywallFeatureRow(
                        icon: "person.2.fill",
                        title: "Shared timeline for partners & caregivers",
                        description: "Everyone stays in sync with real-time updates"
                    )
                }
                .padding(.horizontal, .spacingLG)
                
                // Plan selector
                VStack(spacing: .spacingMD) {
                    Text("Choose your plan")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.foreground)
                    
                    HStack(spacing: .spacingMD) {
                        PlanButton(
                            plan: .monthly,
                            isSelected: selectedPlan == .monthly,
                            action: {
                                selectedPlan = .monthly
                                Haptics.selection()
                            }
                        )
                        
                        PlanButton(
                            plan: .annual,
                            isSelected: selectedPlan == .annual,
                            action: {
                                selectedPlan = .annual
                                Haptics.selection()
                            }
                        )
                    }
                }
                .padding(.horizontal, .spacingLG)
                
                // Disclaimer
                VStack(spacing: 4) {
                    Text("These AI features suggest patterns and possibilities.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.mutedForeground)
                        .multilineTextAlignment(.center)
                    
                    Text("They don't replace medical care or professional advice.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.mutedForeground)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, .spacingLG)
                
                Spacer(minLength: 20)
                
                VStack(spacing: .spacingSM) {
                    Button(action: {
                        Haptics.light()
                        startTrial()
                    }) {
                        Text("Start free trial")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.primary)
                            .cornerRadius(.radiusXL)
                            .shadow(color: Color.primary.opacity(0.3), radius: 12, x: 0, y: 6)
                    }
                    
                    Text("7 days free, then \(selectedPlan.effectiveMonthlyPrice)/mo")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.mutedForeground)
                    
                    Button("Continue with free tracking") {
                        Haptics.light()
                        coordinator.skipPaywall()
                    }
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.mutedForeground)
                    .padding(.top, .spacingSM)
                }
                .padding(.horizontal, .spacingLG)
                .padding(.bottom, .spacing2XL)
            }
        }
        .background(Color.background)
        .onAppear {
            Task {
                await Analytics.shared.logOnboardingStepViewed(step: "paywall")
                // TODO: Analytics.track(.paywallShownOnboarding)
            }
        }
    }
    
    private func startTrial() {
        Task {
            // TODO: Implement actual subscription purchase flow
            // For now, just mark trial as started and continue
            // TODO: Analytics.track(.trialStarted)
            await Analytics.shared.logOnboardingStepViewed(step: "trial_started")
            
            await MainActor.run {
                coordinator.next()
            }
        }
    }
}

// MARK: - Paywall Feature Row
private struct PaywallFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: .spacingMD) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.primary)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.foreground)
                
                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.mutedForeground)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

// MARK: - Plan Button
struct PlanButton: View {
    let plan: PaywallView.SubscriptionPlan
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: .spacingSM) {
                if let savings = plan.savingsText {
                    Text(savings)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(isSelected ? .white : .primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(isSelected ? Color.white.opacity(0.2) : Color.primary.opacity(0.1))
                        .cornerRadius(8)
                } else {
                    Text(" ")
                        .font(.system(size: 11, weight: .bold))
                }
                
                Text(plan == .monthly ? "Monthly" : "Annual")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .foreground)
                
                Text(plan.displayPrice)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .mutedForeground)
                
                Text(plan.effectiveMonthlyPrice + "/mo")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, .spacingMD)
            .background(isSelected ? Color.primary : Color.surface)
            .cornerRadius(.radiusLG)
            .overlay(
                RoundedRectangle(cornerRadius: .radiusLG)
                    .stroke(isSelected ? Color.primary : Color.cardBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PaywallView(coordinator: OnboardingCoordinator(dataStore: InMemoryDataStore()))
}

