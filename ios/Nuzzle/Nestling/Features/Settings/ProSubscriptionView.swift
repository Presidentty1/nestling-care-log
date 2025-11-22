import SwiftUI
import StoreKit

// MARK: - Contextual Upgrade Prompt

struct UpgradePromptView: View {
    let feature: ProFeature
    @Environment(\.dismiss) var dismiss
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            VStack(spacing: .spacingLG) {
                Spacer()

                // Feature Icon
                Image(systemName: featureIcon(for: feature))
                    .font(.system(size: 60))
                    .foregroundColor(.primary)
                    .padding(.bottom, .spacingMD)

                // Title
                Text("Unlock \(feature.displayName)")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                // Description
                Text(feature.description)
                    .font(.body)
                    .foregroundColor(.mutedForeground)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, .spacingMD)

                // Why it's helpful
                CardView(variant: .default) {
                    VStack(alignment: .leading, spacing: .spacingSM) {
                        Text("Why it helps:")
                            .font(.headline)

                        Text(whyHelpfulText(for: feature))
                            .font(.subheadline)
                            .foregroundColor(.foreground)
                    }
                    .padding(.spacingMD)
                }
                .padding(.horizontal, .spacingMD)

                Spacer()

                // Buttons
                VStack(spacing: .spacingMD) {
                    PrimaryButton("Upgrade to Pro", icon: "star.fill") {
                        showPaywall = true
                    }

                    Button("Maybe Later") {
                        dismiss()
                    }
                    .font(.subheadline)
                    .foregroundColor(.mutedForeground)
                }
                .padding(.horizontal, .spacingMD)
            }
            .padding(.vertical, .spacingXL)
            .navigationTitle("Pro Feature")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("✕") {
                        dismiss()
                    }
                    .font(.title2)
                    .foregroundColor(.mutedForeground)
                }
            }
            .sheet(isPresented: $showPaywall) {
                ProSubscriptionView()
            }
        }
    }

    private func featureIcon(for feature: ProFeature) -> String {
        switch feature {
        case .aiAssistant: return "sparkles"
        case .todaysInsight: return "lightbulb.fill"
        case .smartPredictions: return "brain.head.profile"
        case .cryInsights: return "waveform"
        case .advancedAnalytics: return "chart.bar"
        }
    }

    private func whyHelpfulText(for feature: ProFeature) -> String {
        switch feature {
        case .aiAssistant:
            return "Get personalized guidance and answers to your parenting questions, powered by AI."
        case .todaysInsight:
            return "Receive daily personalized insights based on your baby's patterns and needs."
        case .smartPredictions:
            return "Get personalized nap and feed predictions based on your baby's unique patterns, not generic schedules."
        case .cryInsights:
            return "Understand what your baby's cries might mean and get gentle guidance on how to respond."
        case .advancedAnalytics:
            return "See detailed patterns in your baby's sleep, feeding, and diaper data to share with your pediatrician."
        }
    }
}

struct ProSubscriptionView: View {
    @StateObject private var proService = ProSubscriptionService.shared
    @Environment(\.dismiss) var dismiss
    @State private var selectedProductID: String?
    @State private var isPurchasing = false
    @State private var showRestoreAlert = false
    @State private var restoreMessage = ""
    @State private var purchaseError: String?
    @State private var showPurchaseError = false
    @State private var showTrialStarted = false
    @State private var isLoadingProducts = false
    @State private var productLoadError: String?

    private var proFeatures: [ProFeature] {
        ProFeature.allCases.filter { proService.requiresPro($0) }
    }

