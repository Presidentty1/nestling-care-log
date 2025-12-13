import SwiftUI

/// A beautiful card designed for sharing milestones on social media
/// Optimized for Instagram Stories (1080x1920) and other platforms
struct ShareableMilestoneCard: View {
    let milestone: ShareableMilestone
    let babyName: String

    enum ShareableMilestone {
        case firstWeekComplete
        case sleepBreakthrough(hours: Int)
        case patternDiscovered
        case streakAchieved(days: Int)
        case fiftyLogsReached

        var title: String {
            switch self {
            case .firstWeekComplete:
                return "🏆 First Week Complete!"
            case .sleepBreakthrough(let hours):
                return "😴 \(hours)+ Hour Sleep!"
            case .patternDiscovered:
                return "📊 Patterns Emerging!"
            case .streakAchieved(let days):
                return "\(days)-Day Streak! 🎯"
            case .fiftyLogsReached:
                return "📝 50 Logs Tracked!"
            }
        }

        var subtitle: String {
            switch self {
            case .firstWeekComplete:
                return "Consistency pays off"
            case .sleepBreakthrough:
                return "Sweet dreams achieved"
            case .patternDiscovered:
                return "Data tells the story"
            case .streakAchieved:
                return "Tracking every day"
            case .fiftyLogsReached:
                return "Building habits"
            }
        }

        var emoji: String {
            switch self {
            case .firstWeekComplete: return "🎉"
            case .sleepBreakthrough: return "🌙"
            case .patternDiscovered: return "📈"
            case .streakAchieved: return "🔥"
            case .fiftyLogsReached: return "⭐"
            }
        }

        var color: Color {
            switch self {
            case .firstWeekComplete: return .green
            case .sleepBreakthrough: return .blue
            case .patternDiscovered: return .purple
            case .streakAchieved: return .orange
            case .fiftyLogsReached: return .yellow
            }
        }
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    milestone.color.opacity(0.8),
                    milestone.color.opacity(0.4),
                    Color.black.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                // Large emoji
                Text(milestone.emoji)
                    .font(.system(size: 120))

                // Title
                Text(milestone.title)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)

                // Subtitle
                Text(milestone.subtitle)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)

                // Baby name (if provided)
                if !babyName.isEmpty {
                    Text(babyName)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                }

                Spacer()

                // App branding (subtle)
                VStack(spacing: 4) {
                    Text("Nestling")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))

                    Text("Baby sleep tracking made simple")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 40)
        }
        .frame(width: 1080, height: 1920) // Instagram Story dimensions
        .clipShape(RoundedRectangle(cornerRadius: 0)) // Full screen for sharing
    }
}

#Preview {
    ShareableMilestoneCard(
        milestone: .sleepBreakthrough(hours: 8),
        babyName: "Emma"
    )
}