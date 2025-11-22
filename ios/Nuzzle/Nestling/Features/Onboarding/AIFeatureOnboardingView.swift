import SwiftUI

enum AIFeatureType {
    case cryInsights
    case aiAssistant

    var title: String {
        switch self {
        case .cryInsights: return "Introducing Cry Insights (Beta)"
        case .aiAssistant: return "Introducing AI Assistant"
        }
    }

    var icon: String {
        switch self {
        case .cryInsights: return "waveform"
        case .aiAssistant: return "brain.head.profile"
        }
    }
}

struct AIFeatureOnboardingView: View {
    let feature: AIFeatureType
    @Environment(\.dismiss) var dismiss
    @State private var dontShowAgain = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacingLG) {
                    // Header
                    VStack(spacing: .spacingMD) {
                        Image(systemName: feature.icon)
                            .font(.system(size: 60))
                            .foregroundColor(.primary)

                        Text(feature.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text("A gentle AI companion for your parenting journey")
                            .font(.subheadline)
                            .foregroundColor(.mutedForeground)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, .spacingXL)

                    // What it does
                    CardView(variant: .default) {
                        VStack(alignment: .leading, spacing: .spacingMD) {
                            Text("What \(feature == .cryInsights ? "Cry Insights" : "AI Assistant") can do")
                                .font(.headline)

                            VStack(alignment: .leading, spacing: .spacingSM) {
                                switch feature {
                                case .cryInsights:
                                    BulletPoint("Analyze your baby's cry patterns")
                                    BulletPoint("Suggest possible reasons (hungry, tired, discomfort, pain)")
                                    BulletPoint("Provide gentle guidance on what to try next")
                                case .aiAssistant:
                                    BulletPoint("Answer parenting questions based on your baby's data")
                                    BulletPoint("Provide guidance on feeding, sleep, and development")
                                    BulletPoint("Offer personalized tips based on your patterns")
                                }
                            }
                        }
                        .padding(.spacingMD)
                    }
                    .padding(.horizontal, .spacingMD)

                    // What it doesn't do
                    CardView(variant: .default) {
                        VStack(alignment: .leading, spacing: .spacingMD) {
                            Text("What it doesn't do")
                                .font(.headline)

                            VStack(alignment: .leading, spacing: .spacingSM) {
                                BulletPoint("Replace professional medical advice")
                                BulletPoint("Diagnose medical conditions")
                                BulletPoint("Make treatment recommendations")
                            }

                            Text("Always consult your pediatrician for medical concerns.")
                                .font(.caption)
                                .foregroundColor(.mutedForeground)
                                .padding(.top, .spacingXS)
                        }
                        .padding(.spacingMD)
                    }
                    .padding(.horizontal, .spacingMD)

                    // Privacy
                    CardView(variant: .default) {
                        VStack(alignment: .leading, spacing: .spacingMD) {
                            Text("Your privacy matters")
                                .font(.headline)

                            VStack(alignment: .leading, spacing: .spacingSM) {
                                BulletPoint("Audio recordings are processed locally when possible")
                                BulletPoint("Data is encrypted and never sold")
                                BulletPoint("You control what gets shared")
                            }
                        }
                        .padding(.spacingMD)
                    }
                    .padding(.horizontal, .spacingMD)

                    // Examples (for Cry Insights)
                    if feature == .cryInsights {
                        CardView(variant: .default) {
                            VStack(alignment: .leading, spacing: .spacingMD) {
                                Text("Example insights")
                                    .font(.headline)

                                VStack(alignment: .leading, spacing: .spacingSM) {
                                    ExampleInsight(
                                        title: "Pattern Detected",
                                        insight: "\"This cry pattern may suggest hunger. Consider offering a feed if it's been 2-3 hours since the last one.\"",
                                        confidence: "85% confidence"
                                    )

                                    ExampleInsight(
                                        title: "Gentle Suggestion",
                                        insight: "\"This might indicate tiredness. Try dimming the lights and offering a quiet space for sleep.\"",
                                        confidence: "72% confidence"
                                    )
                                }
                            }
                            .padding(.spacingMD)
                        }
                        .padding(.horizontal, .spacingMD)
                    }

                    // Don't show again toggle
                    Toggle("Don't show this again", isOn: $dontShowAgain)
                        .padding(.horizontal, .spacingMD)
                        .padding(.top, .spacingMD)

                    // Continue button
                    PrimaryButton("Try \(feature == .cryInsights ? "Cry Insights" : "AI Assistant")") {
                        // Save preference if user chose not to show again
                        if dontShowAgain {
                            let key = feature == .cryInsights ? "cryInsightsOnboardingShown" : "aiAssistantOnboardingShown"
                            UserDefaults.standard.set(true, forKey: key)
                        }

                        dismiss()
                    }
                    .padding(.horizontal, .spacingMD)

                    // Skip button
                    Button("Maybe Later") {
                        dismiss()
                    }
                    .font(.subheadline)
                    .foregroundColor(.mutedForeground)
                    .padding(.spacingMD)
                }
                .padding(.bottom, .spacingXL)
            }
            .background(Color.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("✕") {
                        dismiss()
                    }
                    .font(.title2)
                    .foregroundColor(.mutedForeground)
                }
            }
        }
    }
}

private struct ExampleInsight: View {
    let title: String
    let insight: String
    let confidence: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text(confidence)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.primary.opacity(0.1))
                    .cornerRadius(8)
            }

            Text(insight)
                .font(.caption)
                .foregroundColor(.mutedForeground)
                .italic()
        }
        .padding(.vertical, .spacingXS)
    }
}

private struct BulletPoint: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        HStack(alignment: .top, spacing: .spacingSM) {
            Text("•")
                .foregroundColor(.primary)
                .font(.body)
            Text(text)
                .foregroundColor(.foreground)
                .font(.body)
                .multilineTextAlignment(.leading)
        }
    }
}

#Preview {
    AIFeatureOnboardingView(feature: .cryInsights)
}

