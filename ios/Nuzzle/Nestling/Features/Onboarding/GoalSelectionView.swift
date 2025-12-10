import SwiftUI

struct GoalSelectionView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    
    let goals = [
        (id: "sleep", title: "😴 Better Sleep", description: "Understand sleep patterns and get nap predictions", icon: "moon.zzz.fill"),
        (id: "feeding", title: "🍼 Track Feeding", description: "Monitor milk intake and feeding schedules", icon: "drop.fill"),
        (id: "health", title: "📊 Health Logs", description: "Track growth, vaccines, and doctor visits", icon: "heart.text.square.fill"),
        (id: "survive", title: "🆘 Just Surviving", description: "I'm overwhelmed and need all the help I can get", icon: "hands.sparkles.fill")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: .spacingXL) {
                VStack(spacing: .spacingSM) {
                    Text("What's your main goal?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.foreground)
                    
                    Text("We'll personalize your home screen to help you most")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.mutedForeground)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, .spacingXL)
                
                VStack(spacing: .spacingMD) {
                    ForEach(goals, id: \.id) { goal in
                        GoalCard(
                            title: goal.title,
                            description: goal.description,
                            icon: goal.icon,
                            isSelected: coordinator.selectedGoal == goal.id,
                            action: {
                                coordinator.selectedGoal = goal.id
                                Haptics.selection()
                                Task {
                                    await Analytics.shared.logOnboardingGoalSelected(goal: goal.id)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, .spacingLG)
                
                Spacer(minLength: 40)
                
                VStack(spacing: .spacingSM) {
                    Button(action: {
                        Haptics.light()
                        coordinator.next()
                    }) {
                        Text("Continue")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(coordinator.selectedGoal != nil ? Color.primary : Color.primary.opacity(0.5))
                            .cornerRadius(.radiusXL)
                            .shadow(
                                color: coordinator.selectedGoal != nil ? Color.primary.opacity(0.3) : .clear,
                                radius: 12,
                                x: 0,
                                y: 6
                            )
                    }
                    .disabled(coordinator.selectedGoal == nil)
                    
                    Button("Skip") {
                        Haptics.light()
                        coordinator.skip()
                    }
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.mutedForeground)
                }
                .padding(.horizontal, .spacingLG)
                .padding(.bottom, .spacing2XL)
            }
        }
        .background(Color.background)
        .onAppear {
            Task {
                await Analytics.shared.logOnboardingStepViewed(step: "goal_selection")
            }
        }
    }
}

// MARK: - Goal Card Component
struct GoalCard: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: .spacingMD) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .primary)
                    .frame(width: 44, height: 44)
                    .background(isSelected ? Color.primary.opacity(0.3) : Color.primary.opacity(0.1))
                    .cornerRadius(.radiusMD)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .foreground)
                    Text(description)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .mutedForeground)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .mutedForeground)
            }
            .padding(.spacingMD)
            .background(isSelected ? Color.primary : Color.surface)
            .cornerRadius(.radiusLG)
            .overlay(
                RoundedRectangle(cornerRadius: .radiusLG)
                    .stroke(isSelected ? Color.primary : Color.cardBorder, lineWidth: isSelected ? 2 : 1)
            )
            .shadow(
                color: isSelected ? Color.primary.opacity(0.2) : .clear,
                radius: isSelected ? 8 : 0,
                x: 0,
                y: isSelected ? 4 : 0
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    GoalSelectionView(coordinator: OnboardingCoordinator(dataStore: InMemoryDataStore()))
}


