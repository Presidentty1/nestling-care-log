import SwiftUI

struct OnboardingContainer<Content: View>: View {
    let title: String
    let subtitle: String?
    let step: Int
    let totalSteps: Int

    @ViewBuilder let content: Content

    let primaryTitle: String
    let primaryAction: () -> Void
    let primaryDisabled: Bool
    let secondaryTitle: String?
    let secondaryAction: (() -> Void)?
    
    init(
        title: String,
        subtitle: String? = nil,
        step: Int,
        totalSteps: Int,
        @ViewBuilder content: () -> Content,
        primaryTitle: String,
        primaryAction: @escaping () -> Void,
        primaryDisabled: Bool = false,
        secondaryTitle: String? = nil,
        secondaryAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.step = step
        self.totalSteps = totalSteps
        self.content = content()
        self.primaryTitle = primaryTitle
        self.primaryAction = primaryAction
        self.primaryDisabled = primaryDisabled
        self.secondaryTitle = secondaryTitle
        self.secondaryAction = secondaryAction
    }

    var body: some View {
        ZStack {
            Color.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    OnboardingProgressDots(current: step, total: totalSteps)
                        .padding(.top, 8)

                    Text(title)
                        .font(.largeTitle.bold())
                        .foregroundColor(Color.foreground)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.body)
                            .foregroundColor(Color.mutedForeground)
                            .multilineTextAlignment(.leading)
                    }

                    content

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: 480)
                .padding(.horizontal, 24)
                .frame(
                    maxWidth: .infinity,
                    alignment: .top
                )
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                Button(action: primaryAction) {
                    Text(primaryTitle)
                        .font(.body)
                        .foregroundColor(primaryDisabled ? Color.mutedForeground : Color.primaryForeground)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .padding(.spacingMD)
                        .background(primaryDisabled ? Color.surface : Color.primary)
                        .cornerRadius(.radiusMD)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(primaryDisabled)

                if let secondaryTitle = secondaryTitle, let secondaryAction = secondaryAction {
                    Button(action: secondaryAction) {
                        Text(secondaryTitle)
                            .font(.body)
                            .foregroundColor(Color.mutedForeground)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
        }
    }
}

#Preview {
    OnboardingContainer(
        title: "Welcome to Nestling",
        subtitle: "Know what happened last and what's coming next.",
        step: 1,
        totalSteps: 3,
        content: {
            VStack(spacing: .spacingMD) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color.primary)

                Text("Track feeds, sleep, diapers, and more with just a tap.")
                    .font(.body)
                    .foregroundColor(Color.mutedForeground)
                    .multilineTextAlignment(.center)
            }
        },
        primaryTitle: "Get Started",
        primaryAction: {},
        secondaryTitle: "Skip for now",
        secondaryAction: {}
    )
}
