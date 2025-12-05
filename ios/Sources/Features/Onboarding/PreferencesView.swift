import SwiftUI

struct PreferencesView: View {
    @ObservedObject var coordinator: OnboardingCoordinator

    var body: some View {
        OnboardingContainer(
            title: "Your preferences",
            subtitle: "You can change these anytime in Settings.",
            step: 3,
            totalSteps: 3,
            content: {
                VStack(spacing: .spacingLG) {
                    VStack(alignment: .leading, spacing: .spacingSM) {
                        Text("Feeding units")
                            .font(.body)
                            .foregroundColor(NuzzleTheme.textPrimary)

                        Picker("Feeding units", selection: $coordinator.preferredUnit) {
                            Text("Milliliters (ml)").tag("ml")
                            Text("Ounces (oz)").tag("oz")
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: .spacingSM) {
                        Text("Time format")
                            .font(.body)
                            .foregroundColor(NuzzleTheme.textPrimary)

                        Picker("Time format", selection: $coordinator.timeFormat24Hour) {
                            Text("12-hour (3:00 PM)").tag(false)
                            Text("24-hour (15:00)").tag(true)
                        }
                        .pickerStyle(.segmented)
                    }
                }
            },
            primaryTitle: "Continue",
            primaryAction: { coordinator.next() },
            secondaryTitle: "Skip",
            secondaryAction: { coordinator.skip() }
        )
    }
}

#Preview {
    PreferencesView(coordinator: OnboardingCoordinator(dataStore: InMemoryDataStore()))
}


