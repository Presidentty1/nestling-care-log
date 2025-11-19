import SwiftUI

struct PickerStyleModifier: ViewModifier {
    let isCaregiverMode: Bool
    
    func body(content: Content) -> some View {
        if isCaregiverMode {
            content.pickerStyle(SegmentedPickerStyle())
        } else {
            content.pickerStyle(MenuPickerStyle())
        }
    }
}

struct DiaperFormView: View {
    @ObservedObject var viewModel: DiaperFormViewModel
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
                    Picker("Diaper Type", selection: $viewModel.subtype) {
                        ForEach(DiaperSubtype.allCases, id: \.self) { type in
                            Text(type.displayName)
                                .font(isCaregiverMode ? .caregiverBody : .body)
                                .tag(type)
                        }
                    }
                    .modifier(PickerStyleModifier(isCaregiverMode: isCaregiverMode))
                }
                
                if !isCaregiverMode || showAdvancedOptions {
                    Section("Time") {
                        DatePicker("Time", selection: $viewModel.startTime, displayedComponents: [.date, .hourAndMinute])
                            .font(isCaregiverMode ? .caregiverBody : .body)
                    }
                    
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
            .navigationTitle(viewModel.editingEvent != nil ? "Edit Diaper" : "Log Diaper")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            do {
                                try await viewModel.save()
                                Haptics.success()
                                showToast = ToastMessage(message: "Diaper change saved", type: .success)
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
                    .font(isCaregiverMode ? .caregiverBody : .body)
                    .frame(minHeight: isCaregiverMode ? .caregiverMinTouchTarget : nil)
                }
            }
            .toast($showToast)
        }
    }
}

#Preview {
    DiaperFormView(viewModel: DiaperFormViewModel(
        dataStore: InMemoryDataStore(),
        baby: Baby.mock()
    ))
}

