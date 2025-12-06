import SwiftUI

struct OnboardingProgressDots: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...total, id: \.self) { step in
                Circle()
                    .fill(step <= current ? NuzzleTheme.primary : NuzzleTheme.textSecondary.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .accessibilityLabel("Step \(current) of \(total)")
        .accessibilityHint("Onboarding progress indicator")
    }
}

#Preview {
    VStack(spacing: 20) {
        OnboardingProgressDots(current: 1, total: 3)
        OnboardingProgressDots(current: 2, total: 3)
        OnboardingProgressDots(current: 3, total: 3)
    }
    .padding()
    .background(NuzzleTheme.background)
}

