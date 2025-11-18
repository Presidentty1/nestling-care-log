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
            
            Group {
                switch coordinator.currentStep {
                case .welcome:
                    WelcomeView(coordinator: coordinator)
                case .babySetup:
                    BabySetupView(coordinator: coordinator)
                case .preferences:
                    PreferencesView(coordinator: coordinator)
                case .aiConsent:
                    AIConsentView(coordinator: coordinator)
                case .notificationsIntro:
                    NotificationsIntroView(coordinator: coordinator)
                }
            }
            .transition(.slide)
        }
        .onChange(of: coordinator.currentStep) { _, newStep in
            if newStep == .notificationsIntro {
                // Check if onboarding is complete
                Task {
                    if try await OnboardingService(dataStore: environment.dataStore).isOnboardingCompleted() {
                        await MainActor.run {
                            onComplete()
                        }
                    }
                }
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

