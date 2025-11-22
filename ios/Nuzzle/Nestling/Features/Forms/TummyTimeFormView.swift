import SwiftUI

struct TummyTimeFormView: View {
    @ObservedObject var viewModel: TummyTimeFormViewModel
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
                                
                                Button("Stop") {
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
                    Section("Duration") {
                        HStack {
                            TextField("Minutes", text: $viewModel.durationMinutes)
                                .font(isCaregiverMode ? .caregiverBody : .body)
                                .keyboardType(.numberPad)
                                .onChange(of: viewModel.durationMinutes) { _, _ in
                                    viewModel.validate()
                                }
                            
                            Text("minutes")
                                .font(isCaregiverMode ? .caregiverBody : .body)
                                .foregroundColor(.mutedForeground)
                        }
                    }
                }
                
                if !isCaregiverMode || showAdvancedOptions {
                    Section("Time") {
                        DatePicker("Start Time", selection: $viewModel.startTime, displayedComponents: [.date, .hourAndMinute])
                            .font(isCaregiverMode ? .caregiverBody : .body)
                    }
                    
                    Section("Notes") {
                        VoiceInputView(text: $viewModel.note, placeholder: "Optional notes...")

                    Section("Photos") {
                        PhotoPickerView(selectedPhotos: $viewModel.photos)
                    }
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
            .navigationTitle(viewModel.editingEvent != nil ? "Edit Tummy Time" : "New Tummy Time")
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
                                showToast = ToastMessage(message: "Tummy time saved", type: .success)
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
    TummyTimeFormView(viewModel: TummyTimeFormViewModel(
        dataStore: InMemoryDataStore(),
        baby: Baby.mock()
    ))
}

