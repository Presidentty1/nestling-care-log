import SwiftUI

/// Detail sheet for expanded win information
/// Shows historical context, charts, and sharing options
struct WinDetailSheet: View {
    let insight: WinOfTheDayCard.DailyInsight
    let babyName: String
    let isPro: Bool
    let onDismiss: () -> Void
    let onShare: () -> Void

    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacingXL) {
                    // Header
                    VStack(spacing: .spacingMD) {
                        Text(insight.emoji)
                            .font(.system(size: 60))

                        Text("Today's Win")
                            .font(.title2.weight(.bold))
                            .foregroundColor(.foreground)

                        Text(insight.headline(babyName: babyName))
                            .font(.title3)
                            .foregroundColor(.foreground)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Main content
                    VStack(spacing: .spacingLG) {
                        // Insight explanation
                        CardView(variant: .elevated) {
                            VStack(alignment: .leading, spacing: .spacingMD) {
                                Text("Why this matters")
                                    .font(.headline)
                                    .foregroundColor(.foreground)

                                Text(explanationText)
                                    .font(.body)
                                    .foregroundColor(.mutedForeground)
                                    .lineSpacing(4)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // Historical context (placeholder for now)
                        CardView(variant: .elevated) {
                            VStack(alignment: .leading, spacing: .spacingMD) {
                                Text("Recent Progress")
                                    .font(.headline)
                                    .foregroundColor(.foreground)

                                Text("This is part of a positive trend. Keep up the great work!")
                                    .font(.body)
                                    .foregroundColor(.mutedForeground)

                                // Placeholder chart area
                                RoundedRectangle(cornerRadius: .radiusMD)
                                    .fill(Color.mutedForeground.opacity(0.1))
                                    .frame(height: 120)
                                    .overlay(
                                        Text("Trend Chart")
                                            .font(.caption)
                                            .foregroundColor(.mutedForeground)
                                    )
                                    .accessibilityLabel("Progress trend chart")
                                    .accessibilityHint("Visual representation of recent progress trends")
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // Share encouragement
                        if isPro {
                            CardView(variant: .success) {
                                VStack(alignment: .leading, spacing: .spacingMD) {
                                    Text("Share this win! 🎉")
                                        .font(.headline)
                                        .foregroundColor(.foreground)

                                    Text("Celebrate your progress and inspire other parents.")
                                        .font(.body)
                                        .foregroundColor(.mutedForeground)

                                    Button(action: onShare) {
                                        HStack {
                                            Image(systemName: "square.and.arrow.up")
                                            Text("Share This Win")
                                        }
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, .spacingMD)
                                        .background(Color.accentColor)
                                        .cornerRadius(.radiusMD)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .padding(.horizontal, .spacingLG)
                }
                .padding(.vertical, .spacingXL)
            }
            .navigationTitle("Win Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                        onDismiss()
                    }
                }
            }
        }
    }

    private var explanationText: String {
        switch insight {
        case .longerNap(let minutes, let improvement):
            return "Sleep is crucial for both you and \(babyName). This \(improvement)% improvement in nap length suggests you're finding a rhythm that works. Longer naps mean more rest for everyone!"

        case .consistentFeeds:
            return "Consistent feeding is one of the most important things for a baby's development. Your steady schedule helps \(babyName) feel secure and know what to expect."

        case .streakMilestone(let days):
            return "Tracking consistently for \(days) days shows real dedication. This kind of consistency helps us provide better insights and predictions for \(babyName)'s care."

        case .firstDataPoint:
            return "Every journey starts with a single step. This first data point is the foundation for understanding \(babyName)'s unique patterns and needs."

        case .goodDiaperPattern:
            return "Healthy diaper output is a great sign that \(babyName) is getting good nutrition. This pattern indicates everything is working well!"

        case .quietNight:
            return "Fewer wake-ups mean better rest for the whole family. You're doing great work helping \(babyName) develop good sleep habits."

        case .predictedPattern(_, let confidence):
            return "Based on \(babyName)'s data, we're \(confidence)% confident in this emerging pattern. This insight helps you anticipate and prepare for \(babyName)'s needs."

        case .optimizedSchedule:
            return "This schedule optimization is tailored to \(babyName)'s actual patterns, not generic recommendations. It should feel natural and effective."

        case .weekOverWeekImprovement:
            return "Your consistent tracking is making a measurable difference! This improvement shows that your care routine is working well for \(babyName)."
        }
    }
}

#Preview {
    WinDetailSheet(
        insight: .longerNap(minutes: 45, percentageImprovement: 20),
        babyName: "Emma",
        isPro: true,
        onDismiss: {},
        onShare: {}
    )
}
