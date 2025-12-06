import SwiftUI

/// Bottom sheet for quick feed logging with smart defaults
struct QuickLogFeedView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedSource: LogEntryFeedSource = .bottle
    @State private var amount: String = ""
    @State private var unit: String = "ml"
    @State private var selectedSide: LogEntryBreastSide?
    @State private var durationMinutes: String = ""
    @State private var isLoading = false

    let onComplete: (Event) -> Void

    // Smart defaults (would be passed in from NowViewModel)
    private let defaultAmount: Double = 120
    private let defaultUnit: String = "ml"
    private let defaultSource: LogEntryFeedSource = .bottle

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacingLG) {
                    // Header
                    VStack(spacing: .spacingSM) {
                        Text("Quick Feed Log")
                            .font(.title2.bold())
                            .foregroundColor(NuzzleTheme.textPrimary)

                        Text("Log a feed with your recent preferences")
                            .font(.body)
                            .foregroundColor(NuzzleTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, .spacingMD)
                    .padding(.top, .spacingMD)

                    // Feed Source Selection
                    VStack(alignment: .leading, spacing: .spacingSM) {
                        Text("Feed Source")
                            .font(.headline)
                            .foregroundColor(NuzzleTheme.textPrimary)

                        Picker("Source", selection: $selectedSource) {
                            ForEach(LogEntryFeedSource.allCases, id: \.self) { source in
                                Text(source.displayName).tag(source)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal, .spacingMD)

                    // Amount Input
                    VStack(alignment: .leading, spacing: .spacingSM) {
                        Text("Amount")
                            .font(.headline)
                            .foregroundColor(NuzzleTheme.textPrimary)

                        HStack(spacing: .spacingSM) {
                            TextField("Amount", text: $amount)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 120)

                            Picker("Unit", selection: $unit) {
                                Text("ml").tag("ml")
                                Text("oz").tag("oz")
                            }
                            .pickerStyle(.segmented)
                            .frame(maxWidth: 100)
                        }
                    }
                    .padding(.horizontal, .spacingMD)

                    // Breast feeding options (only show for breast sources)
                    if selectedSource == .breastLeft || selectedSource == .breastRight || selectedSource == .breastBoth {
                        VStack(alignment: .leading, spacing: .spacingSM) {
                            Text("Duration (Optional)")
                                .font(.headline)
                                .foregroundColor(NuzzleTheme.textPrimary)

                            TextField("Minutes", text: $durationMinutes)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 120)
                        }
                        .padding(.horizontal, .spacingMD)
                    }

                    // Quick preset buttons
                    VStack(alignment: .leading, spacing: .spacingSM) {
                        Text("Quick Amounts")
                            .font(.headline)
                            .foregroundColor(NuzzleTheme.textPrimary)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: .spacingSM) {
                            QuickAmountButton(amount: unit == "ml" ? 60 : 2, unit: unit, action: { setAmount(unit == "ml" ? 60 : 2) })
                            QuickAmountButton(amount: unit == "ml" ? 120 : 4, unit: unit, action: { setAmount(unit == "ml" ? 120 : 4) })
                            QuickAmountButton(amount: unit == "ml" ? 180 : 6, unit: unit, action: { setAmount(unit == "ml" ? 180 : 6) })
                        }
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

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveFeed) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Save")
                                .font(.body.bold())
                        }
                    }
                    .disabled(!isValidInput || isLoading)
                }
            }
            .onAppear {
                loadDefaults()
            }
        }
    }

    private var isValidInput: Bool {
        guard let amountValue = Double(amount), amountValue > 0 else {
            return false
        }

        if unit == "ml" {
            return amountValue <= 500 // Max 500ml
        } else {
            return amountValue <= 17 // Max 17oz
        }
    }

    private func loadDefaults() {
        selectedSource = defaultSource
        setAmount(defaultAmount)
        unit = defaultUnit
    }

    private func setAmount(_ value: Double) {
        amount = String(Int(value))
    }

    private func saveFeed() {
        guard isValidInput, let amountValue = Double(amount) else { return }

        isLoading = true

        // Create the feed event
        let feedEvent = Event(
            babyId: UUID(), // This would be passed in or retrieved from context
            type: .feed,
            subtype: selectedSource.rawValue,
            startTime: Date(),
            amount: amountValue,
            unit: unit,
            side: selectedSide?.rawValue,
            note: durationMinutes.isEmpty ? nil : "Duration: \(durationMinutes) min"
        )

        // Provide haptic feedback
        Haptics.success()

        // Call completion handler
        onComplete(feedEvent)

        // Dismiss the sheet
        dismiss()
    }
}

/// Quick amount preset button
struct QuickAmountButton: View {
    let amount: Double
    let unit: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(Int(amount))\(unit)")
                .font(.body.bold())
                .foregroundColor(NuzzleTheme.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, .spacingSM)
                .background(NuzzleTheme.surface)
                .cornerRadius(.radiusMD)
                .overlay(
                    RoundedRectangle(cornerRadius: .radiusMD)
                        .stroke(NuzzleTheme.primary, lineWidth: 1)
                )
        }
    }
}

#Preview {
    QuickLogFeedView { event in
        print("Logged feed: \(event.displayText)")
    }
}
