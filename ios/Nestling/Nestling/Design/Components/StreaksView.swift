import SwiftUI

/// View showing logging streaks and milestones
struct StreaksView: View {
    let currentStreak: Int
    let longestStreak: Int

    private var streakBadges: [StreakBadge] {
        let badges = [
            StreakBadge(days: 1, name: "First Log", icon: "star", color: .primary, earned: currentStreak >= 1),
            StreakBadge(days: 3, name: "Getting Started", icon: "flame", color: .orange, earned: currentStreak >= 3),
            StreakBadge(days: 7, name: "Week Warrior", icon: "flame.fill", color: .red, earned: currentStreak >= 7),
            StreakBadge(days: 14, name: "Two Weeks Strong", icon: "crown", color: .yellow, earned: currentStreak >= 14),
            StreakBadge(days: 30, name: "Month Master", icon: "crown.fill", color: .purple, earned: currentStreak >= 30),
            StreakBadge(days: 50, name: "Logging Legend", icon: "sparkles", color: .pink, earned: currentStreak >= 50),
            StreakBadge(days: 100, name: "Century Club", icon: "rosette", color: .mint, earned: currentStreak >= 100)
        ]
        return badges
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingMD) {
            // Header with current streak
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current Streak")
                        .font(.headline)
                        .foregroundColor(.foreground)

                    HStack(spacing: .spacingXS) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(currentStreak) day\(currentStreak == 1 ? "" : "s")")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.foreground)
                    }

                    if longestStreak > currentStreak {
                        Text("Personal best: \(longestStreak) days")
                            .font(.caption)
                            .foregroundColor(.mutedForeground)
                    }
                }

                Spacer()

                // Fire emoji for active streak
                if currentStreak > 0 {
                    Text("🔥")
                        .font(.system(size: 40))
                }
            }

            // Streak badges
            VStack(alignment: .leading, spacing: .spacingSM) {
                Text("Milestones")
                    .font(.subheadline)
                    .foregroundColor(.mutedForeground)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: .spacingMD) {
                        ForEach(streakBadges) { badge in
                            StreakBadgeView(badge: badge)
                        }
                    }
                    .padding(.vertical, .spacingXS)
                }
            }
        }
        .padding(.spacingMD)
        .background(Color.surface)
        .cornerRadius(.radiusMD)
    }
}

struct StreakBadge: Identifiable {
    let id = UUID()
    let days: Int
    let name: String
    let icon: String
    let color: Color
    let earned: Bool
}

struct StreakBadgeView: View {
    let badge: StreakBadge

    var body: some View {
        VStack(spacing: .spacingXS) {
            ZStack {
                Circle()
                    .fill(badge.earned ? badge.color.opacity(0.2) : Color.mutedForeground.opacity(0.1))
                    .frame(width: 50, height: 50)

                Image(systemName: badge.icon)
                    .foregroundColor(badge.earned ? badge.color : .mutedForeground)
                    .font(.system(size: 20))
            }

            Text(badge.name)
                .font(.caption)
                .foregroundColor(badge.earned ? .foreground : .mutedForeground)
                .multilineTextAlignment(.center)
                .frame(width: 70)

            Text("\(badge.days) days")
                .font(.caption2)
                .foregroundColor(.mutedForeground)
        }
        .opacity(badge.earned ? 1.0 : 0.6)
    }
}

#Preview {
    VStack {
        StreaksView(currentStreak: 5, longestStreak: 12)

        Spacer().frame(height: 20)

        StreaksView(currentStreak: 25, longestStreak: 25)
    }
    .padding()
}

