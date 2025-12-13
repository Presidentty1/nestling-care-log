import SwiftUI

struct OnboardingProgressIndicator: View {
    let currentStep: OnboardingStep
    
    /// 0 = welcome (hidden). 1...totalSteps = visible steps.
    private var displayStepNumber: Int {
        switch currentStep {
        case .welcome: return 0
        case .babySetup: return 1
        case .goalSelection: return 2
        case .aiConsent: return 3
        case .firstLog: return 4
        case .notificationsPrimer: return 5
        case .paywall: return 6
        case .complete: return 6
        }
    }
    
    private var totalSteps: Int { 6 } // Baby → Goal → AI → First log → Notifs primer → Paywall
    
    private var shouldShow: Bool {
        // Don't show progress on welcome screen
        currentStep != .welcome
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
        OnboardingProgressIndicator(currentStep: .babySetup)
        OnboardingProgressIndicator(currentStep: .goalSelection)
        OnboardingProgressIndicator(currentStep: .aiConsent)
        OnboardingProgressIndicator(currentStep: .firstLog)
        OnboardingProgressIndicator(currentStep: .notificationsPrimer)
        OnboardingProgressIndicator(currentStep: .paywall)
        OnboardingProgressIndicator(currentStep: .complete)
    }
    .padding()
    .background(Color.background)
}


