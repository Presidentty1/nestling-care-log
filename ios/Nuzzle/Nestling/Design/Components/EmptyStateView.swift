import SwiftUI

/// Enhanced Empty State View - Reassuring and contextual for parenting
/// Research shows empty states should reduce anxiety, not pressure users
struct EmptyStateView: View {
    enum Context {
        case todayTimeline
        case historyView
        case firstTimeUser

        var illustration: String {
            switch self {
            case .todayTimeline: return "moon.stars"
            case .historyView: return "calendar.badge.clock"
            case .firstTimeUser: return "heart.fill"
            }
        }

        var headline: String {
            switch self {
            case .todayTimeline: return "Ready when you are"
            case .historyView: return "Your story starts here"
            case .firstTimeUser: return "Welcome to calmer days"
            }
        }

        var supportingText: String {
            switch self {
            case .todayTimeline:
                return "Log what you can, when you can. Every entry helps us understand your baby better."
            case .historyView:
                return "Once you start logging, you'll see patterns emerge that make parenting clearer."
            case .firstTimeUser:
                return "Tracking doesn't need to be perfect. Even one log a day helps us help you."
            }
        }

        var ctaLabel: String {
            guard PolishFeatureFlags.shared.smartCTAsEnabled else {
                return defaultCTALabel
            }

            // Time-based CTAs only for today timeline and first time user contexts
            switch self {
            case .todayTimeline, .firstTimeUser:
                return timeBasedCTALabel
            case .historyView:
                return defaultCTALabel
            }
        }

        private var defaultCTALabel: String {
            switch self {
            case .todayTimeline: return "Log First Event"
            case .historyView: return "Start Tracking"
            case .firstTimeUser: return "Let's Begin"
            }
        }

        private var timeBasedCTALabel: String {
            let hour = Calendar.current.component(.hour, from: Date())
            switch hour {
            case 6..<10: return "Log Morning Feed"
            case 12..<15: return "Log Today's Nap"
            case 18..<21: return "Log Evening Feed"
            case 22..<24, 0..<6: return "Quick Night Log"
            default: return "Log First Event"
            }
        }
    }

    let context: Context
    let babyName: String?
    let onPrimaryAction: () -> Void

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: .spacingXL) {
            Spacer()

            // Animated illustration
            ZStack {
                Circle()
                    .fill(Color.primary.opacity(0.05))
                    .frame(width: 140, height: 140)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)

                Circle()
                    .fill(Color.primary.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: context.illustration)
                    .font(.system(size: 44))
                    .foregroundColor(.primary)
                    .scaleEffect(isAnimating ? 1.0 : 0.9)
            }
            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)

            // Text content
            VStack(spacing: .spacingMD) {
                Text(context.headline)
                    .font(.title2.weight(.bold))
                    .foregroundColor(.foreground)
                    .multilineTextAlignment(.center)

                Text(personalizedSupportingText)
                    .font(.body)
                    .foregroundColor(.mutedForeground)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, .spacingLG)

            // Reassurance message - research shows reducing anxiety increases action
            HStack(spacing: .spacingSM) {
                Image(systemName: "checkmark.shield")
                    .font(.caption)
                    .foregroundColor(.success)

                Text("No perfect timing needed. Log anytime.")
                    .font(.caption)
                    .foregroundColor(.mutedForeground)
            }
            .padding(.horizontal, .spacingLG)
            .padding(.vertical, .spacingSM)
            .background(Color.success.opacity(0.1))
            .cornerRadius(.radiusSM)

            Spacer()

            // Primary CTA
            Button(action: {
                Haptics.medium()
                onPrimaryAction()
            }) {
                Text(context.ctaLabel)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.primary)
                    .cornerRadius(.radiusXL)
                    .shadow(color: Color.primary.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, .spacingLG)
            .padding(.bottom, .spacing2XL)
        }
        .onAppear {
            isAnimating = true
        }
    }

    private var personalizedSupportingText: String {
        if let name = babyName {
            return context.supportingText.replacingOccurrences(of: "your baby", with: name)
        }
        return context.supportingText
    }
}

#Preview {
    VStack {
        EmptyStateView(
            context: .todayTimeline,
            babyName: "Emma",
            onPrimaryAction: {}
        )

        EmptyStateView(
            context: .historyView,
            babyName: nil,
            onPrimaryAction: {}
        )
    }
    .background(Color.background)
}

