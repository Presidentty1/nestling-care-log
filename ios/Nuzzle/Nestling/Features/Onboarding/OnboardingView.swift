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
                    case .babyBasics:
                        BabyEssentialsView(coordinator: coordinator)
                    case .focusGoals:
                        GoalSelectionView(coordinator: coordinator)
                    case .lastWake:
                        LastWakeView(coordinator: coordinator)
                    case .notifications:
                        NotificationsIntroView(coordinator: coordinator)
                    case .paywall:
                        PaywallView(coordinator: coordinator)
                    case .complete:
                        OnboardingCompleteView(coordinator: coordinator)
                    }
                }
                .id(coordinator.currentStep)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(.easeInOut(duration: 0.3), value: coordinator.currentStep)
            }
        }
        .onChange(of: coordinator.isCompleted) { _, completed in
            if completed {
                onComplete()
            }
        }
        .task {
            await Analytics.shared.logOnboardingStarted()
        }
    }
}

#Preview {
    OnboardingView(dataStore: InMemoryDataStore()) {
        print("Onboarding complete")
    }
    .environmentObject(AppEnvironment(dataStore: InMemoryDataStore()))
}