    private var isTrialActive: Bool {
        proService.trialDaysRemaining != nil && proService.trialDaysRemaining! > 0
    }

    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacingLG) {
                    headerView
                    planComparisonView
                    featuresListView
                    pricingView
                    if !proService.isProUser {
                        actionButtons
                    }
                }
                .padding(.bottom, .spacingXL)
            }
            .background(Color.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("✕") {
                        dismiss()
                    }
                    .font(.title2)
                    .foregroundColor(.mutedForeground)
                }
            }
            .onAppear {
                Task {
                    await Analytics.shared.logPaywallViewed(source: "settings")
                    await loadProductsIfNeeded()
                }
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: .spacingSM) {
            Image(systemName: "star.fill")
                .font(.system(size: 60))
                .foregroundColor(.primary)
            
            Text("Unlock Nuzzle Pro")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Less chaos. Smarter naps. Clear picture of your baby's day.")
                .font(.subheadline)
                .foregroundColor(.mutedForeground)
                .multilineTextAlignment(.center)

            if isTrialActive {
                HStack(spacing: .spacingXS) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.primary)
                    Text("\(proService.trialDaysRemaining!) days left in trial")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                .padding(.vertical, .spacingXS)
                .padding(.horizontal, .spacingSM)
                .background(Color.primary.opacity(0.1))
                .cornerRadius(.radiusSM)
            } else {
                HStack(spacing: .spacingXS) {
                    ForEach(0..<5) { _ in
                        Image(systemName: "star.fill")
                            .foregroundColor(.primary)
                            .font(.caption)
                    }
                    Text("4.8 • 1,200+ parents")
                        .font(.caption)
                        .foregroundColor(.mutedForeground)
                }
                .padding(.vertical, .spacingXS)
            }
        }
        .padding(.top, .spacingXL)
    }
    
    private var planComparisonView: some View {
        VStack(spacing: .spacingMD) {
            Text("Compare Plans")
                .font(.headline)
                .foregroundColor(.foreground)

            HStack(alignment: .top, spacing: .spacingMD) {
                // Free Column
                VStack(alignment: .leading, spacing: .spacingSM) {
                    Text("Free")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.foreground)

                    VStack(alignment: .leading, spacing: 4) {
                        BulletPoint("Up to 100 events")
                        BulletPoint("Basic nap suggestions by age")
                        BulletPoint("Today Status overview")
                        BulletPoint("History & search")
                        BulletPoint("Manual reminders")
                        BulletPoint("3 free Cry Insights")
                    }
                    .font(.caption)
                    .foregroundColor(.mutedForeground)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Pro Column
                VStack(alignment: .leading, spacing: .spacingSM) {
                    HStack(spacing: .spacingXS) {
                        Text("Pro")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.foreground)
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        BulletPoint("Everything in Free")
                        BulletPoint("Unlimited events")
                        BulletPoint("Smart predictions from baby's patterns")
                        BulletPoint("Unlimited Cry Insights")
                        BulletPoint("Family sharing")
                        BulletPoint("Weekly patterns summary")
                    }
                    .font(.caption)
                    .foregroundColor(.foreground)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.spacingMD)
        .background(Color.surface)
        .cornerRadius(.radiusMD)
        .padding(.horizontal, .spacingMD)
    }
    
    private var featuresListView: some View {
        VStack(alignment: .leading, spacing: .spacingMD) {
            FeatureRow(
                title: "Smarter naps with AI wake-window guidance",
                description: "Personalized nap predictions based on your baby's unique patterns, not just generic schedules"
            )
            FeatureRow(
                title: "Cry analysis (beta) with gentle tips",
                description: "Record your baby's cry and get insights into what they might need"
            )
            FeatureRow(
                title: "Today's insight and AI assistant for patterns in your baby's day",
                description: "Personalized recommendations and AI-powered assistance for parenting questions"
            )
            FeatureRow(
                title: "Smarter reminders that adapt to your baby's patterns (Pro)",
                description: "Reminders adjust based on your baby's actual feeding and sleeping patterns, not just generic schedules"
            )
        }
        .padding(.spacingMD)
        .background(Color.surface)
        .cornerRadius(.radiusLG)
        .padding(.horizontal, .spacingMD)
    }
    
    private struct FeatureRow: View {
        let title: String
        let description: String
        
        var body: some View {
            HStack(alignment: .top, spacing: .spacingMD) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.primary)
                    .padding(.top, 2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.mutedForeground)
                }
            }
        }
    }
    
    private var pricingView: some View {
        Group {
            if !proService.isProUser {
                VStack(spacing: .spacingMD) {
                    if isLoadingProducts {
                        ProgressView("Loading subscription options...")
                            .padding(.spacingXL)
                    } else if let error = productLoadError {
                        VStack(spacing: .spacingSM) {
                            Text("Unable to load subscription options")
                                .font(.headline)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.mutedForeground)
                            Button("Retry") {
                                Task {
                                    await loadProductsIfNeeded()
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.spacingXL)
                    } else if proService.getProducts().isEmpty {
                        VStack(spacing: .spacingSM) {
                            Text("No subscription options available")
                                .font(.headline)
                            Text("Please check your internet connection and try again")
                                .font(.caption)
                                .foregroundColor(.mutedForeground)
                            Button("Retry") {
                                Task {
                                    await loadProductsIfNeeded()
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.spacingXL)
                    } else {
                        ForEach(proService.getProducts(), id: \.id) { product in
                            SubscriptionOptionCard(
                                product: product,
                                isSelected: selectedProductID == product.id,
                                onSelect: {
                                    selectedProductID = product.id
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, .spacingMD)
                .onAppear {
                    // Auto-select first product if none selected and products are available
                    if selectedProductID == nil, !proService.getProducts().isEmpty {
                        selectedProductID = proService.getProducts().first?.id
                    }
                }
            } else {
                proStatusView
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: .spacingMD) {
            PrimaryButton(
                "Subscribe",
                icon: "star.fill"
            ) {
                guard let productID = selectedProductID else {
                    purchaseError = "Please select a subscription plan"
                    showPurchaseError = true
                    return
                }
                
                Task {
                    isPurchasing = true
                    purchaseError = nil
                    
                    // Ensure products are loaded
                    if proService.getProducts().isEmpty {
                        await loadProductsIfNeeded()
                    }
                    
                    let success = await proService.purchase(productID: productID)
                    isPurchasing = false
                    
                    if success {
                        dismiss()
                    } else {
                        purchaseError = "Purchase failed. Please check your payment method and try again."
                        showPurchaseError = true
                    }
                }
            }
            .disabled(selectedProductID == nil || isPurchasing || isLoadingProducts || proService.getProducts().isEmpty)
            .overlay {
                if isPurchasing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
            .padding(.horizontal, .spacingMD)
            
            HStack(spacing: .spacingMD) {
                Button("Restore Purchases") {
                    Task {
                        let restored = await proService.restorePurchases()
                        restoreMessage = restored
                            ? "Purchases restored successfully"
                            : "No purchases found to restore"
                        showRestoreAlert = true
                    }
                }
                .font(.subheadline)
                .foregroundColor(.mutedForeground)
                
                Button("Maybe Later") {
                    dismiss()
                }
                .font(.subheadline)
                .foregroundColor(.mutedForeground)
            }
            .padding(.spacingMD)
        }
    }
    
    private var proStatusView: some View {
        VStack(spacing: .spacingMD) {
            CardView(variant: .emphasis) {
                VStack(spacing: .spacingSM) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.primary)
                    Text("You're a Pro!")
                        .font(.headline)
                    Text("Thank you for supporting Nestling")
                        .font(.subheadline)
                        .foregroundColor(.mutedForeground)
                }
                .padding(.spacingMD)
            }
            
            CardView(variant: .default) {
                VStack(alignment: .leading, spacing: .spacingSM) {
                    Text("Subscription Details")
                        .font(.headline)
                    HStack {
                        Text("Plan:")
                            .foregroundColor(.mutedForeground)
                        Spacer()
                        Text(proService.getProducts().first(where: { $0.id.contains("monthly") })?.displayName ?? "Monthly")
                            .foregroundColor(.foreground)
                    }
                    Button("Manage Subscription") {
                        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .padding(.top, .spacingXS)
                }
                .padding(.spacingMD)
            }
        }
        .padding(.horizontal, .spacingMD)
        .alert("Purchase Error", isPresented: $showPurchaseError) {
            Button("OK") { }
        } message: {
            Text(purchaseError ?? "An unknown error occurred")
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadProductsIfNeeded() async {
        isLoadingProducts = true
        productLoadError = nil
        
        do {
            await proService.loadProducts()
            
            // Auto-select first product if none selected
            if selectedProductID == nil, !proService.getProducts().isEmpty {
                await MainActor.run {
                    selectedProductID = proService.getProducts().first?.id
                }
            }
            
            if proService.getProducts().isEmpty {
                productLoadError = "No subscription products found. Please contact support."
            }
        } catch {
            productLoadError = error.localizedDescription
        }
        
        isLoadingProducts = false
    }
}
struct TrialOptionCard: View {
    let days: Int
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: .spacingXS) {
                        Text("Free Trial")
                            .font(.headline)
                        Text("✨")
                            .font(.subheadline)
                    }

                    Text("Try Pro for \(days) days, no commitment")
                        .font(.caption)
                        .foregroundColor(.mutedForeground)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Free")
                        .font(.headline)
                        .foregroundColor(.success)

                    Text("Then $4.99/mo")
                        .font(.caption)
                        .foregroundColor(.mutedForeground)
                }

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .primary : .mutedForeground)
            }
            .padding(.spacingMD)
            .background(isSelected ? Color.primary.opacity(0.1) : Color.surface)
            .cornerRadius(.radiusMD)
            .overlay(
                RoundedRectangle(cornerRadius: .radiusMD)
                    .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SubscriptionOptionCard: View {
    let product: Product
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(.headline)

                    Text(product.description)
                        .font(.caption)
                        .foregroundColor(.mutedForeground)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: .spacingXS) {
                        Text(product.displayPrice)
                            .font(.headline)

                        if product.id.contains("yearly") {
                            Text("✨")
                                .font(.caption)
                        }
                    }

                    if product.id.contains("yearly") {
                        VStack(spacing: 2) {
                            Text("7-day free trial")
                                .font(.caption)
                                .foregroundColor(.primary)
                            Text("Best value")
                                .font(.caption)
                                .foregroundColor(.success)
                        }
                    }
                }

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .primary : .mutedForeground)
            }
            .padding(.spacingMD)
            .background(isSelected ? Color.primary.opacity(0.1) : Color.surface)
            .cornerRadius(.radiusMD)
            .overlay(
                RoundedRectangle(cornerRadius: .radiusMD)
                    .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct BulletPoint: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        HStack(alignment: .top, spacing: .spacingSM) {
            Text("•")
                .foregroundColor(.primary)
                .font(.body)
            Text(text)
                .foregroundColor(.foreground)
                .font(.body)
                .multilineTextAlignment(.leading)
        }
    }
}

private struct StatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: .spacingXS) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.foreground)
            Text(label)
                .font(.caption)
                .foregroundColor(.mutedForeground)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ProSubscriptionView()
}

