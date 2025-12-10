import SwiftUI

struct BabySetupView: View {
    @ObservedObject var coordinator: OnboardingCoordinator

    var body: some View {
        OnboardingContainer(
            title: "Tell us about your baby",
            subtitle: "Just the basics to get started. You can add more details later in Settings.",
            step: 1,
            totalSteps: 3,
            content: {
                VStack(alignment: .leading, spacing: .spacingLG) {
                    VStack(alignment: .leading, spacing: .spacingSM) {
                        Text("Baby's name")
                            .font(.body)
                            .foregroundColor(NuzzleTheme.textPrimary)
                        
                        TextField("Baby's name", text: $coordinator.babyName)
                            .textContentType(.name)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled(true)
                            .padding(.spacingMD)
                            .background(NuzzleTheme.surfaceSoft)
                            .cornerRadius(.radiusMD)
                            .accessibilityLabel("Baby's name")
                    }

                    VStack(alignment: .leading, spacing: .spacingSM) {
                        Text("Date of birth")
                            .font(.body)
                            .foregroundColor(NuzzleTheme.textPrimary)
                        
                        DatePicker(
                            "Date of birth",
                            selection: $coordinator.dateOfBirth,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .padding(.spacingMD)
                        .background(NuzzleTheme.surfaceSoft)
                        .cornerRadius(.radiusMD)
                        .accessibilityLabel("Date of birth")
                        .onChange(of: coordinator.dateOfBirth) { _, newDate in
                            // Check if baby is >6 months old (Epic 1 AC4)
                            let ageInMonths = Calendar.current.dateComponents([.month], from: newDate, to: Date()).month ?? 0
                            if ageInMonths > 6 {
                                coordinator.showAgeWarning = true
                            } else {
                                coordinator.showAgeWarning = false
                            }
                        }
                        
                        // Age >6mo warning (Epic 1 AC4)
                        if coordinator.showAgeWarning {
                            HStack(spacing: .spacingSM) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(NuzzleTheme.accentDiaper)
                                    .font(.caption)
                                Text("Nuzzle is optimized for 0-6 months. You can still use it, but guidance is best for early months.")
                                    .font(.caption)
                                    .foregroundColor(NuzzleTheme.textSecondary)
                            }
                            .padding(.spacingSM)
                            .background(NuzzleTheme.surfaceSoft)
                            .cornerRadius(.radiusSM)
                        }
                    }
                }
            },
            primaryTitle: "Continue",
            primaryAction: { coordinator.next() },
            secondaryTitle: "Skip for now",
            secondaryAction: { coordinator.skip() }
        )
    }
}

#Preview {
    BabySetupView(coordinator: OnboardingCoordinator(dataStore: InMemoryDataStore()))
}


