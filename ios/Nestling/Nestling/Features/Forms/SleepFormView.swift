import SwiftUI

struct SleepFormView: View {
    @ObservedObject var viewModel: SleepFormViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var environment: AppEnvironment
    @State private var showToast: ToastMessage?
    @State private var showAdvancedOptions = false
    
    private var isCaregiverMode: Bool {
        environment.isCaregiverMode
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Sleep Type", selection: $viewModel.subtype) {
                        ForEach(SleepSubtype.allCases, id: \.self) { type in
                            Text(type.displayName)
                                .font(isCaregiverMode ? .caregiverBody : .body)
                                .tag(type)
                        }
                    }
                    .modifier(PickerStyleModifier(isCaregiverMode: isCaregiverMode))
                }
                
                Section("Mode") {
                    Picker("Mode", selection: $viewModel.isTimerMode) {
                        Text("Timer")
                            .font(isCaregiverMode ? .caregiverBody : .body)
                            .tag(true)
                        Text("Manual")
                            .font(isCaregiverMode ? .caregiverBody : .body)
                            .tag(false)
                    }
                    .pickerStyle(.segmented)
                }
                
                if viewModel.isTimerMode {
                    Section("Timer") {
                        if viewModel.isTimerRunning {
                            VStack(spacing: 16) {
                                Text(DateUtils.formatDuration(minutes: viewModel.elapsedSeconds / 60))
                                    .font(.system(size: isCaregiverMode ? 56 : 48, weight: .bold))
                                    .monospacedDigit()
                                
                                Button("Stop Sleep") {
                                    viewModel.stopTimer()
                                }
                                .alert("Discard this session?", isPresented: $viewModel.showDiscardPrompt) {
                                    Button("Discard", role: .destructive) {
                                        viewModel.discardTimer()
                                    }
                                    Button("Keep", role: .cancel) {
                                        viewModel.keepTimer()
                                    }
                                } message: {
                                    Text("This session was very short. Would you like to discard it or save it as 1 minute?")
                                }
                                .font(isCaregiverMode ? .caregiverBody : .body)
                                .buttonStyle(.borderedProminent)
                                .frame(minHeight: isCaregiverMode ? .caregiverMinTouchTarget : nil)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical)
                        } else {
                            Button("Start Timer") {
                                viewModel.startTimer()
                            }
                            .font(isCaregiverMode ? .caregiverBody : .body)
                            .buttonStyle(.borderedProminent)
                            .frame(minHeight: isCaregiverMode ? .caregiverMinTouchTarget : nil)
                        }
                    }
                } else {
                    if !isCaregiverMode || showAdvancedOptions {
                        Section("Times") {
                            DatePicker("Start Time", selection: $viewModel.startTime, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                                .font(isCaregiverMode ? .caregiverBody : .body)
                                .onChange(of: viewModel.startTime) { _, _ in
                                    viewModel.validate()
                                }
                            DatePicker("End Time", selection: Binding(
                                get: { viewModel.endTime ?? Date() },
                                set: { viewModel.endTime = $0 }
                            ), in: viewModel.startTime..., displayedComponents: [.date, .hourAndMinute])
                            .font(isCaregiverMode ? .caregiverBody : .body)
                            .onChange(of: viewModel.endTime) { _, _ in
                                viewModel.validate()
                            }
                            
                            if let error = viewModel.validationError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.destructive)
                            }
                        }
                    }
                }
                
                if !isCaregiverMode || showAdvancedOptions {
                    Section("Notes") {
                        TextField("Optional notes", text: $viewModel.note, axis: .vertical)
                            .font(isCaregiverMode ? .caregiverBody : .body)
                            .lineLimit(3...6)
                    }
                }
                
                if isCaregiverMode && !showAdvancedOptions {
                    Section {
                        Button("More Options") {
                            showAdvancedOptions = true
                        }
                        .font(.caregiverBody)
                        .frame(minHeight: .caregiverMinTouchTarget)
                    }
                }
            }
            .navigationTitle(viewModel.editingEvent != nil ? "Edit Sleep" : "New Sleep")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.timer?.invalidate()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            do {
                                try await viewModel.save()
                                Haptics.success()
                                showToast = ToastMessage(message: "Sleep saved", type: .success)
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
                    .font(isCaregiverMode ? .caregiverBody : .body)
                    .frame(minHeight: isCaregiverMode ? .caregiverMinTouchTarget : nil)
                    .disabled(!viewModel.isValid || viewModel.isSaving)
                }
            }
            .toast($showToast)
        }
    }
}

#Preview {
    SleepFormView(viewModel: SleepFormViewModel(
        dataStore: InMemoryDataStore(),
        baby: Baby.mock()
    ))
}

