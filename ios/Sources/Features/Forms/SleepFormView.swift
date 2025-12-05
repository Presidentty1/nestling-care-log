import SwiftUI

struct SleepFormView: View {
    @ObservedObject var viewModel: SleepFormViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var environment: AppEnvironment
    @State private var showToast: ToastMessage?
    @State private var showAdvancedOptions = false
    @State private var saveTask: Task<Void, Never>?
    
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
                    .pickerStyle(isCaregiverMode ? .segmented : .menu)
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
                            DatePicker("Start Time", selection: $viewModel.startTime, displayedComponents: [.date, .hourAndMinute])
                                .font(isCaregiverMode ? .caregiverBody : .body)
                            DatePicker("End Time", selection: Binding(
                                get: { viewModel.endTime ?? Date() },
                                set: { viewModel.endTime = $0 }
                            ), displayedComponents: [.date, .hourAndMinute])
                            .font(isCaregiverMode ? .caregiverBody : .body)
                            .onChange(of: viewModel.endTime) { _, _ in
                                viewModel.validate()
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
            .navigationTitle(viewModel.editingEvent != nil ? "Edit Sleep" : "Log Sleep")
            .navigationBarTitleDisplayMode(.inline)
            .onDisappear {
                saveTask?.cancel()
                viewModel.cleanup()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.cleanup()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        saveTask?.cancel()
                        saveTask = Task {
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

