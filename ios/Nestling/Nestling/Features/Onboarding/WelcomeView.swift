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
                Text("Welcome to Nestling")
                    .font(.headline)
                    .foregroundColor(.foreground)
                
                Text("Know what happened last and what's coming next.")
                    .font(.body)
                    .foregroundColor(.mutedForeground)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, .spacingMD)
                
                Text("Track feeds, sleep, diapers, and more with just a tap.")
                    .font(.body)
                    .foregroundColor(.mutedForeground)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, .spacingMD)
                
                Text("Takes about a minute. You can skip anytime.")
                    .font(.caption)
                    .foregroundColor(.mutedForeground.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, .spacingMD)
                    .padding(.top, 4)
            }
            
            Spacer()
            
            VStack(spacing: .spacingSM) {
                PrimaryButton("Get Started") {
                    coordinator.next()
                }
                
                Button("Skip") {
                    coordinator.skip()
                }
                .foregroundColor(.mutedForeground)
            }
            .padding(.horizontal, .spacingMD)
            .padding(.bottom, .spacing2XL)
        }
        .background(Color.background)
    }
}

#Preview {
    WelcomeView(coordinator: OnboardingCoordinator(dataStore: InMemoryDataStore()))
}

