import SwiftUI

struct InitialStateView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @State private var selectedState: BabyState? = nil
    
    enum BabyState: String {
        case asleep
        case awake
        
        var displayName: String {
            switch self {
            case .asleep: return "Asleep"
            case .awake: return "Awake"
            }
        }
        
        var icon: String {
            switch self {
            case .asleep: return "moon.zzz.fill"
            case .awake: return "sun.max.fill"
            }
        }
    }
    
    var body: some View {
        OnboardingContainer(
            title: "Right now, is \(coordinator.babyName.isEmpty ? "your baby" : coordinator.babyName) asleep or awake?",
            subtitle: "This helps us show you the right guidance right away",
            step: 3,
            totalSteps: 3,
            content: {
                VStack(spacing: .spacingLG) {
                    // Large buttons for asleep/awake
                    VStack(spacing: .spacingMD) {
                        StateButton(
                            state: .asleep,
                            isSelected: selectedState == .asleep,
                            action: {
                                selectedState = .asleep
                                Haptics.medium()
                            }
                        )
                        
                        StateButton(
                            state: .awake,
                            isSelected: selectedState == .awake,
                            action: {
                                selectedState = .awake
                                Haptics.medium()
                            }
                        )
                    }
                    .padding(.horizontal, .spacingMD)
                }
            },
            primaryTitle: "Continue",
            primaryAction: {
                if let state = selectedState {
                    coordinator.initialBabyState = state.rawValue
                    coordinator.next()
                }
            },
            primaryDisabled: selectedState == nil,
            secondaryTitle: "Skip for now",
            secondaryAction: {
                coordinator.initialBabyState = nil
                coordinator.next()
            }
        )
    }
}

struct StateButton: View {
    let state: InitialStateView.BabyState
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: .spacingMD) {
                Image(systemName: state.icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? NuzzleTheme.primaryForeground : NuzzleTheme.textSecondary)
                    .frame(width: 44, height: 44)
                
                Text(state.displayName)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? NuzzleTheme.primaryForeground : NuzzleTheme.textPrimary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(NuzzleTheme.primaryForeground)
                        .font(.system(size: 24))
                }
            }
            .padding(.spacingXL)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: .radiusLG)
                    .fill(isSelected ? NuzzleTheme.primary : NuzzleTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: .radiusLG)
                    .stroke(isSelected ? NuzzleTheme.primary : NuzzleTheme.borderLight, lineWidth: isSelected ? 3 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(state.displayName) state")
        .accessibilityHint("Double tap to select \(state.displayName.lowercased())")
    }
}

#Preview {
    let coordinator = OnboardingCoordinator(dataStore: InMemoryDataStore()) {}
    coordinator.babyName = "Emma"
    return InitialStateView(coordinator: coordinator)
}
