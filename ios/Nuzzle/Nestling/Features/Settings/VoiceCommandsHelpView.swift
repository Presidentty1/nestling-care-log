import SwiftUI

/// Help view showing available voice commands and Siri shortcuts
struct VoiceCommandsHelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .spacingXL) {
                // Header
                VStack(alignment: .leading, spacing: .spacingSM) {
                    Text("Voice Commands & Siri Shortcuts")
                        .font(.headingLG)
                        .foregroundColor(.foreground)

                    Text("Say \"Hey Siri\" followed by any of these commands")
                        .font(.bodyMD)
                        .foregroundColor(.mutedForeground)
                }

                // Setup instructions
                VStack(alignment: .leading, spacing: .spacingMD) {
                    Text("First Time Setup")
                        .font(.headingMD)
                        .foregroundColor(.foreground)

                    VStack(alignment: .leading, spacing: .spacingSM) {
                        StepView(
                            number: 1,
                            instruction: "Go to Settings > Siri & Search"
                        )

                        StepView(
                            number: 2,
                            instruction: "Make sure \"Listen for 'Hey Siri'\" is enabled"
                        )

                        StepView(
                            number: 3,
                            instruction: "Enable Nestling in \"App Shortcuts\" section"
                        )
                    }
                }
                .padding(.spacingLG)
                .background(Color.surface)
                .cornerRadius(.radiusLG)

                // Logging commands
                VStack(alignment: .leading, spacing: .spacingMD) {
                    Text("Log Events")
                        .font(.headingMD)
                        .foregroundColor(.foreground)

                    CommandGroup(
                        title: "Feed",
                        icon: "drop.fill",
                        iconColor: .eventFeed,
                        commands: [
                            "Baby just ate",
                            "Log that baby ate",
                            "Baby finished feeding",
                            "Just fed the baby",
                            "Baby had a bottle",
                            "Baby nursed",
                            "Log a feed in Nestling"
                        ]
                    )

                    CommandGroup(
                        title: "Sleep",
                        icon: "moon.fill",
                        iconColor: .eventSleep,
                        commands: [
                            "Baby is sleeping",
                            "Baby went to sleep",
                            "Start sleep timer",
                            "Baby fell asleep",
                            "Put baby down for nap",
                            "Start sleep timer in Nestling",
                            "Stop sleep timer in Nestling"
                        ]
                    )

                    CommandGroup(
                        title: "Diaper",
                        icon: "drop.circle.fill",
                        iconColor: .eventDiaper,
                        commands: [
                            "Changed baby's diaper",
                            "Baby had a wet diaper",
                            "Baby had a dirty diaper",
                            "Just changed diaper",
                            "Log diaper change in Nestling"
                        ]
                    )

                    CommandGroup(
                        title: "Tummy Time",
                        icon: "figure.child",
                        iconColor: .eventTummy,
                        commands: [
                            "Log tummy time in Nestling",
                            "Start tummy time in Nestling"
                        ]
                    )
                }

                // Query commands
                VStack(alignment: .leading, spacing: .spacingMD) {
                    Text("Ask Questions")
                        .font(.headingMD)
                        .foregroundColor(.foreground)

                    CommandGroup(
                        title: "Last Events",
                        icon: "clock.fill",
                        iconColor: .info,
                        commands: [
                            "When was last feed in Nestling",
                            "When was last diaper change in Nestling",
                            "When was last nap in Nestling",
                            "How long since last feed in Nestling"
                        ]
                    )
                }

                // Tips
                VStack(alignment: .leading, spacing: .spacingMD) {
                    Text("Tips for Best Results")
                        .font(.headingMD)
                        .foregroundColor(.foreground)

                    VStack(alignment: .leading, spacing: .spacingSM) {
                        TipView(
                            icon: "mic.fill",
                            text: "Speak clearly and at normal volume"
                        )

                        TipView(
                            icon: "wifi",
                            text: "Make sure you have internet connection for best recognition"
                        )

                        TipView(
                            icon: "hand.raised.fill",
                            text: "Hold your phone naturally - don't speak directly into the microphone"
                        )

                        TipView(
                            icon: "checkmark.circle.fill",
                            text: "Test with simple commands first, then try more natural phrases"
                        )
                    }
                }
                .padding(.spacingLG)
                .background(Color.surface)
                .cornerRadius(.radiusLG)
            }
            .padding(.spacingLG)
        }
        .background(Color.background)
        .navigationTitle("Voice Commands")
    }
}

struct StepView: View {
    let number: Int
    let instruction: String

    var body: some View {
        HStack(alignment: .top, spacing: .spacingMD) {
            ZStack {
                Circle()
                    .fill(Color.primary.opacity(0.1))
                    .frame(width: 28, height: 28)

                Text("\(number)")
                    .font(.body.weight(.bold))
                    .foregroundColor(.primary)
            }

            Text(instruction)
                .font(.body)
                .foregroundColor(.foreground)
                .multilineTextAlignment(.leading)
        }
    }
}

struct CommandGroup: View {
    let title: String
    let icon: String
    let iconColor: Color
    let commands: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingSM) {
            HStack(spacing: .spacingSM) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.body)

                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundColor(.foreground)
            }

            VStack(alignment: .leading, spacing: .spacingXS) {
                ForEach(commands, id: \.self) { command in
                    HStack(spacing: .spacingSM) {
                        Text("•")
                            .foregroundColor(.mutedForeground)
                        Text("\"\(command)\"")
                            .font(.body)
                            .foregroundColor(.foreground)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
        }
        .padding(.spacingLG)
        .background(Color.surface)
        .cornerRadius(.radiusLG)
    }
}

struct TipView: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: .spacingMD) {
            Image(systemName: icon)
                .foregroundColor(.primary)
                .font(.body)
                .frame(width: 20)

            Text(text)
                .font(.body)
                .foregroundColor(.foreground)
                .multilineTextAlignment(.leading)
        }
    }
}

#Preview {
    NavigationView {
        VoiceCommandsHelpView()
    }
}