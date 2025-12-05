import SwiftUI

struct ManageBabiesView: View {
    @EnvironmentObject var environment: AppEnvironment
    @Environment(\.dismiss) var dismiss
    @State private var showAddBaby = false
    @State private var editingBaby: Baby?
    @State private var showEditBaby = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(environment.babies) { baby in
                    HStack {
                        BabyAvatar(name: baby.name, size: 40)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(baby.name)
                                .font(.body)
                                .foregroundColor(.foreground)
                            
                            Text("Born \(DateUtils.formatDate(baby.dateOfBirth))")
                                .font(.caption)
                                .foregroundColor(.mutedForeground)
                        }
                        
                        Spacer()
                        
                        if baby.id == environment.currentBaby?.id {
                            StatusPill("Active", variant: .success)
                        }
                        
                        Menu {
                            Button(action: {
                                editingBaby = baby
                                showEditBaby = true
                            }) {
                                Label("Edit", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive, action: {
                                Task {
                                    try? await environment.dataStore.deleteBaby(baby)
                                    environment.refreshBabies()
                                }
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundColor(.mutedForeground)
                        }
                    }
                }
            }
            .navigationTitle("Manage Babies")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Add Baby") {
                        showAddBaby = true
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showAddBaby) {
                SheetDetentWrapper(
                    preferMedium: environment.appSettings.preferMediumSheet,
                    isSaving: false
                ) {
                    AddEditBabyView(onSave: { baby in
                        Task {
                            try? await environment.dataStore.addBaby(baby)
                            environment.refreshBabies()
                            if environment.currentBaby == nil {
                                environment.currentBaby = baby
                            }
                        }
                        showAddBaby = false
                    })
                }
            }
            .sheet(isPresented: $showEditBaby) {
                if let baby = editingBaby {
                    SheetDetentWrapper(
                        preferMedium: environment.appSettings.preferMediumSheet,
                        isSaving: false
                    ) {
                        AddEditBabyView(baby: baby, onSave: { updatedBaby in
                            Task {
                                try? await environment.dataStore.updateBaby(updatedBaby)
                                environment.refreshBabies()
                            }
                            editingBaby = nil
                            showEditBaby = false
                        })
                    }
                }
            }
        }
    }
}

struct AddEditBabyView: View {
    let baby: Baby?
    let onSave: (Baby) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var dateOfBirth: Date = Date()
    @State private var sex: Sex?
    @State private var errorMessage: String?
    
    init(baby: Baby? = nil, onSave: @escaping (Baby) -> Void) {
        self.baby = baby
        self.onSave = onSave
        _name = State(initialValue: baby?.name ?? "")
        _dateOfBirth = State(initialValue: baby?.dateOfBirth ?? Date())
        _sex = State(initialValue: baby?.sex)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Baby's name", text: $name)
                }
                
                Section("Date of Birth") {
                    DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                        .datePickerStyle(.compact)
                }
                
                Section("Sex (Optional)") {
                    Picker("Sex", selection: $sex) {
                        Text("Not specified").tag(nil as Sex?)
                        ForEach(Sex.allCases, id: \.self) { s in
                            Text(s.displayName).tag(s as Sex?)
                        }
                    }
                }
            }
            .navigationTitle(baby != nil ? "Edit Baby" : "Add Baby")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveBaby()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || dateOfBirth > Calendar.current.startOfDay(for: Date()))
                }
            }
            .alert("Validation Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    private func saveBaby() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Name is required"
            return
        }
        
        guard dateOfBirth <= Date() else {
            errorMessage = "Date of birth cannot be in the future"
            return
        }
        
        let updatedBaby = Baby(
            id: baby?.id ?? IDGenerator.generate(),
            name: name.trimmingCharacters(in: .whitespaces),
            dateOfBirth: dateOfBirth,
            sex: sex,
            timezone: TimeZone.current.identifier,
            primaryFeedingStyle: baby?.primaryFeedingStyle,
            createdAt: baby?.createdAt ?? Date(),
            updatedAt: Date()
        )
        
        Haptics.success()
        onSave(updatedBaby)
        dismiss()
    }
}

#Preview {
    ManageBabiesView()
        .environmentObject(AppEnvironment(dataStore: InMemoryDataStore()))
}

