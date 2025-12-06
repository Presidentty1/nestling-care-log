import SwiftUI

struct PreferencesAndConsentView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    
    var body: some View {
        ScrollView {
            VStack(spacing: .spacingXL) {
                VStack(spacing: .spacingSM) {
                    Text("Smart Predictions")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.foreground)
                    
                    Text("Get AI-powered nap predictions and feeding insights")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.mutedForeground)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, .spacingXL)
                
                VStack(alignment: .center, spacing: .spacingXL) {
                    // Icon
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 64))
                        .foregroundColor(.primary)
                        .padding(.top, .spacingLG)
                    
                    // Description
                    Text("Get suggested nap windows and feeding times based on your baby's unique patterns")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.mutedForeground)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Features
                    VStack(alignment: .leading, spacing: .spacingMD) {
                        FeatureRow(icon: "moon.zzz.fill", text: "Predict next nap time")
                        FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Track patterns over time")
                        FeatureRow(icon: "lightbulb.fill", text: "Get personalized insights")
                    }
                    .padding(.spacingLG)
                    .background(Color.surface.opacity(0.5))
                    .cornerRadius(.radiusLG)
                    
                    // Toggle
                    Toggle(isOn: $coordinator.aiDataSharingEnabled) {
                        Text("Enable Smart Predictions")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .tint(.primary)
                    .padding()
                    .background(Color.surface)
                    .cornerRadius(.radiusMD)
                    
                    // Disclaimer
                    HStack(spacing: .spacingSM) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundColor(.mutedForeground)
                        
                        Text("Provides general guidance, not medical advice. Consult your pediatrician.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.mutedForeground)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.spacingMD)
                    .background(Color.surface.opacity(0.5))
                    .cornerRadius(.radiusSM)
                }
                .padding(.horizontal, .spacingLG)
                
                Spacer(minLength: 40)
                
                VStack(spacing: .spacingSM) {
                    Button(action: {
                        Haptics.light()
                        coordinator.next()
                    }) {
                        Text("Continue")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.primary)
                            .cornerRadius(.radiusXL)
                            .shadow(color: Color.primary.opacity(0.3), radius: 12, x: 0, y: 6)
                    }
                    
                    Button("Skip") {
                        Haptics.light()
                        coordinator.skip()
                    }
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.mutedForeground)
                }
                .padding(.horizontal, .spacingLG)
                .padding(.bottom, .spacing2XL)
            }
        }
        .background(Color.background)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: .spacingMD) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.primary)
                .frame(width: 28, height: 28)
            
            Text(text)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.foreground)
            
            Spacer()
        }
    }
}

#Preview {
    PreferencesAndConsentView(coordinator: OnboardingCoordinator(dataStore: InMemoryDataStore()))
}

