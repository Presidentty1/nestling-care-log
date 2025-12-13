import SwiftUI

struct WidgetOnboardingView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentStep = 0
    @State private var showWidgetPreview = false

    private let steps = [
        ("Add to Home Screen", "Get nap predictions without opening the app"),
        ("Long press home screen", "Press and hold until icons jiggle"),
        ("Tap the + button", "Look for the Nestling widget"),
        ("Choose your widget", "Pick Next Nap or Today Summary")
    ]

    var body: some View {
        ZStack {
            Color.background
                .ignoresSafeArea()

            VStack(spacing: .spacingXL) {
                // Header
                VStack(spacing: .spacingMD) {
                    ZStack {
                        Circle()
                            .fill(Color.primary.opacity(0.1))
                            .frame(width: 80, height: 80)

                        Image(systemName: "square.grid.2x2.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.primary)
                    }

                    Text(steps[currentStep].0)
                        .font(.headingLG)
                        .multilineTextAlignment(.center)

                    Text(steps[currentStep].1)
                        .font(.bodyMD)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, .spacingXL)

                // Step indicator
                HStack(spacing: .spacingSM) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Circle()
                            .fill(index <= currentStep ? Color.primary : Color.surface)
                            .frame(width: 8, height: 8)
                    }
                }

                Spacer()

                // Widget preview (simplified for onboarding)
                WidgetPreviewCard()
                    .padding(.horizontal, .spacingLG)

                Spacer()

                // Navigation buttons
                HStack(spacing: .spacingMD) {
                    if currentStep > 0 {
                        SecondaryButton("Back") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                    }

                    Spacer()

                    if currentStep < steps.count - 1 {
                        PrimaryButton("Next") {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                    } else {
                        PrimaryButton("Got it!") {
                            AnalyticsService.shared.logWidgetOnboardingCompleted()
                            dismiss()
                        }
                    }
                }
                .padding(.horizontal, .spacingLG)
                .padding(.bottom, .spacingXL)
            }
        }
        .onAppear {
            AnalyticsService.shared.logWidgetOnboardingShown()
        }
    }
}

struct WidgetPreviewCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: .spacingMD) {
            Text("Widget Preview")
                .font(.headingSM)
                .foregroundColor(.textPrimary)

            // Simplified widget preview
            ZStack {
                RoundedRectangle(cornerRadius: .radiusMD)
                    .fill(Color.surface)
                    .frame(height: 120)

                VStack(alignment: .leading, spacing: .spacingXS) {
                    HStack {
                        Image(systemName: "moon.zzz.fill")
                            .foregroundColor(.primary)
                        Text("Next Nap")
                            .font(.headingXS)
                    }

                    Text("2:30 - 3:00 PM")
                        .font(.headingMD)

                    Text("Based on wake patterns")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                .padding(.spacingMD)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .overlay(
                RoundedRectangle(cornerRadius: .radiusMD)
                    .stroke(Color.cardBorder, lineWidth: 1)
            )
        }
    }
}

#Preview {
    WidgetOnboardingView()
}