import SwiftUI

struct WelcomeView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    
    var body: some View {
        VStack(spacing: .spacing2XL) {
            Spacer()
            
            Image(systemName: "heart.fill")
                .font(.system(size: 80))
                .foregroundColor(.primary)
            
            VStack(spacing: .spacingMD) {
                Text("Get 2 More Hours of Sleep")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.foreground)
                    .multilineTextAlignment(.center)
                
                Text("Track baby care in 2 taps. Predict naps. Sync with partner.")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.mutedForeground)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, .spacingLG)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Trust signals
                HStack(spacing: .spacingLG) {
                    TrustBadge(icon: "lock.shield.fill", text: "Privacy First")
                    TrustBadge(icon: "clock.fill", text: "Setup < 60s")
                    TrustBadge(icon: "heart.fill", text: "No Ads Ever")
                }
                .padding(.top, .spacingSM)
                
                Text("Free forever • Premium from $4.99/mo")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.mutedForeground.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, .spacingMD)
                    .padding(.top, 4)
            }
            
            Spacer()
            
            VStack(spacing: .spacingSM) {
                Button(action: {
                    Haptics.light()
                    coordinator.next()
                }) {
                    Text("Let's Go!")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.primary)
                        .cornerRadius(.radiusXL)
                        .shadow(color: Color.primary.opacity(0.3), radius: 12, x: 0, y: 6)
                }
                
                Button("Maybe later") {
                    Haptics.light()
                    coordinator.skip()
                }
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.mutedForeground)
            }
            .padding(.horizontal, .spacingMD)
            .padding(.bottom, .spacing2XL)
        }
        .background(Color.background)
    }
}

// MARK: - Trust Badge Component
struct TrustBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.primary)
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.mutedForeground)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    WelcomeView(coordinator: OnboardingCoordinator(dataStore: InMemoryDataStore()))
}

