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
                    Section {
                        Picker("Feeding units", selection: $coordinator.preferredUnit) {
                            Text("Milliliters (ml)").tag("ml")
                            Text("Ounces (oz)").tag("oz")
                        }
                        .pickerStyle(.segmented)
                        .padding(.vertical, 8)
                    } header: {
                        Text("Measurement Units")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.foreground)
                    }
                    
                    Section {
                        Picker("Time format", selection: $coordinator.timeFormat24Hour) {
                            Text("12-hour (3:00 PM)").tag(false)
                            Text("24-hour (15:00)").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .padding(.vertical, 8)
                    } header: {
                        Text("Time Format")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.foreground)
                    }
                }
                .frame(height: 280)
                
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
                            .background(Color.primary)
                            .cornerRadius(.radiusXL)
                            .shadow(color: Color.primary.opacity(0.3), radius: 12, x: 0, y: 6)
                    }
                    .padding(.horizontal, .spacingMD)
                    
                    Button("Maybe later") {
                        Haptics.light()
                        coordinator.skip()
                    }
                    .font(.system(size: 17, weight: .medium))
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

