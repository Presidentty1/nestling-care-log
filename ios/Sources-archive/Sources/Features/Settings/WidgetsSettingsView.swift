import SwiftUI

struct WidgetsSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacingXL) {
                    // Header
                    VStack(spacing: .spacingMD) {
                        Image(systemName: "widget.small")
                            .font(.system(size: 64))
                            .foregroundColor(Color.adaptivePrimary(colorScheme))

                        Text("Home Screen Widgets")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color.adaptiveForeground(colorScheme))

                        Text("Add Nestling to your home screen for instant access to logging")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                    }
                    .padding(.horizontal, .spacingMD)

                    // Widget Preview
                    VStack(alignment: .leading, spacing: .spacingMD) {
                        Text("Quick Log Widget")
                            .font(.headline)
                            .foregroundColor(Color.adaptiveForeground(colorScheme))

                        Text("Log feeds, sleep, and diapers without opening the app")
                            .font(.body)
                            .foregroundColor(Color.adaptiveTextSecondary(colorScheme))

                        // Mock widget preview
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.adaptiveSurface(colorScheme))
                                .frame(height: 120)
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "heart.fill")
                                        .foregroundColor(.red)
                                    Spacer()
                                    Text("Emma")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Text("Last feed 2h ago")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                HStack(spacing: 8) {
                                    WidgetButtonPreview(icon: "bottle.fill", color: .blue, title: "Feed")
                                    WidgetButtonPreview(icon: "arrow.triangle.2.circlepath.circle.fill", color: .green, title: "Diaper")
                                }
                            }
                            .padding(12)
                        }
                    }
                    .padding(.horizontal, .spacingMD)

                    // Setup Instructions
                    VStack(alignment: .leading, spacing: .spacingMD) {
                        Text("How to Add")
                            .font(.headline)
                            .foregroundColor(Color.adaptiveForeground(colorScheme))

                        VStack(alignment: .leading, spacing: .spacingSM) {
                            InstructionRow(step: 1, text: "Long press on an empty area of your home screen")
                            InstructionRow(step: 2, text: "Tap the '+' button in the top left")
                            InstructionRow(step: 3, text: "Search for 'Nestling' and select Quick Log")
                            InstructionRow(step: 4, text: "Choose your widget size and tap 'Add Widget'")
                        }
                    }
                    .padding(.spacingMD)
                    .background(Color.adaptiveSurface(colorScheme))
                    .cornerRadius(.radiusMD)
                    .padding(.horizontal, .spacingMD)

                    // Siri Shortcuts
                    VStack(alignment: .leading, spacing: .spacingMD) {
                        Text("Siri Shortcuts")
                            .font(.headline)
                            .foregroundColor(Color.adaptiveForeground(colorScheme))

                        Text("Use Siri to log events hands-free")
                            .font(.body)
                            .foregroundColor(Color.adaptiveTextSecondary(colorScheme))

                        VStack(alignment: .leading, spacing: .spacingSM) {
                            ShortcutExample(phrase: "\"Hey Siri, log a feed\"")
                            ShortcutExample(phrase: "\"Hey Siri, start sleep timer\"")
                            ShortcutExample(phrase: "\"When is baby's next nap?\"")
                        }

                        NavigationLink("Set Up Siri Shortcuts") {
                            SiriShortcutsView()
                        }
                        .padding(.top, .spacingSM)
                    }
                    .padding(.spacingMD)
                    .background(Color.adaptiveSurface(colorScheme))
                    .cornerRadius(.radiusMD)
                    .padding(.horizontal, .spacingMD)

                    Spacer()
                }
                .padding(.vertical, .spacing2XL)
            }
            .navigationTitle("Widgets & Shortcuts")
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

struct WidgetButtonPreview: View {
    let icon: String
    let color: Color
    let title: String

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)

            Text(title)
                .font(.caption2)
                .foregroundColor(.primary)
        }
        .frame(width: 32, height: 32)
        .background(Color.white.opacity(0.3))
        .cornerRadius(6)
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

struct ShortcutExample: View {
    let phrase: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack {
            Image(systemName: "quote.opening")
                .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
            Text(phrase)
                .font(.body)
                .foregroundColor(Color.adaptiveForeground(colorScheme))
                .italic()
            Image(systemName: "quote.closing")
                .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
        }
        .padding(.horizontal, .spacingMD)
        .padding(.vertical, .spacingXS)
        .background(Color.adaptiveSurface(colorScheme).opacity(0.5))
        .cornerRadius(.radiusSM)
    }
}


