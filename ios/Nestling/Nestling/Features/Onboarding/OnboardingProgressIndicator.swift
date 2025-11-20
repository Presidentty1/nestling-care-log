import SwiftUI

struct OnboardingProgressIndicator: View {
    let currentStep: OnboardingStep
    
    private var currentStepIndex: Int {
        switch currentStep {
        case .welcome: return 0
        case .babySetup: return 1
        case .preferences: return 2
        case .aiConsent: return 3
        case .notificationsIntro: return 4
        case .proTrial: return 5
        }
    }
    
    private var totalSteps: Int { 6 }
    
    var body: some View {
        VStack(spacing: .spacingSM) {
            // Progress dots
            HStack(spacing: .spacingSM) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Circle()
                        .fill(index <= currentStepIndex ? Color.primary : Color.mutedForeground.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: currentStepIndex)
                }
            }
            
            // Step text
            Text("Step \(currentStepIndex + 1) of \(totalSteps)")
                .font(.caption)
                .foregroundColor(.mutedForeground)
        }
        .padding(.horizontal, .spacingMD)
        .padding(.vertical, .spacingSM)
    }
}

#Preview {
    VStack(spacing: .spacingLG) {
        OnboardingProgressIndicator(currentStep: .welcome)
        OnboardingProgressIndicator(currentStep: .babySetup)
        OnboardingProgressIndicator(currentStep: .preferences)
    }
    .padding()
    .background(Color.background)
}


