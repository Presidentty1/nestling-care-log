import SwiftUI

struct FeedFormView: View {
    @ObservedObject var viewModel: FeedFormViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var environment: AppEnvironment
    @State private var showToast: ToastMessage?
    @State private var saveTask: Task<Void, Never>?
    
    private var isCaregiverMode: Bool {
        environment.isCaregiverMode
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
                } else {
                    Section("Amount") {
                        HStack {
                            TextField("Amount", text: $viewModel.amount)
                                .keyboardType(.decimalPad)
                                .accessibilityLabel("Feed amount")
                                .accessibilityHint("Enter the amount in \(viewModel.unit.displayName). Minimum \(Int(AppConstants.minimumFeedAmountML)) milliliters required.")
                                .onChange(of: viewModel.amount) { _, _ in
                                    viewModel.validate()
                                }
                            
                            Picker("Unit", selection: $viewModel.unit) {
                                ForEach(UnitType.allCases, id: \.self) { unit in
                                    Text(unit.displayName).tag(unit)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 100)
                            .accessibilityLabel("Unit")
                            .accessibilityHint("Select milliliters or ounces")
                            .onChange(of: viewModel.unit) { _, _ in
                                Haptics.selection()
                            }
                        }
                        
                        if !viewModel.isValid && viewModel.feedType != .breast {
                            Text("Minimum \(Int(AppConstants.minimumFeedAmountML))ml required")
                                .font(.caption)
                                .foregroundColor(.destructive)
                                .accessibilityLabel("Validation error: Minimum \(Int(AppConstants.minimumFeedAmountML)) milliliters required")
                        }
                    }
                }
                
                Section("Time") {
                    DatePicker("Start Time", selection: $viewModel.startTime, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section("Notes") {
                    TextField("Optional notes", text: $viewModel.note, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(viewModel.editingEvent != nil ? "Edit Feed" : "Log Feed")
            .navigationBarTitleDisplayMode(.inline)
            .onDisappear {
                saveTask?.cancel()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
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
                                showToast = ToastMessage(message: "Feed saved", type: .success)
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
        }
    }
}

#Preview {
    FeedFormView(viewModel: FeedFormViewModel(
        dataStore: InMemoryDataStore(),
        baby: Baby.mock()
    ))
}

