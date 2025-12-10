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
                    case .babyEssentials:
                        BabyEssentialsView(coordinator: coordinator)
                    case .goalSelection:
                        GoalSelectionView(coordinator: coordinator)
                    case .complete:
                        ReadyToGoView(coordinator: coordinator)
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
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

