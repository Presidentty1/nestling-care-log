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
            // Prominent streak display
            HStack(alignment: .center, spacing: .spacingMD) {
                // Large flame emoji with glow
                ZStack {
                    Circle()
                        .fill(Color.warning.opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Text("🔥")
                        .font(.system(size: 36))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: .spacingXS) {
                        Text("\(currentStreak)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.foreground)
                        
                        Text("day\(currentStreak == 1 ? "" : "s")")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.mutedForeground)
                    }
                    
                    Text("Current Streak")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.mutedForeground)
                    
                    if longestStreak > currentStreak {
                        Text("Best: \(longestStreak) days")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.mutedForeground.opacity(0.8))
                    }
                }

                Spacer()
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

