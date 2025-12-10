import SwiftUI
import StoreKit

struct ProSubscriptionView: View {
    @StateObject private var proService = ProSubscriptionService.shared
    @Environment(\.dismiss) var dismiss
    @State private var selectedProductID: String?
    @State private var isPurchasing = false
    @State private var showRestoreAlert = false
    @State private var restoreMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacingLG) {
                    // Header
                    VStack(spacing: .spacingSM) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.primary)
                        
                        Text("Nestling Pro")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Unlock advanced features")
                            .font(.subheadline)
                            .foregroundColor(.mutedForeground)
                    }
                    .padding(.top, .spacingXL)
                    
                    // Features List
                    VStack(alignment: .leading, spacing: .spacingMD) {
                        ForEach(ProFeature.allCases.filter { proService.requiresPro($0) }, id: \.self) { feature in
                            HStack(spacing: .spacingMD) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.primary)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(feature.displayName)
                                        .font(.headline)
                                    
                                    Text(feature.description)
                                        .font(.caption)
                                        .foregroundColor(.mutedForeground)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.spacingMD)
                    .background(NuzzleTheme.surface)
                    .cornerRadius(.radiusLG)
                    .padding(.horizontal, .spacingMD)
                    
                    // Subscription Options
                    if !proService.isProUser {
                        VStack(spacing: .spacingMD) {
                            ForEach(proService.getOfferings().sorted { (offering1, offering2) -> Bool in
                                // Sort to put yearly first (emphasize annual)
                                if offering1.id.contains("yearly") { return true }
                                if offering2.id.contains("yearly") { return false }
                                return offering1.id < offering2.id
                            }, id: \.id) { offering in
                                RevenueCatOfferingCard(
                                    offering: offering,
                                    isSelected: selectedProductID == offering.id || (selectedProductID == nil && offering.id.contains("yearly")),
                                    onSelect: {
                                        selectedProductID = offering.id
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, .spacingMD)
                        
                        // Purchase Button
                        PrimaryButton(
                            "Subscribe",
                            icon: "star.fill",
                            isLoading: isPurchasing
                        ) {
                            if let packageId = selectedProductID {
                                Task {
                                    isPurchasing = true
                                    let success = await proService.purchase(packageId: packageId)
                                    isPurchasing = false

                                    if success {
                                        dismiss()
                                    }
                                }
                            }
                        }
                        .disabled(selectedProductID == nil || isPurchasing)
                        .padding(.horizontal, .spacingMD)
                        
                        // Restore Purchases
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
                        .padding(.spacingMD)
                    } else {
                        // Already Pro
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
                        .padding(.horizontal, .spacingMD)
                    }
                    
                    // Terms & Privacy
                    VStack(spacing: .spacingSM) {
                        Text("Subscriptions auto-renew unless cancelled. Cancel anytime in Settings.")
                            .font(.caption)
                            .foregroundColor(.mutedForeground)
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: .spacingMD) {
                            Button(action: {
                                AppConfig.validateAndOpenURL(AppConfig.termsOfServiceURL)
                            }) {
                                Text("Terms of Service")
                                    .foregroundColor(NuzzleTheme.primary)
                            }
                            Text("•")
                            Button(action: {
                                AppConfig.validateAndOpenURL(AppConfig.privacyPolicyURL)
                            }) {
                                Text("Privacy Policy")
                                    .foregroundColor(NuzzleTheme.primary)
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.mutedForeground)
                    }
                    .padding(.spacingMD)
                }
                .padding(.bottom, .spacingXL)
            }
            .navigationTitle("Pro Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Restore Purchases", isPresented: $showRestoreAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(restoreMessage)
            }
        }
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
                    Text(product.displayPrice)
                        .font(.headline)

                    // Trial information
                    if let introOffer = product.subscription?.introductoryOffer {
                        Text("Free \(introOffer.period.value) \(introOffer.period.unit.localizedDescription()) trial")
                            .font(.caption)
                            .foregroundColor(.success)
                    } else if product.id.contains("yearly") {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Best value")
                                .font(.caption)
                                .foregroundColor(.success)
                                .fontWeight(.semibold)
                            Text("Save ~44%")
                                .font(.caption)
                                .foregroundColor(.success)
                        }
                    }
                }
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .primary : .mutedForeground)
            }
            .padding(.spacingMD)
            .background(isSelected ? NuzzleTheme.primary.opacity(0.1) : NuzzleTheme.surface)
            .cornerRadius(.radiusMD)
            .overlay(
                RoundedRectangle(cornerRadius: .radiusMD)
                    .stroke(isSelected ? NuzzleTheme.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RevenueCatOfferingCard: View {
    let offering: RevenueCatOffering
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(offering.title)
                            .font(.headline)

                        if offering.isPopular {
                            Text("BEST VALUE")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .cornerRadius(4)
                        }
                    }

                    Text(offering.price)
                        .font(.subheadline)

                    if let savings = offering.savings {
                        Text(savings)
                            .font(.caption)
                            .foregroundColor(.green)
                    }

                    if let trialDays = offering.trialDays {
                        Text("Free \(trialDays)-day trial")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .primary : .mutedForeground)
            }
            .padding(.spacingMD)
            .background(isSelected ? NuzzleTheme.primary.opacity(0.1) : NuzzleTheme.surface)
            .cornerRadius(.radiusMD)
            .overlay(
                RoundedRectangle(cornerRadius: .radiusMD)
                    .stroke(isSelected ? NuzzleTheme.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ProSubscriptionView()
}

