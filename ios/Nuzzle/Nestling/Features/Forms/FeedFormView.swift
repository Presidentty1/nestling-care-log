import SwiftUI

// Import voice input component

struct FeedFormView: View {
    @ObservedObject var viewModel: FeedFormViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var environment: AppEnvironment
    @State private var showToast: ToastMessage?
    @State private var showDiscardChangesAlert = false
    
    private var isCaregiverMode: Bool {
        environment.isCaregiverMode
    }

    private var currentAmountValue: Double {
        Double(viewModel.amount) ?? 0
    }

    private var stepSize: Double {
        viewModel.unit == .oz ? 0.5 : 10.0
    }

    private var canDecrement: Bool {
        let minML = AppConstants.minimumFeedAmountML
        let currentML = viewModel.unit == .ml ? currentAmountValue : currentAmountValue * AppConstants.mlPerOz
        return currentML - (viewModel.unit == .ml ? stepSize : stepSize * AppConstants.mlPerOz) >= minML
    }

    private func incrementAmount() {
        let newValue = currentAmountValue + stepSize
        viewModel.amount = String(format: viewModel.unit == .oz ? "%.1f" : "%.0f", newValue)
        viewModel.validate()
        Haptics.light()
        AnalyticsService.shared.trackFeedAmountStepperUsed(direction: "up", unit: viewModel.unit.rawValue)
    }

    private func decrementAmount() {
        let newValue = max(0, currentAmountValue - stepSize)
        viewModel.amount = String(format: viewModel.unit == .oz ? "%.1f" : "%.0f", newValue)
        viewModel.validate()
        Haptics.light()
        AnalyticsService.shared.trackFeedAmountStepperUsed(direction: "down", unit: viewModel.unit.rawValue)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if !isCaregiverMode {
                    Section("Type") {
                        Picker("Feed Type", selection: $viewModel.feedType) {
                            ForEach(FeedSubtype.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .onChange(of: viewModel.feedType) { _, _ in
                            Haptics.selection()
                            viewModel.validate()
                        }
                    }
                }
                
                if viewModel.feedType == .breast {
                    Section("Side") {
                        Picker("Side", selection: $viewModel.side) {
                            ForEach(Side.allCases, id: \.self) { side in
                                Text(side.displayName).tag(side)
                            }
                        }
                        .onChange(of: viewModel.side) { _, _ in
                            Haptics.selection()
                        }
                    }
                } else if viewModel.feedType == .bottle || viewModel.feedType == .pumping {
                    Section("Amount") {
                        VStack(spacing: .spacingSM) {
                            // Stepper row
                            HStack(spacing: .spacingMD) {
                                Button(action: decrementAmount) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.primary)
                                        .frame(width: 44, height: 44)
                                }
                                .disabled(!canDecrement)
                                .accessibilityLabel("Decrease amount")

                                VStack(spacing: 4) {
                                    TextField("Amount", text: $viewModel.amount)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.center)
                                        .font(.system(size: 24, weight: .bold))
                                        .frame(maxWidth: .infinity)
                                        .accessibilityLabel("Feed amount")
                                        .accessibilityHint("Enter the amount in \(viewModel.unit.displayName). Minimum \(Int(AppConstants.minimumFeedAmountML)) milliliters required.")
                                        .onChange(of: viewModel.amount) { _, _ in
                                            viewModel.validate()
                                        }

                                    Text(viewModel.unit.displayName)
                                        .font(.caption)
                                        .foregroundColor(.mutedForeground)
                                }
                                .frame(maxWidth: .infinity)

                                Button(action: incrementAmount) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.primary)
                                        .frame(width: 44, height: 44)
                                }
                                .accessibilityLabel("Increase amount")
                            }

                            // Unit picker
                            Picker("Unit", selection: $viewModel.unit) {
                                ForEach(UnitType.allCases, id: \.self) { unit in
                                    Text(unit.displayName).tag(unit)
                                }
                            }
                            .pickerStyle(.segmented)
                            .accessibilityLabel("Unit")
                            .accessibilityHint("Select milliliters or ounces")
                            .onChange(of: viewModel.unit) { _, _ in
                                Haptics.selection()
                            }
                        }

                        // Visual bottle level indicator (only for bottle/pumping)
                        if viewModel.feedType == .bottle || viewModel.feedType == .pumping {
                            BottleLevelIndicator(
                                amount: currentAmountValue,
                                unit: viewModel.unit
                            )
                            .padding(.horizontal)
                        }
                        
                        if !viewModel.isValid && (viewModel.feedType == .bottle || viewModel.feedType == .pumping) {
                            // UX-01: Show validation error with min/max limits
                            Group {
                                let amountValue = Double(viewModel.amount) ?? 0
                                let amountML = viewModel.unit == .ml ? amountValue : amountValue * AppConstants.mlPerOz
                                let maxML = viewModel.unit == .ml ? AppConstants.maximumFeedAmountML : AppConstants.maximumFeedAmountOZ * AppConstants.mlPerOz
                                
                                let errorMessage: String = {
                                    if amountML < AppConstants.minimumFeedAmountML {
                                        return "Minimum \(Int(AppConstants.minimumFeedAmountML))ml required"
                                    } else if amountML > maxML {
                                        let maxDisplay = viewModel.unit == .ml ? "\(Int(AppConstants.maximumFeedAmountML))ml" : "\(Int(AppConstants.maximumFeedAmountOZ))oz"
                                        return "Maximum \(maxDisplay) allowed"
                                    } else {
                                        return "Invalid amount"
                                    }
                                }()
                                
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.destructive)
                                    .accessibilityLabel("Validation error: \(errorMessage)")
                            }
                        }
                    }
                }
                
                Section("Time") {
                    DatePicker("Start Time", selection: $viewModel.startTime, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section("Notes") {
                    VoiceInputView(text: $viewModel.note, placeholder: "Optional notes...")
                }

                Section("Photos") {
                    PhotoPickerView(selectedPhotos: $viewModel.photos)
                }
            }
            .navigationTitle(viewModel.editingEvent != nil ? "Edit Feed" : "New Feed")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled(viewModel.hasChanges)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if viewModel.hasChanges {
                            showDiscardChangesAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            do {
                                try await viewModel.save()
                                Haptics.success()

                                let feedCount = await viewModel.getTodayFeedCount()
                                let nextFeedTime = viewModel.predictNextFeedTime()

                                var message = "Feed logged!"
                                if feedCount == 3 {
                                    message = "3rd feed today - you're doing great!"
                                }
                                if let nextTime = nextFeedTime {
                                    message += " Next feed probably around \(nextTime.formatted(date: .omitted, time: .shortened))"
                                }

                                showToast = ToastMessage(message: message, type: .success)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    dismiss()
                                }
                            } catch {
                                Haptics.error()
                                showToast = ToastMessage(message: error.localizedDescription, type: .error)
                            }
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                                .symbolBounce(value: viewModel.isSaving)
                            Text("Save")
                        }
                    }
                    .disabled(!viewModel.isValid || viewModel.isSaving)
                }
            }
            .toast($showToast)
            .alert("Discard changes?", isPresented: $showDiscardChangesAlert) {
                Button("Discard", role: .destructive) {
                    dismiss()
                }
                Button("Keep Editing", role: .cancel) { }
            } message: {
                Text("You have unsaved changes. Do you want to discard them?")
            }
        }
    }
}

#Preview {
    FeedFormView(viewModel: FeedFormViewModel(
        dataStore: InMemoryDataStore(),
        baby: Baby.mock()
    ))
}

