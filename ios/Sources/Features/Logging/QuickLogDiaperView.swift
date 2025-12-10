import SwiftUI

/// Bottom sheet for quick diaper logging with presets
struct QuickLogDiaperView: View {
    @Environment(\.dismiss) var dismiss
    @State private var notes: String = ""
    @State private var isLoading = false

    let onComplete: (Event) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacingLG) {
                    // Header
                    VStack(spacing: .spacingSM) {
                        Text("Quick Diaper Log")
                            .font(.title2.bold())
                            .foregroundColor(NuzzleTheme.textPrimary)

                        Text("Choose what you found")
                            .font(.body)
                            .foregroundColor(NuzzleTheme.textSecondary)
                    }
                    .padding(.horizontal, .spacingMD)
                    .padding(.top, .spacingMD)

                    // Preset buttons
                    VStack(spacing: .spacingMD) {
                        DiaperPresetButton(
                            title: "Wet",
                            subtitle: "Just wet",
                            color: NuzzleTheme.accentDiaper,
                            action: { logDiaper(wet: true, dirty: false) }
                        )

                        DiaperPresetButton(
                            title: "Dirty",
                            subtitle: "Just dirty",
                            color: NuzzleTheme.accentDiaper,
                            action: { logDiaper(wet: false, dirty: true) }
                        )

                        DiaperPresetButton(
                            title: "Both",
                            subtitle: "Wet and dirty",
                            color: NuzzleTheme.accentDiaper,
                            action: { logDiaper(wet: true, dirty: true) }
                        )
                    }
                    .padding(.horizontal, .spacingMD)

                    // Optional notes
                    VStack(alignment: .leading, spacing: .spacingSM) {
                        Text("Notes (Optional)")
                            .font(.headline)
                            .foregroundColor(NuzzleTheme.textPrimary)

                        TextField("Any additional notes...", text: $notes)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, .spacingMD)

                    Spacer(minLength: .spacing2XL)
                }
            }
            .background(NuzzleTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func logDiaper(wet: Bool, dirty: Bool) {
        isLoading = true

        // Determine subtype based on wet/dirty combination
        let subtype: String
        if wet && dirty {
            subtype = "both"
        } else if wet {
            subtype = "wet"
        } else if dirty {
            subtype = "dirty"
        } else {
            subtype = "diaper" // fallback
        }

        // Create the diaper event
        let diaperEvent = Event(
            babyId: UUID(), // This would be passed in or retrieved from context
            type: .diaper,
            subtype: subtype,
            startTime: Date(),
            note: notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes
        )

        // Provide haptic feedback
        Haptics.success()

        // Call completion handler
        onComplete(diaperEvent)

        // Dismiss the sheet
        dismiss()
    }
}

/// Preset button for diaper logging
struct DiaperPresetButton: View {
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: .spacingMD) {
                // Color indicator
                Circle()
                    .fill(color)
                    .frame(width: 16, height: 16)

                VStack(alignment: .leading, spacing: .spacingXS) {
                    Text(title)
                        .font(.body.bold())
                        .foregroundColor(NuzzleTheme.textPrimary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(NuzzleTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.spacingMD)
            .background(NuzzleTheme.surface)
            .cornerRadius(.radiusMD)
            .overlay(
                RoundedRectangle(cornerRadius: .radiusMD)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    QuickLogDiaperView { event in
        print("Logged diaper: \(event.displayText)")
    }
}


