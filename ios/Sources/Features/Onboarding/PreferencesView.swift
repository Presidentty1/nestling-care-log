import SwiftUI

struct PreferencesView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    
    var body: some View {
        ScrollView {
            VStack(spacing: .spacingLG) {
                VStack(spacing: .spacingSM) {
                    Text("Your Preferences")
                        .font(.headline)
                        .foregroundColor(.foreground)
                    
                    Text("You can change these anytime in Settings")
                        .font(.body)
                        .foregroundColor(.mutedForeground)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, .spacing2XL)
                
                Form {
                    Section("Measurement Units") {
                        Picker("Units", selection: $coordinator.preferredUnit) {
                            Text("Milliliters (ml)").tag("ml")
                            Text("Ounces (oz)").tag("oz")
                        }
                    }
                    
                    Section("Time Format") {
                        Picker("Time Format", selection: $coordinator.timeFormat24Hour) {
                            Text("12-hour (3:00 PM)").tag(false)
                            Text("24-hour (15:00)").tag(true)
                        }
                    }
                }
                .frame(height: 200)
                
                VStack(spacing: .spacingSM) {
                    PrimaryButton("Continue") {
                        coordinator.next()
                    }
                    .padding(.horizontal, .spacingMD)
                    
                    Button("Skip") {
                        coordinator.skip()
                    }
                    .foregroundColor(.mutedForeground)
                }
                .padding(.bottom, .spacing2XL)
            }
        }
        .background(Color.background)
    }
}

#Preview {
    PreferencesView(coordinator: OnboardingCoordinator(dataStore: InMemoryDataStore()))
}


