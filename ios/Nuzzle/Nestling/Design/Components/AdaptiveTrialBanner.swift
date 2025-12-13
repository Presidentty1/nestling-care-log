import SwiftUI

/// Adaptive Trial Banner - Progressive urgency based on trial days remaining
/// Research shows visible countdowns increase conversion by 40%
struct AdaptiveTrialBanner: View {
    let daysRemaining: Int
    let onUpgradeTap: () -> Void

    private var urgencyLevel: UrgencyLevel {
        switch daysRemaining {
        case 4...7: return .low
        case 2...3: return .medium
        case 0...1: return .high
        default: return .none
        }
    }

    enum UrgencyLevel {
        case none, low, medium, high

        var backgroundColor: Color {
            switch self {
            case .none: return .clear
            case .low: return .info.opacity(0.1)
            case .medium: return .warning.opacity(0.15)
            case .high: return .destructive.opacity(0.15)
            }
        }

        var textColor: Color {
            switch self {
            case .none: return .mutedForeground
            case .low: return .info
            case .medium: return .warning
            case .high: return .destructive
            }
        }

        var showBadge: Bool {
            switch self {
            case .medium, .high: return true
            default: return false
            }
        }

        var pulseAnimation: Bool {
            switch self {
            case .high: return true
            default: return false
            }
        }
    }

    @State private var isPulsing = false

    var body: some View {
        if urgencyLevel != .none {
            HStack(spacing: .spacingSM) {
                // Icon with optional pulse
                Image(systemName: urgencyLevel == .high ? "exclamationmark.circle.fill" : "clock.fill")
                    .foregroundColor(urgencyLevel.textColor)
                    .font(.subheadline)
                    .scaleEffect(urgencyLevel.pulseAnimation && isPulsing ? 1.1 : 1.0)
                    .animation(urgencyLevel.pulseAnimation ? .easeInOut(duration: 1.0).repeatForever(autoreverses: true) : .default, value: isPulsing)

                // Message
                VStack(alignment: .leading, spacing: 2) {
                    Text(headline)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.foreground)

                    if urgencyLevel != .low {
                        Text(subtext)
                            .font(.caption)
                            .foregroundColor(.mutedForeground)
                    }

                    // Expandable loss messaging for high urgency
                    if urgencyLevel == .high {
                        DisclosureGroup("See what you'll lose") {
                            VStack(alignment: .leading, spacing: .spacingXS) {
                                LossItem(icon: "moon.zzz.fill", text: "Personalized nap predictions")
                                LossItem(icon: "chart.line.uptrend.xyaxis", text: "Weekly trend charts")
                                LossItem(icon: "brain.head.profile", text: "AI insights from your baby's patterns")
                                LossItem(icon: "square.and.arrow.up", text: "Shareable milestone cards")
                            }
                            .padding(.top, .spacingXS)
                        }
                        .font(.caption)
                        .foregroundColor(.mutedForeground)
                        .tint(.destructive.opacity(0.7))
                    }
                }

                Spacer()

                // CTA button
                Button(action: {
                    Haptics.medium()
                    onUpgradeTap()
                }) {
                    Text(ctaLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, .spacingMD)
                        .padding(.vertical, .spacingSM)
                        .background(urgencyLevel.textColor)
                        .cornerRadius(.radiusSM)
                }
            }
            .padding(.horizontal, .spacingMD)
            .padding(.vertical, .spacingSM)
            .background(urgencyLevel.backgroundColor)
            .cornerRadius(.radiusMD)
            .overlay(
                RoundedRectangle(cornerRadius: .radiusMD)
                    .stroke(urgencyLevel.textColor.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, .spacingLG)
            .onAppear {
                if urgencyLevel.pulseAnimation {
                    isPulsing = true
                }
            }
        }
    }

    private var headline: String {
        switch urgencyLevel {
        case .low:
            return "\(daysRemaining) days left of Pro"
        case .medium:
            return "\(daysRemaining) days left"
        case .high:
            return daysRemaining == 1 ? "Last day of trial" : "Trial ending today"
        case .none:
            return ""
        }
    }

    private var subtext: String {
        switch urgencyLevel {
        case .medium:
            return "Keep your personalized insights"
        case .high:
            return "Don't lose your patterns & predictions"
        default:
            return ""
        }
    }

    private var ctaLabel: String {
        switch urgencyLevel {
        case .high: return "Subscribe"
        default: return "Upgrade"
        }
    }
}

/// Loss item component for expandable loss messaging
private struct LossItem: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: .spacingXS) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.destructive.opacity(0.7))
                .accessibilityHidden(true) // Icon is decorative
            Text(text)
                .font(.caption)
                .foregroundColor(.foreground)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Feature you'll lose: \(text)")
    }
}

#Preview {
    VStack(spacing: .spacingLG) {
        AdaptiveTrialBanner(daysRemaining: 7, onUpgradeTap: {})
        AdaptiveTrialBanner(daysRemaining: 3, onUpgradeTap: {})
        AdaptiveTrialBanner(daysRemaining: 1, onUpgradeTap: {})
    }
    .padding()
    .background(Color.background)
}

