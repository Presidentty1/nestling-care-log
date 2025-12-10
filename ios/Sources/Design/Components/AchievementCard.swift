import SwiftUI

struct AchievementCard: View {
    let achievement: Achievement
    let isNew: Bool = false // Could be used for animations

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: .spacingMD) {
            ZStack {
                Circle()
                    .fill(rarityColor(achievement.rarity))
                    .frame(width: 80, height: 80)
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 4)

                Image(systemName: achievement.iconName)
                    .font(.system(size: 32))
                    .foregroundColor(.white)
            }

            Text(achievement.title)
                .font(.headline)
                .foregroundColor(Color.adaptiveForeground(colorScheme))
                .multilineTextAlignment(.center)

            Text(achievement.description)
                .font(.caption)
                .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                .multilineTextAlignment(.center)
                .lineLimit(2)

            // Rarity indicator
            Text(rarityName(achievement.rarity).uppercased())
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(rarityColor(achievement.rarity))
                .padding(.horizontal, .spacingSM)
                .padding(.vertical, .spacingXS)
                .background(rarityColor(achievement.rarity).opacity(0.2))
                .cornerRadius(.radiusSM)
        }
        .padding(.spacingLG)
        .background(Color.adaptiveSurface(colorScheme))
        .cornerRadius(.radiusMD)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    private func rarityName(_ rarity: Achievement.Rarity) -> String {
        switch rarity {
        case .common: return "Common"
        case .rare: return "Rare"
        case .epic: return "Epic"
        case .legendary: return "Legendary"
        }
    }

    private func rarityColor(_ rarity: Achievement.Rarity) -> Color {
        switch rarity {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
}

struct AchievementGrid: View {
    let achievements: [Achievement]

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: .spacingMD) {
            ForEach(achievements) { achievement in
                AchievementCard(achievement: achievement)
            }
        }
        .padding(.horizontal, .spacingMD)
    }
}

#Preview {
    VStack {
        AchievementCard(achievement: Achievement.allAchievements[0])
            .frame(width: 160)

        AchievementGrid(achievements: Achievement.allAchievements.prefix(6).map { $0 })
    }
    .padding()
}

