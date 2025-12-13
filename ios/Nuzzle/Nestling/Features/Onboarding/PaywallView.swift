import SwiftUI
import StoreKit

struct PaywallView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @StateObject private var proService = ProSubscriptionService.shared
    @State private var selectedPlan: SubscriptionPlan = .monthly
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfUse = false

    enum SubscriptionPlan {
        case monthly
        case annual

        var productID: String {
            switch self {
            case .monthly: return "com.nestling.pro.monthly"
            case .annual: return "com.nestling.pro.yearly"
            }
        }

        var displayName: String {
            switch self {
            case .monthly: return "Monthly"
            case .annual: return "Annual"
            }
        }

        var savingsText: String? {
            switch self {
            case .monthly: return nil
            case .annual: return "Save 30%"
            }
        }

        func displayPrice(from products: [Product]) -> String {
            guard let product = products.first(where: { $0.id == productID }) else {
                // Fallback to loading state
                return "Loading..."
            }
            return product.displayPrice
        }

        func effectiveMonthlyPrice(from products: [Product]) -> String {
            guard let product = products.first(where: { $0.id == productID }) else {
                return "$5.99" // Fallback
            }

            switch self {
            case .monthly:
                return product.displayPrice
            case .annual:
                // Calculate effective monthly price for annual plan
                let price = product.price
                if let period = product.subscription?.subscriptionPeriod {
                    // Calculate months based on period unit
                    let months: Int
                    switch period.unit {
                    case .month: months = period.value
                    case .year: months = period.value * 12
                    case .week: months = period.value / 4
                    case .day: months = period.value / 30
                    @unknown default: months = 12
                    }
                    let safeMonths = max(1, months)
                    let effectiveMonthly = price / Decimal(safeMonths)
                    return effectiveMonthly.formatted(.currency(code: product.priceFormatStyle.currencyCode))
                }
                return "$4.17" // Fallback
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
                            products: proService.getProducts(),
                            isSelected: selectedPlan == .monthly,
                            action: {
                                selectedPlan = .monthly
                                Haptics.selection()
                            }
                        )

                        PlanButton(
                            plan: .annual,
                            products: proService.getProducts(),
                            isSelected: selectedPlan == .annual,
                            action: {
                                selectedPlan = .annual
                                Haptics.selection()
                            }
                        )
                    }
                }
                .padding(.horizontal, .spacingLG)

                // Error handling for failed product loading
                if !proService.isLoading && proService.getProducts().isEmpty {
                    VStack(spacing: .spacingMD) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 32))
                            .foregroundColor(.destructive)

                        Text("Unable to load subscription options")
                            .font(.headline)

                        Text("Please check your internet connection and try again.")
                            .font(.subheadline)
                            .foregroundColor(.mutedForeground)
                            .multilineTextAlignment(.center)

                        PrimaryButton("Retry", isDisabled: proService.isLoading) {
                            Task {
                                await proService.loadProducts()
                            }
                        }
                    }
                    .padding()
                }

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

                // Legal links
                HStack(spacing: .spacingMD) {
                    Button("Privacy Policy") {
                        showPrivacyPolicy = true
                    }
                    .font(.caption2)
                    .foregroundColor(.mutedForeground)

                    Text("•")
                        .foregroundColor(.mutedForeground)

                    Button("Terms of Use") {
                        showTermsOfUse = true
                    }
                    .font(.caption2)
                    .foregroundColor(.mutedForeground)
                }
                .padding(.bottom, .spacingSM)

                VStack(spacing: .spacingSM) {
                    Button(action: {
                        Haptics.light()
                        startTrial()
                    }) {
                        Text(proService.isLoading ? "Loading..." : "Start free trial")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.primary)
                            .cornerRadius(.radiusXL)
                            .shadow(color: Color.primary.opacity(0.3), radius: 12, x: 0, y: 6)
                    }
                    .disabled(proService.isLoading || proService.getProducts().isEmpty)
                    
                    Text("7 days free, then \(selectedPlan.effectiveMonthlyPrice(from: proService.getProducts()))/mo")
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
        .overlay {
            if proService.isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()

                    VStack(spacing: .spacingMD) {
                        ProgressView()
                            .tint(.white)
                        Text("Loading subscription options...")
                            .foregroundColor(.white)
                            .font(.subheadline)
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(.radiusLG)
                }
            }
        }
        .onAppear {
            Task {
                await proService.loadProducts()
                await Analytics.shared.logOnboardingStepViewed(step: "paywall")
                // TODO: Analytics.track(.paywallShownOnboarding)
            }
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            LegalDocumentView(documentType: .privacyPolicy)
        }
        .sheet(isPresented: $showTermsOfUse) {
            LegalDocumentView(documentType: .termsOfUse)
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
    let products: [Product]
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

                Text(plan.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .foreground)

                Text(plan.displayPrice(from: products))
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .mutedForeground)

                Text(plan.effectiveMonthlyPrice(from: products) + "/mo")
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

