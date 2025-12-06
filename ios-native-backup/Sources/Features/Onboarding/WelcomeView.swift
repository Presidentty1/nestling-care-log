import SwiftUI

struct WelcomeView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @State private var showSampleData = false
    @State private var showGuestMode = false

    var body: some View {
        OnboardingContainer(
            title: "Welcome to Nuzzle",
            subtitle: "Know what happened last and what's coming next. Track feeds, sleep, diapers, and more with just a tap.",
            step: 1,
            totalSteps: 2,
            content: {
                VStack(spacing: .spacingLG) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 48))
                        .foregroundColor(NuzzleTheme.primary)
                        .padding(.top, .spacingSM)

                    // Account options
                    VStack(spacing: .spacingMD) {
                        // Sign in with Apple/Google would go here if implemented

                        // Guest mode option
                        VStack(spacing: .spacingSM) {
                            Text("No account needed")
                                .font(.body)
                                .foregroundColor(NuzzleTheme.textSecondary)

                            Button(action: {
                                showGuestMode = true
                                // Analytics for guest mode selection
                                Task {
                                    await Analytics.shared.log("onboarding_guest_mode_selected")
                                }
                            }) {
                                HStack(spacing: .spacingSM) {
                                    Image(systemName: "person.fill.questionmark")
                                        .foregroundColor(NuzzleTheme.primary)
                                    Text("Continue without account")
                                        .font(.body.bold())
                                        .foregroundColor(NuzzleTheme.primary)
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.spacingMD)
                                .background(NuzzleTheme.surface)
                                .cornerRadius(.radiusMD)
                            }
                            .accessibilityLabel("Continue without account to try Nuzzle")

                            Text("Unlimited logging • Sync/backup requires account")
                                .font(.caption)
                                .foregroundColor(NuzzleTheme.textTertiary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, .spacingMD)
                }
            },
            primaryTitle: "Get Started",
            primaryAction: { coordinator.next() }
        )
        .sheet(isPresented: $showSampleData) {
            SampleDataIntroView(onLoadSample: {
                coordinator.loadSampleData = true
                showSampleData = false
                coordinator.next()
            })
        }
        .sheet(isPresented: $showGuestMode) {
            GuestModeIntroView(onContinue: {
                // Set up guest mode and complete onboarding
                coordinator.primaryGoal = "just_logging" // Default goal for guest users
                coordinator.babyName = "My Baby" // Default name
                // Keep default dateOfBirth
                coordinator.skip() // Complete onboarding with guest setup
            })
        }
    }
}

#Preview {
    WelcomeView(coordinator: OnboardingCoordinator(dataStore: InMemoryDataStore()))
}


