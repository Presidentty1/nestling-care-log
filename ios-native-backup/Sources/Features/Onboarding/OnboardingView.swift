import SwiftUI

struct OnboardingView: View {
    @StateObject private var coordinator: OnboardingCoordinator
    @EnvironmentObject var environment: AppEnvironment
    let onComplete: () -> Void
    
    init(dataStore: DataStore, onComplete: @escaping () -> Void) {
        _coordinator = StateObject(wrappedValue: OnboardingCoordinator(dataStore: dataStore, onComplete: onComplete))
        self.onComplete = onComplete
    }
    
    var body: some View {
        ZStack {
            NuzzleTheme.background.ignoresSafeArea()
            
            Group {
                switch coordinator.currentStep {
                case .babyInfo:
                    BabySetupView(coordinator: coordinator)
                case .goalSelection:
                    GoalSelectionView(coordinator: coordinator)
                case .initialState:
                    InitialStateView(coordinator: coordinator)
                }
            }
            .transition(.slide)
        }
    }
}

#Preview {
    OnboardingView(dataStore: InMemoryDataStore()) {
        Logger.analytics("Onboarding complete")
    }
    .environmentObject(AppEnvironment(dataStore: InMemoryDataStore()))
}


