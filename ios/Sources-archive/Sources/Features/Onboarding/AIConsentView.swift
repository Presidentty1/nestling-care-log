import SwiftUI

struct AIConsentView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    
    var body: some View {
        ScrollView {
            VStack(spacing: .spacingLG) {
                VStack(spacing: .spacingMD) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 60))
                        .foregroundColor(.primary)
                    
                    Text("AI-Powered Features")
                        .font(.headline)
                        .foregroundColor(.foreground)
                    
                    Text("Enable AI features to get smart predictions for feeds and naps. Your data is used only to improve predictions and is never shared with third parties.")
                        .font(.body)
                        .foregroundColor(.mutedForeground)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, .spacingMD)
                }
                .padding(.top, .spacing2XL)
                
                CardView {
                    VStack(alignment: .leading, spacing: .spacingMD) {
                        Toggle("Enable AI Data Sharing", isOn: $coordinator.aiDataSharingEnabled)
                        
                        if coordinator.aiDataSharingEnabled {
                            Text("AI features will help predict nap windows and feeding times based on your baby's patterns.")
                                .font(.caption)
                                .foregroundColor(.mutedForeground)
                        } else {
                            Text("You can still use all core features. AI predictions will be disabled.")
                                .font(.caption)
                                .foregroundColor(.mutedForeground)
                        }
                    }
                }
                .padding(.horizontal, .spacingMD)
                
                MedicalDisclaimer(variant: .ai)
                    .padding(.horizontal, .spacingMD)
                
                VStack(spacing: .spacingSM) {
                    PrimaryButton("Continue") {
                        coordinator.next()
                    }
                    .padding(.horizontal, .spacingMD)
                    
                    Button("Skip") {
                        coordinator.skip()
                    }
                    .foregroundColor(.mutedForeground)
                }
                .padding(.bottom, .spacing2XL)
            }
        }
        .background(NuzzleTheme.background)
    }
}

#Preview {
    AIConsentView(coordinator: OnboardingCoordinator(dataStore: InMemoryDataStore()))
}


