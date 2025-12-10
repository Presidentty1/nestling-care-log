import SwiftUI

/// Bottom sheet for quick tummy time logging with duration presets
struct QuickLogTummyTimeView: View {
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
                        Text("Quick Tummy Time Log")
                            .font(.title2.bold())
                            .foregroundColor(NuzzleTheme.textPrimary)

                        Text("Choose a duration")
                            .font(.body)
                            .foregroundColor(NuzzleTheme.textSecondary)
                    }
                    .padding(.horizontal, .spacingMD)
                    .padding(.top, .spacingMD)

                    // Duration preset buttons
                    VStack(spacing: .spacingMD) {
                        DurationPresetButton(
                            title: "5 minutes",
                            subtitle: "Quick session",
                            durationMinutes: 5,
                            color: NuzzleTheme.accentTummy,
                            action: { logTummyTime(durationMinutes: 5) }
                        )

                        DurationPresetButton(
                            title: "10 minutes",
                            subtitle: "Standard session",
                            durationMinutes: 10,
                            color: NuzzleTheme.accentTummy,
                            action: { logTummyTime(durationMinutes: 10) }
                        )

                        DurationPresetButton(
                            title: "15 minutes",
                            subtitle: "Extended session",
                            durationMinutes: 15,
                            color: NuzzleTheme.accentTummy,
                            action: { logTummyTime(durationMinutes: 15) }
                        )

                        DurationPresetButton(
                            title: "20 minutes",
                            subtitle: "Long session",
                            durationMinutes: 20,
                            color: NuzzleTheme.accentTummy,
                            action: { logTummyTime(durationMinutes: 20) }
                        )
                    }
                    .padding(.horizontal, .spacingMD)

                    // Optional notes
                    VStack(alignment: .leading, spacing: .spacingSM) {
                        Text("Notes (Optional)")
                            .font(.headline)
                            .foregroundColor(NuzzleTheme.textPrimary)

                        TextField("How did it go?", text: $notes)
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

    private func logTummyTime(durationMinutes: Int) {
        isLoading = true

        // Calculate start and end times
        let endTime = Date()
        let startTime = Calendar.current.date(byAdding: .minute, value: -durationMinutes, to: endTime) ?? endTime

        // Create the tummy time event
        let tummyTimeEvent = Event(
            babyId: UUID(), // This would be passed in or retrieved from context
            type: .tummyTime,
            startTime: startTime,
            endTime: endTime,
            note: notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes
        )

        // Provide haptic feedback
        Haptics.success()

        // Call completion handler
        onComplete(tummyTimeEvent)

        // Dismiss the sheet
        dismiss()
    }
}

/// Preset button for tummy time duration
struct DurationPresetButton: View {
    let title: String
    let subtitle: String
    let durationMinutes: Int
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
    QuickLogTummyTimeView { event in
        print("Logged tummy time: \(event.displayText)")
    }
}



