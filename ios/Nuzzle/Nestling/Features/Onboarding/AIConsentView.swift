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
                    
                    Text("Turn on Smart Predictions to get suggested nap windows and feeding times based on your baby's patterns. Your data is used only to improve these suggestions and is never sold.")
                        .font(.body)
                        .foregroundColor(.mutedForeground)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, .spacingMD)
                }
                .padding(.top, .spacing2XL)
                
                    CardView {
                    VStack(alignment: .leading, spacing: .spacingMD) {
                        Toggle("Enable Smart Predictions", isOn: $coordinator.aiDataSharingEnabled)
                        
                        if coordinator.aiDataSharingEnabled {
                            Text("AI features will help predict nap windows and feeding times based on your baby's patterns.")
                                .font(.caption)
                                .foregroundColor(.mutedForeground)
                        } else {
                            Text("You can still use all core features. AI predictions will be disabled.")
                                .font(.caption)
                                .foregroundColor(.mutedForeground)
                        }
                        
                        Text("You can change this anytime in Settings → AI & Smart Features.")
                            .font(.caption2)
                            .foregroundColor(.mutedForeground)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, .spacingMD)
                
                MedicalDisclaimer(variant: .ai)
                    .padding(.horizontal, .spacingMD)
                    .scaleEffect(0.95) // Make disclaimer slightly smaller
                
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
        .background(Color.background)
    }
}

#Preview {
    AIConsentView(coordinator: OnboardingCoordinator(dataStore: InMemoryDataStore()))
}

