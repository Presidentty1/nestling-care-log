import SwiftUI

struct OnboardingView: View {
    @StateObject private var coordinator: OnboardingCoordinator
    @EnvironmentObject var environment: AppEnvironment
    let onComplete: () -> Void
    
    init(dataStore: DataStore, onComplete: @escaping () -> Void) {
        _coordinator = StateObject(wrappedValue: OnboardingCoordinator(dataStore: dataStore))
        self.onComplete = onComplete
    }
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator
                OnboardingProgressIndicator(currentStep: coordinator.currentStep)
                    .padding(.top, .spacingMD)
                
                Group {
                    switch coordinator.currentStep {
                    case .welcome:
                        WelcomeView(coordinator: coordinator)
                    case .babySetup:
                        BabySetupView(coordinator: coordinator)
                    case .initialState:
                        InitialStateView(coordinator: coordinator)
                    case .preferences:
                        PreferencesView(coordinator: coordinator)
                    case .aiConsent:
                        AIConsentView(coordinator: coordinator)
                    case .notificationsIntro:
                        NotificationsIntroView(coordinator: coordinator)
                    case .proTrial:
                        ProTrialView(coordinator: coordinator)
                    }
                }
                .transition(.slide)
            }
        }
        .onChange(of: coordinator.isCompleted) { _, completed in
            if completed {
                onComplete()
            }
        }
    }
}

#Preview {
    OnboardingView(dataStore: InMemoryDataStore()) {
        print("Onboarding complete")
    }
    .environmentObject(AppEnvironment(dataStore: InMemoryDataStore()))
}

