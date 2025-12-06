import SwiftUI

struct SiriShortcutsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacingXL) {
                    // Header
                    VStack(spacing: .spacingMD) {
                        Image(systemName: "waveform")
                            .font(.system(size: 64))
                            .foregroundColor(Color.adaptivePrimary(colorScheme))

                        Text("Siri Shortcuts")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color.adaptiveForeground(colorScheme))

                        Text("Control Nestling with your voice")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                    }
                    .padding(.horizontal, .spacingMD)

                    // Available Shortcuts
                    VStack(alignment: .leading, spacing: .spacingMD) {
                        Text("Available Shortcuts")
                            .font(.headline)
                            .foregroundColor(Color.adaptiveForeground(colorScheme))

                        VStack(spacing: .spacingMD) {
                            ShortcutCard(
                                title: "Log Feed",
                                phrases: ["Log a feed", "Feed time", "Baby ate"],
                                description: "Quickly log a feeding session"
                            )

                            ShortcutCard(
                                title: "Start Sleep Timer",
                                phrases: ["Start sleep", "Baby is sleeping", "Put baby down"],
                                description: "Begin tracking sleep time"
                            )

                            ShortcutCard(
                                title: "Stop Sleep Timer",
                                phrases: ["Stop sleep", "Baby woke up", "End sleep"],
                                description: "Complete the current sleep session"
                            )

                            ShortcutCard(
                                title: "Log Diaper Change",
                                phrases: ["Log diaper", "Change diaper", "Wet diaper"],
                                description: "Record a diaper change"
                            )

                            ShortcutCard(
                                title: "Check Next Nap",
                                phrases: ["When next nap", "Nap time", "When should baby nap"],
                                description: "Ask about the next predicted nap time"
                            )
                        }
                    }
                    .padding(.horizontal, .spacingMD)

                    // Setup Instructions
                    VStack(alignment: .leading, spacing: .spacingMD) {
                        Text("How to Set Up")
                            .font(.headline)
                            .foregroundColor(Color.adaptiveForeground(colorScheme))

                        VStack(alignment: .leading, spacing: .spacingSM) {
                            InstructionRow(step: 1, text: "Open the Shortcuts app on your iPhone")
                            InstructionRow(step: 2, text: "Tap the '+' button to create a new shortcut")
                            InstructionRow(step: 3, text: "Add an 'Automation' and choose 'App Shortcut'")
                            InstructionRow(step: 4, text: "Select Nestling from the app list")
                            InstructionRow(step: 5, text: "Choose your shortcut and customize phrases")
                        }
                    }
                    .padding(.spacingMD)
                    .background(Color.adaptiveSurface(colorScheme))
                    .cornerRadius(.radiusMD)
                    .padding(.horizontal, .spacingMD)

                    // Voice Control Tips
                    VStack(alignment: .leading, spacing: .spacingMD) {
                        Text("Voice Control Tips")
                            .font(.headline)
                            .foregroundColor(Color.adaptiveForeground(colorScheme))

                        VStack(alignment: .leading, spacing: .spacingSM) {
                            TipRow(text: "Be specific with your requests")
                            TipRow(text: "Use natural language like 'baby had a bottle'")
                            TipRow(text: "Try different phrases if Siri doesn't understand")
                            TipRow(text: "Shortcuts work even when your phone is locked")
                        }
                    }
                    .padding(.spacingMD)
                    .background(Color.adaptiveSurface(colorScheme))
                    .cornerRadius(.radiusMD)
                    .padding(.horizontal, .spacingMD)

                    Spacer()
                }
                .padding(.vertical, .spacing2XL)
            }
            .navigationTitle("Siri Shortcuts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                }
            }
        }
    }
}

struct ShortcutCard: View {
    let title: String
    let phrases: [String]
    let description: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingSM) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color.adaptiveForeground(colorScheme))

                Spacer()

                Image(systemName: "waveform")
                    .foregroundColor(Color.adaptivePrimary(colorScheme))
            }

            Text(description)
                .font(.caption)
                .foregroundColor(Color.adaptiveTextSecondary(colorScheme))

            VStack(alignment: .leading, spacing: 4) {
                Text("Example phrases:")
                    .font(.caption2)
                    .foregroundColor(Color.adaptiveTextTertiary(colorScheme))

                ForEach(phrases, id: \.self) { phrase in
                    Text("\"\(phrase)\"")
                        .font(.caption)
                        .foregroundColor(Color.adaptivePrimary(colorScheme))
                        .italic()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.adaptivePrimary(colorScheme).opacity(0.1))
                        .cornerRadius(4)
                }
            }
        }
        .padding(.spacingMD)
        .background(Color.adaptiveSurface(colorScheme))
        .cornerRadius(.radiusMD)
    }
}

struct InstructionRow: View {
    let step: Int
    let text: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: .spacingMD) {
            Text("\(step)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(Color.adaptivePrimary(colorScheme))
                .frame(width: 20, height: 20)
                .background(Color.adaptivePrimary(colorScheme).opacity(0.2))
                .clipShape(Circle())

            Text(text)
                .font(.body)
                .foregroundColor(Color.adaptiveForeground(colorScheme))
        }
    }
}

struct TipRow: View {
    let text: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: .spacingSM) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
                .font(.system(size: 14))

            Text(text)
                .font(.body)
                .foregroundColor(Color.adaptiveForeground(colorScheme))
        }
    }
}