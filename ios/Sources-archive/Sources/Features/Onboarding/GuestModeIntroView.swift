import SwiftUI

struct GuestModeIntroView: View {
    let onContinue: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacingXL) {
                    // Header
                    VStack(spacing: .spacingMD) {
                        Image(systemName: "person.fill.questionmark")
                            .font(.system(size: 48))
                            .foregroundColor(Color.adaptivePrimary(colorScheme))

                        Text("Try Nuzzle without an account")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color.adaptiveForeground(colorScheme))

                        Text("Log unlimited events and use all core features. Your data stays on your device.")
                            .font(.body)
                            .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, .spacingMD)

                    // Features
                    VStack(alignment: .leading, spacing: .spacingMD) {
                        Text("What you can do:")
                            .font(.headline)
                            .foregroundColor(Color.adaptiveForeground(colorScheme))

                        FeatureRow(icon: "checkmark.circle.fill", text: "Log feeds, sleep, diapers, and more")
                        FeatureRow(icon: "checkmark.circle.fill", text: "Get nap predictions and insights")
                        FeatureRow(icon: "checkmark.circle.fill", text: "View timeline and history")
                        FeatureRow(icon: "checkmark.circle.fill", text: "Export your data")
                    }
                    .padding(.horizontal, .spacingMD)

                    // Limitations
                    VStack(alignment: .leading, spacing: .spacingMD) {
                        Text("What requires an account:")
                            .font(.headline)
                            .foregroundColor(Color.adaptiveForeground(colorScheme))

                        FeatureRow(icon: "lock.fill", text: "Sync across devices")
                        FeatureRow(icon: "lock.fill", text: "Backup your data")
                        FeatureRow(icon: "lock.fill", text: "Share with caregivers")
                        FeatureRow(icon: "lock.fill", text: "Advanced AI features")
                    }
                    .padding(.horizontal, .spacingMD)

                    Spacer()

                    // Continue button
                    VStack(spacing: .spacingMD) {
                        PrimaryButton("Continue with guest mode") {
                            Haptics.success()
                            onContinue()
                        }

                        Text("You can create an account later to unlock sync and backup")
                            .font(.caption)
                            .foregroundColor(Color.adaptiveTextTertiary(colorScheme))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, .spacingMD)
                    }
                }
                .padding(.vertical, .spacing2XL)
            }
            .navigationTitle("Guest Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        dismiss()
                    }
                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                }
            }
        }
        .presentationDetents([.large])
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: .spacingMD) {
            Image(systemName: icon)
                .foregroundColor(icon == "checkmark.circle.fill" ? .green : Color.adaptiveTextSecondary(colorScheme))
                .frame(width: 20)

            Text(text)
                .font(.body)
                .foregroundColor(Color.adaptiveForeground(colorScheme))
        }
    }
}

#Preview {
    GuestModeIntroView(onContinue: {})
}


