import SwiftUI

struct GoalSelectionView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.colorScheme) private var colorScheme

    let goals = [
        Goal(id: "better_naps", title: "Better naps", description: "Track patterns and get nap predictions", icon: "moon.stars"),
        Goal(id: "track_feeds", title: "Track feeds", description: "Monitor feeding schedules and amounts", icon: "bottle"),
        Goal(id: "coordinate_caregiver", title: "Coordinate with partner", description: "Share logs and handoffs seamlessly", icon: "person.2"),
        Goal(id: "ai_predictions", title: "Use AI predictions", description: "Get smart insights and recommendations", icon: "brain"),
        Goal(id: "just_logging", title: "Just logging", description: "Keep track of daily routines", icon: "checkmark.circle"),
    ]

    var body: some View {
        VStack(spacing: .spacingXL) {
            // Header
            VStack(spacing: .spacingMD) {
                Text("What's your main goal with Nuzzle?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color.adaptiveForeground(colorScheme))

                Text("This helps us personalize your experience")
                    .font(.body)
                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, .spacingMD)

            // Goal options
            VStack(spacing: .spacingMD) {
                ForEach(goals) { goal in
                    GoalOptionView(
                        goal: goal,
                        isSelected: coordinator.primaryGoal == goal.id,
                        action: {
                            coordinator.primaryGoal = goal.id
                            Haptics.light()
                        }
                    )
                }
            }
            .padding(.horizontal, .spacingMD)

            Spacer()

            // Bottom buttons
            VStack(spacing: .spacingMD) {
                PrimaryButton("Continue") {
                    // Log goal selection analytics
                    Task {
                        await Analytics.shared.log("onboarding_goal_selected", parameters: [
                            "goal": coordinator.primaryGoal,
                            "step": 2
                        ])
                    }
                    coordinator.next()
                }
                .disabled(coordinator.primaryGoal.isEmpty)

                SecondaryButton("Skip for now") {
                    coordinator.primaryGoal = "" // Empty string for skipped
                    // Log skipped goal selection
                    Task {
                        await Analytics.shared.log("onboarding_goal_selected", parameters: [
                            "goal": "skipped",
                            "step": 2
                        ])
                    }
                    coordinator.next()
                }
            }
            .padding(.horizontal, .spacingMD)
        }
        .padding(.vertical, .spacing2XL)
        .background(Color.adaptiveBackground(colorScheme))
    }
}

struct Goal: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
}

struct GoalOptionView: View {
    let goal: Goal
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: .spacingMD) {
                Image(systemName: goal.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? Color.adaptivePrimary(colorScheme) : Color.adaptiveTextSecondary(colorScheme))
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: .spacingXS) {
                    Text(goal.title)
                        .font(.headline)
                        .foregroundColor(Color.adaptiveForeground(colorScheme))

                    Text(goal.description)
                        .font(.subheadline)
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                        .lineLimit(2)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.adaptivePrimary(colorScheme))
                        .font(.system(size: 20))
                } else {
                    Circle()
                        .stroke(Color.adaptiveTextTertiary(colorScheme), lineWidth: 1)
                        .frame(width: 20, height: 20)
                }
            }
            .padding(.spacingMD)
            .background(
                RoundedRectangle(cornerRadius: .radiusMD)
                    .fill(isSelected ? Color.adaptivePrimary(colorScheme).opacity(0.1) : Color.adaptiveSurface(colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: .radiusMD)
                    .stroke(isSelected ? Color.adaptivePrimary(colorScheme) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    let coordinator = OnboardingCoordinator(dataStore: InMemoryDataStore()) {}
    GoalSelectionView(coordinator: coordinator)
}