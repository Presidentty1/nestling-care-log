import SwiftUI

/// Enhanced progress indicator with visual progress bar (Phase 4)
struct OnboardingProgressIndicatorEnhanced: View {
    let currentStep: OnboardingStep
    
    /// 0 = welcome (hidden). 1...totalSteps = visible steps.
    private var displayStepNumber: Int {
        switch currentStep {
        case .welcome: return 0
        case .babySetup: return 1
        case .firstLog: return 2
        case .partnerOnboarding: return 3
        case .complete: return 3
        }
    }
    
    private var totalSteps: Int { 3 }
    
    private var progress: Double {
        guard totalSteps > 0 else { return 0 }
        return Double(displayStepNumber) / Double(totalSteps)
    }
    
    private var shouldShow: Bool {
        // Don't show progress on welcome screen
        currentStep != .welcome
    }
    
    var body: some View {
        if shouldShow {
            VStack(spacing: .spacingMD) {
                // Progress bar (new in Phase 4)
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.mutedForeground.opacity(0.2))
                            .frame(height: 6)
                        
                        // Progress fill
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [Color.primary, Color.primary.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: 6)
                            .animation(.easeInOut(duration: 0.3), value: progress)
                    }
                }
                .frame(height: 6)
                
                // Step text
                Text("Step \(max(1, displayStepNumber)) of \(totalSteps)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.mutedForeground)
            }
            .padding(.horizontal, .spacingLG)
            .padding(.vertical, .spacingMD)
        } else {
            EmptyView()
        }
    }
}

#Preview {
    VStack(spacing: .spacingXL) {
        OnboardingProgressIndicatorEnhanced(currentStep: .welcome)
        OnboardingProgressIndicatorEnhanced(currentStep: .babySetup)
        OnboardingProgressIndicatorEnhanced(currentStep: .firstLog)
        OnboardingProgressIndicatorEnhanced(currentStep: .partnerOnboarding)
        OnboardingProgressIndicatorEnhanced(currentStep: .complete)
    }
    .padding()
    .background(Color.background)
}

