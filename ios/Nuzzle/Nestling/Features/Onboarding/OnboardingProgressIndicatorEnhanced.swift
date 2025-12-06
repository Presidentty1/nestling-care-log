import SwiftUI

/// Enhanced progress indicator with visual progress bar (Phase 4)
struct OnboardingProgressIndicatorEnhanced: View {
    let currentStep: OnboardingStep
    
    private var currentStepIndex: Int {
        switch currentStep {
        case .welcome: return 0
        case .babyEssentials: return 1
        case .goalSelection: return 2
        case .complete: return 3
        }
    }
    
    private var totalSteps: Int { 4 }
    
    private var progress: Double {
        Double(currentStepIndex) / Double(totalSteps)
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
                Text("Step \(currentStepIndex) of \(totalSteps)")
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
        OnboardingProgressIndicatorEnhanced(currentStep: .babyEssentials)
        OnboardingProgressIndicatorEnhanced(currentStep: .goalSelection)
        OnboardingProgressIndicatorEnhanced(currentStep: .complete)
    }
    .padding()
    .background(Color.background)
}

