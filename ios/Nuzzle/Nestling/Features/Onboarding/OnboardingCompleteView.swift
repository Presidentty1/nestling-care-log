import SwiftUI

struct OnboardingCompleteView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @State private var showCheckmark = false
    
    var body: some View {
        VStack(spacing: .spacing2XL) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.primary.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                if showCheckmark {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.primary)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            
            VStack(spacing: .spacingSM) {
                Text("You're all set!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.foreground)
                
                Text("Let's start tracking \(babyName)'s day")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.mutedForeground)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            Button(action: {
                Haptics.light()
                coordinator.completeOnboarding()
            }) {
                Text("Go to Today")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.primary)
                    .cornerRadius(.radiusXL)
                    .shadow(color: Color.primary.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            .padding(.horizontal, .spacingLG)
            .padding(.bottom, .spacing2XL)
        }
        .background(Color.background)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                showCheckmark = true
            }
            
            Task {
                await Analytics.shared.logOnboardingStepViewed(step: "complete")
            }
        }
    }
    
    private var babyName: String {
        coordinator.babyName.isEmpty ? "your baby" : coordinator.babyName
    }
}

#Preview {
    OnboardingCompleteView(coordinator: OnboardingCoordinator(dataStore: InMemoryDataStore()))
}

