import SwiftUI

/// Win of the Day Card - Daily insight card for positive reinforcement
/// Research shows daily positive reinforcement increases retention by 30%
/// Psychology: Dopamine trigger + personalization = habit formation
struct WinOfTheDayCard: View {
    let insight: DailyInsight
    let babyName: String
    let isPro: Bool
    let onLearnMore: () -> Void
    let onUpgrade: () -> Void

    @State private var hasAnimated = false
    @State private var showDetailSheet = false
    @State private var insightTimestamp = Date() // For "NEW" badge logic

    private var isNewInsight: Bool {
        // Show "NEW" badge for insights less than 2 hours old
        Date().timeIntervalSince(insightTimestamp) < (2 * 60 * 60)
    }

    enum DailyInsight: Equatable {
        // Free tier insights (factual, encouraging)
        case longerNap(minutes: Int, percentageImprovement: Int)
        case consistentFeeds(count: Int, targetRange: String)
        case streakMilestone(days: Int)
        case firstDataPoint(type: String)
        case goodDiaperPattern(wetCount: Int, dirtyCount: Int)
        case quietNight(wakingsVsAverage: Int)

        // Pro tier insights (predictive, actionable)
        case predictedPattern(patternType: String, confidence: Int)
        case optimizedSchedule(suggestion: String)
        case weekOverWeekImprovement(category: String, improvement: Int)

        var emoji: String {
            switch self {
            case .longerNap: return "🌙"
            case .consistentFeeds: return "🍼"
            case .streakMilestone: return "🔥"
            case .firstDataPoint: return "🎉"
            case .goodDiaperPattern: return "✨"
            case .quietNight: return "😴"
            case .predictedPattern: return "🔮"
            case .optimizedSchedule: return "📊"
            case .weekOverWeekImprovement: return "📈"
            }
        }

        var isPremiumInsight: Bool {
            switch self {
            case .predictedPattern, .optimizedSchedule, .weekOverWeekImprovement:
                return true
            default:
                return false
            }
        }

        func headline(babyName: String) -> String {
            switch self {
            case .longerNap(let minutes, let improvement):
                return "\(babyName) slept \(improvement)% longer today!"
            case .consistentFeeds(let count, _):
                return "\(count) feeds today — right on track"
            case .streakMilestone(let days):
                return "\(days) days of tracking! You're amazing"
            case .firstDataPoint(let type):
                return "First \(type) logged — we're learning!"
            case .goodDiaperPattern(let wet, let dirty):
                return "\(wet + dirty) diaper changes — healthy output"
            case .quietNight(let fewer):
                return "\(fewer) fewer wake-ups than average"
            case .predictedPattern(let pattern, _):
                return "\(babyName)'s \(pattern) pattern is forming"
            case .optimizedSchedule(let suggestion):
                return suggestion
            case .weekOverWeekImprovement(let category, let improvement):
                return "\(category) improved \(improvement)% this week"
            }
        }

        func subtext(babyName: String) -> String {
            switch self {
            case .longerNap(let minutes, _):
                return "Today's longest nap was \(minutes) minutes. Great rest!"
            case .consistentFeeds(_, let range):
                return "You're feeding every \(range). Keep it up!"
            case .streakMilestone:
                return "Consistent tracking helps us give better suggestions"
            case .firstDataPoint:
                return "With more logs, we'll spot \(babyName)'s unique patterns"
            case .goodDiaperPattern:
                return "This is a healthy sign of good feeding"
            case .quietNight:
                return "\(babyName)'s sleep is improving!"
            case .predictedPattern(_, let confidence):
                return "\(confidence)% confidence based on your logs"
            case .optimizedSchedule:
                return "Based on \(babyName)'s sleep and feed patterns"
            case .weekOverWeekImprovement:
                return "Your consistent tracking is making a difference"
            }
        }
    }

    var body: some View {
        Button(action: {
            Haptics.light()
            showDetailSheet = true
        }) {
            CardView(variant: insight.isPremiumInsight && !isPro ? .outline : .success) {
            VStack(alignment: .leading, spacing: .spacingMD) {
                // Header with emoji
                HStack(spacing: .spacingSM) {
                    Text(insight.emoji)
                        .font(.system(size: 28))
                        .scaleEffect(hasAnimated ? 1.0 : 0.5)
                        .opacity(hasAnimated ? 1.0 : 0.0)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: .spacingXS) {
                            Text("Today's Win")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.mutedForeground)

                            if isNewInsight {
                                Text("NEW")
                                    .font(.caption2.weight(.bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Color.accentColor)
                                    .cornerRadius(4)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }

                        Text(insight.headline(babyName: babyName))
                            .font(.headline)
                            .foregroundColor(.foreground)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()
                }

                Text(insight.subtext(babyName: babyName))
                    .font(.subheadline)
                    .foregroundColor(.mutedForeground)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                // Pro upsell for premium insights
                if insight.isPremiumInsight && !isPro {
                    Divider()

                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.primary)

                        Text("Unlock personalized insights")
                            .font(.caption)
                            .foregroundColor(.mutedForeground)

                        Spacer()

                        Button(action: {
                            Haptics.light()
                            onUpgrade()
                        }) {
                            Text("Try Pro")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, .spacingMD)
                                .padding(.vertical, .spacingSM)
                                .background(Color.primary)
                                .cornerRadius(.radiusSM)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Today's win: \(insight.headline(babyName: babyName)). \(isNewInsight ? "New insight. " : "")Tap to view details.")
        .accessibilityHint("Double tap to see more information about this insight")
        .sheet(isPresented: $showDetailSheet) {
            WinDetailSheet(
                insight: insight,
                babyName: babyName,
                isPro: isPro,
                onDismiss: { showDetailSheet = false },
                onShare: {
                    // TODO: Implement share functionality
                    showDetailSheet = false
                }
            )
        }
        .onAppear {
            // Animate emoji entrance - research shows delight increases retention
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2)) {
                hasAnimated = true
            }
            Haptics.light()
        }
    }
}

#Preview {
    VStack(spacing: .spacingLG) {
        // Free tier insights
        WinOfTheDayCard(
            insight: .longerNap(minutes: 45, percentageImprovement: 20),
            babyName: "Emma",
            isPro: false,
            onLearnMore: {},
            onUpgrade: {}
        )

        WinOfTheDayCard(
            insight: .streakMilestone(days: 7),
            babyName: "Emma",
            isPro: false,
            onLearnMore: {},
            onUpgrade: {}
        )

        // Pro tier insight
        WinOfTheDayCard(
            insight: .predictedPattern(patternType: "nap", confidence: 85),
            babyName: "Emma",
            isPro: false,
            onLearnMore: {},
            onUpgrade: {}
        )
    }
    .padding()
    .background(Color.background)
}