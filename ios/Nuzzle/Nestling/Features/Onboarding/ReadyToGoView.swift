import SwiftUI

struct ReadyToGoView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @State private var showConfetti = false
    
    private var celebrationsEnabled: Bool {
        UserDefaults.standard.object(forKey: "celebrationsEnabled") as? Bool ?? true
    }
    
    var body: some View {
        VStack(spacing: .spacing2XL) {
            Spacer()
            
            // Success icon with subtle animation
            ZStack {
                Circle()
                    .fill(Color.primary.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.primary)
                    .scaleEffect(showConfetti ? 1.0 : 0.8)
            }
            
            VStack(spacing: .spacingMD) {
                Text("You're all set!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.foreground)
                
                Text("Let's log your first feed and start tracking \(coordinator.babyName.isEmpty ? "your baby's" : "\(coordinator.babyName)'s") day")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.mutedForeground)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, .spacingLG)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Quick tips
            VStack(alignment: .leading, spacing: .spacingMD) {
                TipRow(icon: "bolt.fill", text: "Log in seconds with Quick Actions")
                TipRow(icon: "brain.head.profile", text: "Get smart nap predictions")
                TipRow(icon: "clock.arrow.circlepath", text: "See patterns over time")
            }
            .padding(.spacingLG)
            .background(Color.surface.opacity(0.5))
            .cornerRadius(.radiusLG)
            .padding(.horizontal, .spacingLG)
            
            Spacer()
            
            VStack(spacing: .spacingSM) {
                Button(action: {
                    Haptics.medium()
                    coordinator.completeOnboarding()
                }) {
                    Text("Start Tracking")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.primary)
                        .cornerRadius(.radiusXL)
                        .shadow(color: Color.primary.opacity(0.4), radius: 16, x: 0, y: 8)
                }
            }
            .padding(.horizontal, .spacingLG)
            .padding(.bottom, .spacing2XL)
        }
        .background(Color.background)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                if celebrationsEnabled {
                    showConfetti = true
                }
            }
        }
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: .spacingMD) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.primary)
                .frame(width: 24, height: 24)
            
            Text(text)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.foreground)
            
            Spacer()
        }
    }
}

#Preview {
    let coordinator = OnboardingCoordinator(dataStore: InMemoryDataStore())
    coordinator.babyName = "Emma"
    return ReadyToGoView(coordinator: coordinator)
}

