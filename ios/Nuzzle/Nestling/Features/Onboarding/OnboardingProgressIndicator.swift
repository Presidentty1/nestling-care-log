import SwiftUI

struct OnboardingProgressIndicator: View {
    let currentStep: OnboardingStep
    
    private var currentStepIndex: Int {
        switch currentStep {
        case .welcome: return 0
        case .babyBasics: return 1
        case .focusGoals: return 2
        case .lastWake: return 3
        case .notifications: return 4
        case .paywall: return 5
        case .complete: return 6
        }
    }
    
    private var totalSteps: Int { 6 } // 6 steps after welcome
    
    private var shouldShow: Bool {
        // Don't show progress on welcome screen
        currentStep != .welcome
    }
    
    private var displayStepNumber: Int {
        // Map to 1-3 for display (excluding welcome)
        max(1, currentStepIndex)
    }
    
    var body: some View {
        if shouldShow {
            VStack(spacing: .spacingSM) {
                // Progress dots (3 steps)
                HStack(spacing: .spacingSM) {
                    ForEach(1...totalSteps, id: \.self) { index in
                        Circle()
                            .fill(index <= displayStepNumber ? Color.primary : Color.mutedForeground.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: displayStepNumber)
                    }
                }
                
                // Step text (1-3)
                Text("Step \(displayStepNumber) of \(totalSteps)")
                    .font(.caption)
                    .foregroundColor(.mutedForeground)
            }
            .padding(.horizontal, .spacingMD)
            .padding(.vertical, .spacingSM)
        } else {
            EmptyView()
        }
    }
}

#Preview {
    VStack(spacing: .spacingLG) {
        OnboardingProgressIndicator(currentStep: .welcome)
        OnboardingProgressIndicator(currentStep: .babyBasics)
        OnboardingProgressIndicator(currentStep: .focusGoals)
        OnboardingProgressIndicator(currentStep: .lastWake)
        OnboardingProgressIndicator(currentStep: .notifications)
        OnboardingProgressIndicator(currentStep: .paywall)
        OnboardingProgressIndicator(currentStep: .complete)
    }
    .padding()
    .background(Color.background)
}


