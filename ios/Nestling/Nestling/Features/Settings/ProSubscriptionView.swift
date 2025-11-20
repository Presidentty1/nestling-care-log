import SwiftUI
import StoreKit

struct ProSubscriptionView: View {
    @StateObject private var proService = ProSubscriptionService.shared
    @Environment(\.dismiss) var dismiss
    @State private var selectedProductID: String?
    @State private var isPurchasing = false
    @State private var showRestoreAlert = false
    @State private var restoreMessage = ""
    @State private var purchaseError: String?
    @State private var showPurchaseError = false
    
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
                        
                        Text("Unlock Nestling Pro")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Make the guesswork even easier")
                            .font(.subheadline)
                            .foregroundColor(.mutedForeground)
                    }
                    .padding(.top, .spacingXL)

                    // Free vs Pro Comparison
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
                                    BulletPoint("Unlimited logging")
                                    BulletPoint("Basic nap suggestions by age")
                                    BulletPoint("Today Status overview")
                                    BulletPoint("History & search")
                                    BulletPoint("Manual reminders")
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
                                    BulletPoint("Smart predictions from baby's patterns")
                                    BulletPoint("Cry Insights (Beta)")
                                    BulletPoint("Adaptive reminders")
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

                    // Features List - Updated per feedback
                    VStack(alignment: .leading, spacing: .spacingMD) {
                        // Bullet 1: Smarter nap & feed predictions
                        HStack(alignment: .top, spacing: .spacingMD) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.primary)
                                .padding(.top, 2)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Smarter nap & feed predictions tuned to your baby")
                                    .font(.headline)
                                
                                Text("Personalized suggestions based on your baby's unique patterns, not just generic wake windows")
                                    .font(.caption)
                                    .foregroundColor(.mutedForeground)
                            }
                        }
                        
                        // Bullet 2: Cry Insights
                        HStack(alignment: .top, spacing: .spacingMD) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.primary)
                                .padding(.top, 2)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Cry Insights to help decode fussiness (Beta)")
                                    .font(.headline)
                                
                                Text("Record your baby's cry and get insights into what they might need")
                                    .font(.caption)
                                    .foregroundColor(.mutedForeground)
                            }
                        }
                        
                        // Bullet 3: Richer patterns
                        HStack(alignment: .top, spacing: .spacingMD) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.primary)
                                .padding(.top, 2)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Richer patterns over time to share with your pediatrician")
                                    .font(.headline)
                                
                                Text("Detailed analytics and insights to track your baby's development")
                                    .font(.caption)
                                    .foregroundColor(.mutedForeground)
                            }
                        }
                        
                        // Bullet 4: Smarter reminders
                        HStack(alignment: .top, spacing: .spacingMD) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.primary)
                                .padding(.top, 2)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Smarter reminders that adapt to your baby's patterns (Pro)")
                                    .font(.headline)
                                
                                Text("Reminders adjust based on your baby's actual feeding and sleeping patterns, not just generic schedules")
                                    .font(.caption)
                                    .foregroundColor(.mutedForeground)
                            }
                        }
                    }
                    .padding(.spacingMD)
                    .background(Color.surface)
                    .cornerRadius(.radiusLG)
                    .padding(.horizontal, .spacingMD)
                    
                    // Subscription Options
                    if !proService.isProUser {
                        VStack(spacing: .spacingMD) {
                            // Auto-select first product if none selected
                            if selectedProductID == nil && !proService.getProducts().isEmpty {
                                let _ = {
                                    selectedProductID = proService.getProducts().first?.id
                                }()
                            }
                            
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
                            selectedProductID?.contains("trial") == true ? "Start Trial" : "Subscribe",
                            icon: "star.fill"
                        ) {
                            if let productID = selectedProductID {
                                Task {
                                    isPurchasing = true
                                    purchaseError = nil

                                    print("[DEBUG] Starting purchase for product: \(productID)")
                                    print("[DEBUG] Available products: \(proService.getProducts().map { $0.id })")

                                    let success = await proService.purchase(productID: productID)
                                    isPurchasing = false

                                    print("[DEBUG] Purchase result: \(success)")

                                    if success {
                                        dismiss()
                                    } else {
                                        // Purchase failed - show error
                                        purchaseError = "Purchase failed. Please check your payment method and try again."
                                        showPurchaseError = true
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
                        
                        HStack(spacing: .spacingMD) {
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
                            
                            // Maybe Later
                            Button("Maybe Later") {
                                dismiss()
                            }
                            .font(.subheadline)
                            .foregroundColor(.mutedForeground)
                        }
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
            .onAppear {
                // Track paywall viewed analytics
                Task {
                    await Analytics.shared.logPaywallViewed(source: "settings")
                }
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
        .alert("Purchase Error", isPresented: $showPurchaseError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(purchaseError ?? "An unknown error occurred.")
        }
        .task {
            print("[DEBUG] ProSubscriptionView loaded")
            print("[DEBUG] Products available: \(proService.getProducts().count)")
            for product in proService.getProducts() {
                print("[DEBUG] Product: \(product.id) - \(product.displayName) - \(product.displayPrice)")
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

#Preview {
    ProSubscriptionView()
}

