import SwiftUI
import StoreKit

struct ProTrialView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @StateObject private var proService = ProSubscriptionService.shared
    @State private var selectedProductID: String?
    @State private var isPurchasing = false
    @State private var showProView = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: .spacingLG) {
                // Header
                VStack(spacing: .spacingMD) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.primary)
                    
                    Text("Start Your Free Trial")
                        .font(.headline)
                        .foregroundColor(.foreground)
                    
                    Text("Unlock advanced features to help you understand your baby better")
                        .font(.body)
                        .foregroundColor(.mutedForeground)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, .spacingMD)
                }
                .padding(.top, .spacing2XL)
                
                // Features Highlights
                CardView(variant: .emphasis) {
                    VStack(alignment: .leading, spacing: .spacingMD) {
                        HStack(spacing: .spacingMD) {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(.primary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Advanced Analytics")
                                    .font(.body)
                                    .fontWeight(.medium)
                                Text("Detailed charts and insights")
                                    .font(.caption)
                                    .foregroundColor(.mutedForeground)
                            }
                        }
                        
                        HStack(spacing: .spacingMD) {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(.primary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Family Sharing")
                                    .font(.body)
                                    .fontWeight(.medium)
                                Text("Share with partners and caregivers")
                                    .font(.caption)
                                    .foregroundColor(.mutedForeground)
                            }
                        }
                        
                        HStack(spacing: .spacingMD) {
                            Image(systemName: "waveform.path.ecg")
                                .foregroundColor(.primary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Cry Analysis")
                                    .font(.body)
                                    .fontWeight(.medium)
                                Text("AI-powered cry insights")
                                    .font(.caption)
                                    .foregroundColor(.mutedForeground)
                            }
                        }
                        
                        HStack(spacing: .spacingMD) {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.primary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Smart Predictions")
                                    .font(.body)
                                    .fontWeight(.medium)
                                Text("Know when baby needs sleep or food")
                                    .font(.caption)
                                    .foregroundColor(.mutedForeground)
                            }
                        }
                    }
                }
                .padding(.horizontal, .spacingMD)
                
                // Subscription Options (simplified for onboarding)
                if !proService.isProUser {
                    VStack(spacing: .spacingMD) {
                        // Auto-select first product if none selected
                        if selectedProductID == nil && !proService.getProducts().isEmpty {
                            let _ = {
                                selectedProductID = proService.getProducts().first?.id
                            }()
                        }
                        
                        if let firstProduct = proService.getProducts().first {
                            CardView {
                                VStack(alignment: .leading, spacing: .spacingSM) {
                                    HStack {
                                        Text(firstProduct.displayName)
                                            .font(.headline)
                                        
                                        Spacer()
                                        
                                        Text(firstProduct.displayPrice)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                    }
                                    
                                    if firstProduct.id.contains("yearly") {
                                        Text("Save 17% vs monthly")
                                            .font(.caption)
                                            .foregroundColor(.success)
                                    }
                                }
                            }
                            .padding(.horizontal, .spacingMD)
                        }
                    }
                    
                    // Action Buttons
                    VStack(spacing: .spacingSM) {
                        PrimaryButton("Start Free Trial", icon: "star.fill") {
                            if let productID = selectedProductID ?? proService.getProducts().first?.id {
                                Task {
                                    isPurchasing = true
                                    let success = await proService.purchase(productID: productID)
                                    isPurchasing = false
                                    
                                    if success {
                                        coordinator.next()
                                    }
                                }
                            }
                        }
                        .disabled(selectedProductID == nil || isPurchasing || proService.getProducts().isEmpty)
                        .overlay {
                            if isPurchasing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                        }
                        .padding(.horizontal, .spacingMD)
                        
                        Button("Maybe Later") {
                            coordinator.skip()
                        }
                        .font(.subheadline)
                        .foregroundColor(.mutedForeground)
                        .padding(.spacingMD)
                        
                        Button("View All Features") {
                            showProView = true
                        }
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .padding(.horizontal, .spacingMD)
                    }
                } else {
                    // Already Pro
                    PrimaryButton("Continue") {
                        coordinator.next()
                    }
                    .padding(.horizontal, .spacingMD)
                }
                
                // Terms
                Text("Free trial starts today. Cancel anytime in Settings. Subscription auto-renews unless cancelled.")
                    .font(.caption)
                    .foregroundColor(.mutedForeground)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, .spacingMD)
                    .padding(.bottom, .spacingXL)
            }
        }
        .background(Color.background)
        .sheet(isPresented: $showProView) {
            ProSubscriptionView()
        }
    }
}

#Preview {
    ProTrialView(coordinator: OnboardingCoordinator(dataStore: InMemoryDataStore()))
}

