import SwiftUI
import StoreKit

/// Value-Realized Upgrade Modal - Context-aware upgrade prompts
/// Different from generic paywall - acknowledges what user just experienced
struct ValueRealizedUpgradeModal: View {
    let trigger: ConversionTriggerService.ConversionTrigger
    @Binding var isPresented: Bool
    let onUpgrade: () -> Void

    @ObservedObject private var proService = ProSubscriptionService.shared

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
                .onTapGesture { isPresented = false }

            VStack(spacing: .spacingXL) {
                // Success state - show what they just experienced
                ZStack {
                    Circle()
                        .fill(Color.success.opacity(0.1))
                        .frame(width: 100, height: 100)

                    Image(systemName: successIcon)
                        .font(.system(size: 44))
                        .foregroundColor(.success)
                }

                VStack(spacing: .spacingMD) {
                    Text(headline)
                        .font(.title2.weight(.bold))
                        .multilineTextAlignment(.center)

                    Text(subtext)
                        .font(.body)
                        .foregroundColor(.mutedForeground)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, .spacingLG)

                // Social proof - research shows 15-20% conversion lift
                HStack(spacing: .spacingSM) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)

                    Text("4.8 stars • Trusted by 10,000+ parents")
                        .font(.caption)
                        .foregroundColor(.mutedForeground)
                }

                // Benefits list
                VStack(alignment: .leading, spacing: .spacingSM) {
                    BenefitRow(icon: "moon.zzz.fill", text: "Unlimited nap predictions")
                    BenefitRow(icon: "chart.line.uptrend.xyaxis", text: "Weekly trend insights")
                    BenefitRow(icon: "waveform", text: "Cry analysis (Beta)")
                    BenefitRow(icon: "doc.text", text: "Shareable doctor reports")
                }
                .padding(.spacingMD)
                .background(Color.surface)
                .cornerRadius(.radiusMD)
                .padding(.horizontal, .spacingLG)

                // CTA buttons
                VStack(spacing: .spacingMD) {
                    Button(action: {
                        Haptics.medium()
                        onUpgrade()
                        isPresented = false
                    }) {
                        HStack {
                            Image(systemName: "crown.fill")
                            Text("Start Free Trial")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.primary)
                        .cornerRadius(.radiusXL)
                        .shadow(color: Color.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                    }

                    Text("7 days free, then \(proService.getMonthlyProduct()?.displayPrice ?? "$5.99")/mo")
                        .font(.caption)
                        .foregroundColor(.mutedForeground)

                    Button("Maybe later") {
                        isPresented = false
                    }
                    .font(.body)
                    .foregroundColor(.mutedForeground)
                }
                .padding(.horizontal, .spacingLG)
            }
            .padding(.vertical, .spacingXL)
            .background(Color.elevated)
            .cornerRadius(.radius2XL)
            .shadow(color: Color.black.opacity(0.2), radius: 20)
            .padding(.horizontal, .spacingLG)
        }
    }

    private var successIcon: String {
        switch trigger {
        case .aiPredictionAccurate: return "checkmark.circle.fill"
        case .patternUnlocked: return "chart.bar.fill"
        case .weeklyInsightReady: return "calendar.badge.checkmark"
        case .sevenDayStreak: return "flame.fill"
        case .fiftyLogs: return "star.fill"
        case .thirdDayActive: return "heart.fill"
        case .trialEnding: return "clock.fill"
        case .trialEnded: return "crown.fill"
        }
    }

    private var headline: String {
        switch trigger {
        case .aiPredictionAccurate:
            return "That prediction was helpful!"
        case .patternUnlocked:
            return "We've learned your baby's patterns"
        case .weeklyInsightReady:
            return "Your first weekly insight is ready"
        case .sevenDayStreak:
            return "7-day streak unlocked!"
        case .fiftyLogs:
            return "50 logs and counting!"
        case .thirdDayActive:
            return "You're really getting this"
        case .trialEnding:
            return "Don't lose your progress"
        case .trialEnded:
            return "Trial ended - keep the insights"
        }
    }

    private var subtext: String {
        switch trigger {
        case .aiPredictionAccurate:
            return "Get unlimited AI predictions with Pro"
        case .patternUnlocked:
            return "Unlock personalized insights based on your data"
        case .weeklyInsightReady:
            return "See how this week compared to last"
        case .sevenDayStreak:
            return "Keep your streak going with Pro features"
        case .fiftyLogs:
            return "Your consistent tracking deserves Pro insights"
        case .thirdDayActive:
            return "Ready to unlock the full experience?"
        case .trialEnding:
            return "2 days left to keep all your insights"
        case .trialEnded:
            return "Subscribe to maintain your personalized predictions"
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: .spacingMD) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.primary)
                .frame(width: 24)

            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.foreground)

            Spacer()
        }
    }
}

#Preview {
    @Previewable @State var isPresented = true
    return ValueRealizedUpgradeModal(
        trigger: .aiPredictionAccurate,
        isPresented: $isPresented,
        onUpgrade: {}
    )
}
