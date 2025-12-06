import SwiftUI

struct FirstLogView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @State private var showAnimation = false
    
    var body: some View {
        OnboardingContainer(
            title: "Try Your First Log",
            subtitle: "See how fast and easy it is to track.",
            step: 7,
            totalSteps: 8,
            content: {
            VStack(spacing: .spacingXL) {
                Spacer()
                
                // Big interactive button
                Button(action: {
                    Haptics.success()
                    showAnimation = true
                    
                    // Delay to show animation before proceeding
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        coordinator.next()
                    }
                }) {
                    VStack(spacing: .spacingMD) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                        
                        Text("Log a Feed")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .background(Color.eventFeed)
                    .cornerRadius(.radiusXL)
                    .shadow(color: Color.eventFeed.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .scaleEffect(showAnimation ? 0.95 : 1.0)
                .overlay(
                    ZStack {
                        if showAnimation {
                            // Success checkmark
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.white)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                )
                
                Text("Tap to simulate logging a feeding.\nIn the app, it's just this simple.")
                    .font(.body)
                    .foregroundColor(.mutedForeground)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button("Preview Sample Data") {
                    coordinator.loadSampleData()
                }
                .font(.subheadline)
                .foregroundColor(.primary)
                .padding(.top, .spacingMD)
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showAnimation)
            },
            primaryTitle: "Continue",
            primaryAction: {
                coordinator.next()
            },
            primaryDisabled: false,
            secondaryTitle: "Skip for now",
            secondaryAction: {
                coordinator.next()
            }
        )
    }
}

#Preview {
    FirstLogView(coordinator: OnboardingCoordinator(dataStore: InMemoryDataStore()))
}
