import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject var environment: AppEnvironment
    @State private var achievements: [Achievement] = Achievement.allAchievements
    @State private var currentStreak: Int = 0
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: .spacingLG) {
                // Streak Display
                CardView(variant: .emphasis) {
                    VStack(spacing: .spacingSM) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        
                        Text("\(currentStreak) Day Streak")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.foreground)
                        
                        Text("Keep logging to maintain your streak!")
                            .font(.caption)
                            .foregroundColor(.mutedForeground)
                    }
                    .padding(.spacingMD)
                }
                .padding(.horizontal, .spacingMD)
                
                // Achievements Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: .spacingMD) {
                    ForEach(achievements) { achievement in
                        AchievementCard(achievement: achievement)
                    }
                }
                .padding(.horizontal, .spacingMD)
            }
            .padding(.vertical, .spacingMD)
        }
        .navigationTitle("Achievements")
        .background(Color.background)
        .task {
            await loadAchievements()
        }
    }
    
    private func loadAchievements() async {
        isLoading = true
        defer { isLoading = false }
        
        guard let baby = environment.currentBaby else { return }
        
        do {
            let streakService = StreakService(dataStore: environment.dataStore)
            currentStreak = try await streakService.calculateCurrentStreak(for: baby)
            
            let achievementService = AchievementService(dataStore: environment.dataStore)
            let unlocked = try await achievementService.checkAchievements(for: baby)
            
            await MainActor.run {
                // Mark unlocked achievements
                for (index, achievement) in achievements.enumerated() {
                    if unlocked.contains(where: { $0.id == achievement.id }) {
                        achievements[index] = Achievement(
                            id: achievement.id,
                            title: achievement.title,
                            description: achievement.description,
                            icon: achievement.icon,
                            unlockedAt: Date()
                        )
                    }
                }
            }
        } catch {
            logger.debug("Failed to load achievements: \(error)")
        }
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: .spacingSM) {
            Image(systemName: achievement.icon)
                .font(.system(size: 30))
                .foregroundColor(achievement.isUnlocked ? .primary : .mutedForeground)
                .opacity(achievement.isUnlocked ? 1.0 : 0.5)
            
            Text(achievement.title)
                .font(.headline)
                .foregroundColor(achievement.isUnlocked ? .foreground : .mutedForeground)
                .multilineTextAlignment(.center)
            
            Text(achievement.description)
                .font(.caption)
                .foregroundColor(.mutedForeground)
                .multilineTextAlignment(.center)
            
            if achievement.isUnlocked, let unlockedAt = achievement.unlockedAt {
                Text("Unlocked \(formatDate(unlockedAt))")
                    .font(.caption2)
                    .foregroundColor(.mutedForeground)
            }
        }
        .padding(.spacingMD)
        .frame(maxWidth: .infinity)
        .background(Color.surface)
        .cornerRadius(.radiusMD)
        .overlay(
            RoundedRectangle(cornerRadius: .radiusMD)
                .stroke(achievement.isUnlocked ? Color.primary : Color.clear, lineWidth: 2)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        AchievementsView()
            .environmentObject(AppEnvironment(dataStore: InMemoryDataStore()))
    }
}

