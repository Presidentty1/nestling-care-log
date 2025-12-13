import SwiftUI

struct FirstLogView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @EnvironmentObject var environment: AppEnvironment
    @State private var showAnimation = false
    @State private var hasLogged = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: .spacingXL) {
                VStack(spacing: .spacingSM) {
                    Text("Try Your First Log")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.foreground)
                    
                    Text("See how fast and easy it is to track")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.mutedForeground)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, .spacingXL)
                
                Spacer()
                
                // Big interactive button
                Button(action: {
                    guard !hasLogged else { return }
                    Haptics.success()
                    showAnimation = true
                    hasLogged = true
                    
                    // Actually log a feed event (requires the baby to exist in the store)
                    Task {
                        do {
                            guard let baby = coordinator.createBabyFromCurrentData() else { return }
                            
                            let event = Event(
                                babyId: baby.id,
                                type: .feed,
                                subtype: "bottle",
                                amount: 120,
                                unit: "ml",
                                note: nil
                            )
                            
                            try await environment.dataStore.addEvent(event)
                            
                            // Analytics
                            await Analytics.shared.log("first_log_completed", parameters: [
                                "event_type": "feed",
                                "source": "onboarding"
                            ])
                        } catch {
                            logger.debug("Error logging first event: \(error)")
                        }
                        
                        // Continue to next onboarding step after a short delight delay
                        await MainActor.run {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                coordinator.next()
                            }
                        }
                    }
                }) {
                    VStack(spacing: .spacingMD) {
                        if showAnimation {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            Image(systemName: "drop.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }
                        
                        Text(hasLogged ? "Logged!" : "Log a Feed")
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
                .disabled(hasLogged)
                
                Text(hasLogged ? "Nice. You're set up." : "Tap to log your first feeding.\nIt's just this simple.")
                    .font(.body)
                    .foregroundColor(.mutedForeground)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                if !hasLogged {
                    Button("Skip for now") {
                        Haptics.light()
                        coordinator.next()
                    }
                    .font(.subheadline)
                    .foregroundColor(.mutedForeground)
                    .padding(.top, .spacingMD)
                }
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, .spacingLG)
            .padding(.bottom, .spacing2XL)
        }
        .background(Color.background)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showAnimation)
        .onAppear {
            Task {
                await Analytics.shared.logOnboardingStepViewed(step: "first_log")
            }
        }
    }
}

#Preview {
    FirstLogView(coordinator: OnboardingCoordinator(dataStore: InMemoryDataStore()))
}
