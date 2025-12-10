import SwiftUI

struct PaywallView: View {
    let feature: ProFeature
    let onUpgrade: () -> Void
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacingXL) {
                    // Feature preview
                    VStack(spacing: .spacingMD) {
                        Image(systemName: featureIcon(for: feature))
                            .font(.system(size: 64))
                            .foregroundColor(Color.adaptivePrimary(colorScheme))

                        Text(feature.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color.adaptiveForeground(colorScheme))

                        Text(feature.description)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                            .padding(.horizontal, .spacingMD)
                    }

                    // What you get
                    VStack(alignment: .leading, spacing: .spacingMD) {
                        Text("Unlock with Pro:")
                            .font(.headline)
                            .foregroundColor(Color.adaptiveForeground(colorScheme))

                        VStack(alignment: .leading, spacing: .spacingSM) {
                            FeatureBullet(text: "Advanced AI predictions")
                            FeatureBullet(text: "Smart notifications")
                            FeatureBullet(text: "Cry pattern analysis")
                            FeatureBullet(text: "Advanced export options")
                            FeatureBullet(text: "Family sharing")
                            FeatureBullet(text: "Priority support")
                        }
                    }
                    .padding(.horizontal, .spacingMD)

                    Spacer()

                    // CTA
                    VStack(spacing: .spacingMD) {
                        PrimaryButton("Try Pro free for 7 days") {
                            onUpgrade()
                        }

                        Text("Cancel anytime • No commitment")
                            .font(.caption)
                            .foregroundColor(Color.adaptiveTextTertiary(colorScheme))
                    }
                    .padding(.horizontal, .spacingMD)
                }
                .padding(.vertical, .spacing2XL)
            }
            .navigationTitle("Pro Feature")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Maybe Later") {
                        onDismiss()
                    }
                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                }
            }
        }
        .presentationDetents([.large])
    }

    private func featureIcon(for feature: ProFeature) -> String {
        switch feature {
        case .smartSuggestions: return "brain"
        case .intelligentReminders: return "bell.badge"
        case .cryAnalysis: return "waveform"
        case .advancedExport: return "square.and.arrow.up"
        case .csvExport: return "tablecells"
        case .familySharing: return "person.2"
        case .prioritySupport: return "star"
        }
    }
}

struct FeatureBullet: View {
    let text: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: .spacingSM) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 16))

            Text(text)
                .font(.body)
                .foregroundColor(Color.adaptiveForeground(colorScheme))
        }
    }
}

#Preview {
    PaywallView(feature: .smartSuggestions, onUpgrade: {}, onDismiss: {})
}

