import SwiftUI
import StoreKit

struct ProSubscriptionView: View {
    @StateObject private var proService = ProSubscriptionService.shared
    @Environment(\.dismiss) var dismiss
    @State private var selectedProductID: String?
    @State private var isPurchasing = false
    @State private var showRestoreAlert = false
    @State private var restoreMessage = ""
    
    private var proFeatures: [ProFeature] {
        ProFeature.allCases.filter { proService.requiresPro($0) }
    }
    
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
                        ForEach(proFeatures, id: \.self) { feature in
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
                    .background(Color.surface)
                    .cornerRadius(.radiusLG)
                    .padding(.horizontal, .spacingMD)
                    
                    // Subscription Options
                    if !proService.isProUser {
                        VStack(spacing: .spacingMD) {
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
                        .padding(.horizontal, .spacingMD)
                        
                        // Purchase Button
                        PrimaryButton(
                            "Subscribe",
                            icon: "star.fill"
                        ) {
                            if let productID = selectedProductID {
                                Task {
                                    isPurchasing = true
                                    let success = await proService.purchase(productID: productID)
                                    isPurchasing = false
                                    
                                    if success {
                                        dismiss()
                                    }
                                }
                            }
                        }
                        .disabled(selectedProductID == nil || isPurchasing)
                        .overlay {
                            if isPurchasing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                        }
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
                            Link("Terms of Service", destination: URL(string: "https://nestling.app/terms")!)
                            Text("•")
                            Link("Privacy Policy", destination: URL(string: "https://nestling.app/privacy")!)
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
                    
                    if product.id.contains("yearly") {
                        Text("Save 17%")
                            .font(.caption)
                            .foregroundColor(.success)
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

#Preview {
    ProSubscriptionView()
}

