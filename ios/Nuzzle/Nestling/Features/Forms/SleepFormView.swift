import SwiftUI

enum SleepMode {
    case timer, quick, manual
}

struct SleepFormView: View {
    @ObservedObject var viewModel: SleepFormViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var environment: AppEnvironment
    @State private var showToast: ToastMessage?
    @State private var showAdvancedOptions = false
    @State private var showDiscardChangesAlert = false
    
    private var isCaregiverMode: Bool {
        environment.isCaregiverMode
    }

    private var mode: SleepMode {
        get {
            if viewModel.isTimerMode {
                return .timer
            } else if viewModel.endTime == nil {
                return .quick
            } else {
                return .manual
            }
        }
        set {
            switch newValue {
            case .timer:
                viewModel.isTimerMode = true
                viewModel.endTime = nil
            case .quick:
                viewModel.isTimerMode = false
                viewModel.endTime = nil
            case .manual:
                viewModel.isTimerMode = false
                if viewModel.endTime == nil {
                    viewModel.endTime = Date()
                }
            }
        }
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
                    Picker("Mode", selection: $mode) {
                        Text("Timer")
                            .font(isCaregiverMode ? .caregiverBody : .body)
                            .tag(SleepMode.timer)
                        Text("Quick Log")
                            .font(isCaregiverMode ? .caregiverBody : .body)
                            .tag(SleepMode.quick)
                        Text("Manual")
                            .font(isCaregiverMode ? .caregiverBody : .body)
                            .tag(SleepMode.manual)
                    }
                    .pickerStyle(.segmented)
                }

                if mode == .quick && viewModel.editingEvent == nil {
                    Section("Quick Log") {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: .spacingSM) {
                            QuickDurationButton(minutes: 15, action: quickLogSleep)
                            QuickDurationButton(minutes: 30, action: quickLogSleep)
                            QuickDurationButton(minutes: 60, action: quickLogSleep)
                            QuickDurationButton(minutes: 120, action: quickLogSleep)
                        }
                    }
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
                        VoiceInputView(text: $viewModel.note, placeholder: "Optional notes...")
                    }

                    Section("Photos") {
                        PhotoPickerView(selectedPhotos: $viewModel.photos)
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
            .interactiveDismissDisabled(viewModel.hasChanges)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if viewModel.hasChanges {
                            showDiscardChangesAlert = true
                        } else {
                            viewModel.timer?.invalidate()
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
            .alert("Discard changes?", isPresented: $showDiscardChangesAlert) {
                Button("Discard", role: .destructive) {
                    viewModel.timer?.invalidate()
                    dismiss()
                }
                Button("Keep Editing", role: .cancel) { }
            } message: {
                Text("You have unsaved changes. Do you want to discard them?")
            }
        }
        }
    }

    private func quickLogSleep(minutes: Int) async {
        do {
            viewModel.endTime = Date()
            viewModel.startTime = viewModel.endTime!.addingTimeInterval(-Double(minutes * 60))
            viewModel.isTimerMode = false

            try await viewModel.save()
            Haptics.success()
            showToast = ToastMessage(message: "Sleep logged", type: .success)
            AnalyticsService.shared.trackQuickNapLogged(minutes: minutes)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                dismiss()
            }
        } catch {
            Haptics.error()
            showToast = ToastMessage(message: error.localizedDescription, type: .error)
        }
    }

    private struct QuickDurationButton: View {
    let minutes: Int
    let action: (Int) -> Void

    var body: some View {
        Button(action: { action(minutes) }) {
            VStack {
                Text(formatDuration(minutes))
                    .font(.headline)
                Text(durationLabel(minutes))
                    .font(.caption2)
                    .foregroundColor(.mutedForeground)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, .spacingSM)
            .background(Color.surface)
            .cornerRadius(.radiusSM)
        }
    }

    private func formatDuration(_ minutes: Int) -> String {
        minutes < 60 ? "\(minutes)m" : "\(minutes/60)h"
    }

    private func durationLabel(_ minutes: Int) -> String {
        switch minutes {
        case 15: return "Quick nap"
        case 30: return "Short nap"
        case 60: return "Full nap"
        case 120: return "Long nap"
        default: return ""
        }
    }
}

#Preview {
    SleepFormView(viewModel: SleepFormViewModel(
        dataStore: InMemoryDataStore(),
        baby: Baby.mock()
    ))
}

