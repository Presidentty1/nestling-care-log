import SwiftUI

struct WelcomeView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    
    var body: some View {
        ZStack {
            // Warm gradient background
            LinearGradient(
                colors: [Color.creamAccent.opacity(0.3), Color.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: .spacing2XL) {
                Spacer()

                // Replace SF Symbol with custom baby illustration
                Image("WelcomeIllustration")  // Add to Assets
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)

                VStack(spacing: .spacingMD) {
                Text("Less guessing.\nMore calm days.")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.foreground)
                    .multilineTextAlignment(.center)
                
                Text("Log feeds, diapers, and sleep — and get smart nap tips based on your baby.")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.mutedForeground)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, .spacingLG)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Three icon bullets
                VStack(spacing: .spacingMD) {
                    HStack(spacing: .spacingXL) {
                        VStack(spacing: 8) {
                            Image(systemName: "moon.zzz.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.primary)
                            Text("Smart nap\nwindows")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.foreground)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity)
                        
                        VStack(spacing: 8) {
                            Image(systemName: "hand.tap.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.primary)
                            Text("2-tap\nlogging")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.foreground)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity)
                        
                        VStack(spacing: 8) {
                            Image(systemName: "waveform")
                                .font(.system(size: 32))
                                .foregroundColor(.primary)
                            Text("Cry insights\n(beta)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.foreground)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, .spacingLG)
                
                // Badge showing privacy
                HStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.mutedForeground)
                    Text("Private, iCloud-backed")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.mutedForeground)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.surface)
                .cornerRadius(16)
                .padding(.top, .spacingSM)
            }
            
            Spacer()
            
            VStack(spacing: .spacingSM) {
                Button(action: {
                    Haptics.light()
                    // TODO: Analytics.track(.onboardingStarted)
                    coordinator.next()
                }) {
                    Text("Get started (30 seconds)")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.primary)
                        .cornerRadius(.radiusXL)
                        .shadow(color: Color.primary.opacity(0.3), radius: 12, x: 0, y: 6)
                }
                
                Button("Just log for now") {
                    Haptics.light()
                    coordinator.skip()
                }
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.mutedForeground)
            }
            .padding(.horizontal, .spacingMD)
            .padding(.bottom, .spacing2XL)
            }
        }
        .onAppear {
            Task {
                await Analytics.shared.logOnboardingStepViewed(step: "welcome")
            }
        }
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

