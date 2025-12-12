import SwiftUI

struct GoalSelectionView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    
    let focusOptions: [(area: FocusArea, icon: String, description: String)] = [
        (.napsAndNights, "moon.zzz.fill", "Get smart nap windows and sleep tracking"),
        (.feedsAndDiapers, "drop.fill", "Monitor feeds, bottles, and diaper changes"),
        (.cries, "waveform", "Understand possible reasons for crying"),
        (.all, "sparkles", "I need help with everything")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: .spacingXL) {
                VStack(spacing: .spacingSM) {
                    Text("What do you need most right now?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.foreground)
                        .multilineTextAlignment(.center)
                    
                    Text("We'll tune your home screen around this")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.mutedForeground)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, .spacingXL)
                
                VStack(spacing: .spacingMD) {
                    ForEach(focusOptions, id: \.area) { option in
                        FocusAreaCard(
                            title: option.area.displayName,
                            description: option.description,
                            icon: option.icon,
                            isSelected: coordinator.selectedFocusAreas.contains(option.area),
                            action: {
                                if option.area == .all {
                                    // "All" acts like select all
                                    if coordinator.selectedFocusAreas.contains(.all) {
                                        coordinator.selectedFocusAreas.removeAll()
                                    } else {
                                        coordinator.selectedFocusAreas = Set(FocusArea.allCases)
                                    }
                                } else {
                                    // Toggle individual selection
                                    if coordinator.selectedFocusAreas.contains(option.area) {
                                        coordinator.selectedFocusAreas.remove(option.area)
                                        coordinator.selectedFocusAreas.remove(.all)
                                    } else {
                                        coordinator.selectedFocusAreas.insert(option.area)
                                        // If all others are selected, also select "all"
                                        let others: Set<FocusArea> = [.napsAndNights, .feedsAndDiapers, .cries]
                                        if others.isSubset(of: coordinator.selectedFocusAreas) {
                                            coordinator.selectedFocusAreas.insert(.all)
                                        }
                                    }
                                }
                                Haptics.selection()
                                Task {
                                    await Analytics.shared.logOnboardingGoalSelected(goal: option.area.rawValue)
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
                            .background(!coordinator.selectedFocusAreas.isEmpty ? Color.primary : Color.primary.opacity(0.5))
                            .cornerRadius(.radiusXL)
                            .shadow(
                                color: !coordinator.selectedFocusAreas.isEmpty ? Color.primary.opacity(0.3) : .clear,
                                radius: 12,
                                x: 0,
                                y: 6
                            )
                    }
                    .disabled(coordinator.selectedFocusAreas.isEmpty)
                    
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

// MARK: - Focus Area Card Component
struct FocusAreaCard: View {
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






