import SwiftUI

struct PrivacyDataView: View {
    @EnvironmentObject var environment: AppEnvironment
    @Environment(\.dismiss) var dismiss
    @State private var showDeleteConfirmation = false
    @State private var deleteConfirmationText = ""
    @State private var showShareSheet = false
    @State private var csvURL: URL?
    @State private var showImportPicker = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacingLG) {
                    // Export Section
                    CardView {
                        VStack(alignment: .leading, spacing: .spacingSM) {
                            Text("Export Data")
                                .font(.headline)
                                .foregroundColor(.foreground)
                            
                            Text("Export your events as CSV or JSON. The file can be shared or saved to Files.")
                                .font(.body)
                                .foregroundColor(.mutedForeground)
                            
                            HStack(spacing: .spacingSM) {
                                PrimaryButton("Export CSV", icon: "square.and.arrow.up") {
                                    exportToCSV()
                                }
                                
                                SecondaryButton("Export JSON", icon: "doc.text") {
                                    exportToJSON()
                                }
                            }
                            .padding(.top, .spacingSM)
                        }
                    }
                    .padding(.horizontal, .spacingMD)
                    
                    // Backup Section
                    CardView {
                        VStack(alignment: .leading, spacing: .spacingSM) {
                            Text("Create Backup")
                                .font(.headline)
                                .foregroundColor(.foreground)
                            
                            Text("Create a complete backup including JSON data and PDF summary.")
                                .font(.body)
                                .foregroundColor(.mutedForeground)
                            
                            PrimaryButton("Create Backup", icon: "square.and.arrow.down.fill") {
                                createBackup()
                            }
                            .padding(.top, .spacingSM)
                        }
                    }
                    .padding(.horizontal, .spacingMD)
                    
                    // Import Section
                    CardView {
                        VStack(alignment: .leading, spacing: .spacingSM) {
                            Text("Restore from Backup")
                                .font(.headline)
                                .foregroundColor(.foreground)
                            
                            Text("Restore data from a backup file (ZIP or JSON).")
                                .font(.body)
                                .foregroundColor(.mutedForeground)
                            
                            Button(action: {
                                // Will be implemented with file picker
                                showImportPicker = true
                            }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up.fill")
                                    Text("Restore Backup")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.spacingMD)
                                .background(Color.surface)
                                .cornerRadius(.radiusMD)
                            }
                            .padding(.top, .spacingSM)
                        }
                    }
                    .padding(.horizontal, .spacingMD)
                    
                    // Delete Section
                    CardView {
                        VStack(alignment: .leading, spacing: .spacingSM) {
                            Text("Delete All Data")
                                .font(.headline)
                                .foregroundColor(.destructive)
                            
                            Text("This will permanently delete all your data, including events, babies, and settings. This action cannot be undone.")
                                .font(.body)
                                .foregroundColor(.mutedForeground)
                            
                            DestructiveButton("Delete All Data") {
                                showDeleteConfirmation = true
                            }
                            .padding(.top, .spacingSM)
                        }
                    }
                    .padding(.horizontal, .spacingMD)
                }
                .padding(.spacingMD)
            }
            .navigationTitle("Privacy & Data")
            .background(Color.background)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let csvURL = csvURL {
                    ShareSheet(items: [csvURL])
                }
            }
            .alert("Delete All Data?", isPresented: $showDeleteConfirmation) {
                TextField("Type DELETE to confirm", text: $deleteConfirmationText)
                Button("Cancel", role: .cancel) {
                    deleteConfirmationText = ""
                }
                Button("Delete", role: .destructive) {
                    if deleteConfirmationText == "DELETE" {
                        deleteAllData()
                    }
                    deleteConfirmationText = ""
                }
            } message: {
                Text("This will permanently delete all your data. Type DELETE to confirm.")
            }
        }
    }
    
    private func createBackup() {
        Task {
            do {
                guard let baby = environment.currentBaby else { return }
                
                let backupURL = try await BackupService.createBackup(dataStore: environment.dataStore, baby: baby)
                
                await MainActor.run {
                    csvURL = backupURL
                    showShareSheet = true
                }
                
                Haptics.success()
            } catch {
                Haptics.error()
            }
        }
    }
    
    private func exportToJSON() {
        Task {
            do {
                guard let baby = environment.currentBaby else { return }
                
                // Fetch all data
                let babies = try await environment.dataStore.fetchBabies()
                let startDate = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
                let events = try await environment.dataStore.fetchEvents(for: baby, from: startDate, to: Date())
                let settings = try await environment.dataStore.fetchAppSettings()
                
                // Create JSON structure
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                encoder.outputFormatting = .prettyPrinted
                
                let exportData: [String: Any] = [
                    "version": 1,
                    "babies": try babies.map { try JSONEncoder().encode($0) }.map { try JSONSerialization.jsonObject(with: $0) },
                    "events": try events.map { try JSONEncoder().encode($0) }.map { try JSONSerialization.jsonObject(with: $0) },
                    "settings": try JSONSerialization.jsonObject(with: try encoder.encode(settings))
                ]
                
                let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
                
                // Save to temp file
                let tempDir = FileManager.default.temporaryDirectory
                let fileName = "nestling_backup_\(Date().timeIntervalSince1970).json"
                let fileURL = tempDir.appendingPathComponent(fileName)
                
                try jsonData.write(to: fileURL)
                
                await MainActor.run {
                    csvURL = fileURL
                    showShareSheet = true
                }
                
                Haptics.success()
            } catch {
                Haptics.error()
            }
        }
    }
    
    private func exportToPDF() {
        Task {
            do {
                guard let baby = environment.currentBaby else { return }
                
                let startDate = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
                let events = try await environment.dataStore.fetchEvents(for: baby, from: startDate, to: Date())
                
                if let pdfURL = PDFExportService.generatePDF(for: events, baby: baby, dateRange: (startDate, Date())) {
                    await MainActor.run {
                        csvURL = pdfURL
                        showShareSheet = true
                    }
                    Haptics.success()
                } else {
                    Haptics.error()
                }
            } catch {
                Haptics.error()
            }
        }
    }
    
    private func exportToCSV() {
        Task {
            do {
                guard let baby = environment.currentBaby else { return }
                
                // Fetch all events
                let startDate = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
                let events = try await environment.dataStore.fetchEvents(for: baby, from: startDate, to: Date())
                
                // Generate CSV
                var csv = "Date,Time,Type,Subtype,Amount,Unit,Duration (min),Note\n"
                
                for event in events.sorted(by: { $0.startTime > $1.startTime }) {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    let timeFormatter = DateFormatter()
                    timeFormatter.dateFormat = "HH:mm"
                    
                    let date = dateFormatter.string(from: event.startTime)
                    let time = timeFormatter.string(from: event.startTime)
                    let type = event.type.displayName
                    let subtype = event.subtype ?? ""
                    let amount = event.amount.map { String(Int($0)) } ?? ""
                    let unit = event.unit ?? ""
                    let duration = event.durationMinutes.map { String($0) } ?? ""
                    let note = (event.note ?? "").replacingOccurrences(of: ",", with: ";")
                    
                    csv += "\(date),\(time),\(type),\(subtype),\(amount),\(unit),\(duration),\(note)\n"
                }
                
                // Save to temp file
                let tempDir = FileManager.default.temporaryDirectory
                let fileName = "nestling_export_\(Date().timeIntervalSince1970).csv"
                let fileURL = tempDir.appendingPathComponent(fileName)
                
                try csv.write(to: fileURL, atomically: true, encoding: .utf8)
                
                await MainActor.run {
                    csvURL = fileURL
                    showShareSheet = true
                }
                
                Haptics.success()
            } catch {
                Haptics.error()
            }
        }
    }
    
    private func deleteAllData() {
        Task {
            if let jsonStore = environment.dataStore as? JSONBackedDataStore {
                jsonStore.reset()
            } else if let inMemoryStore = environment.dataStore as? InMemoryDataStore {
                inMemoryStore.reset()
            }
            await environment.refreshBabies()
            await environment.refreshSettings()
            Haptics.error()
            await MainActor.run {
                dismiss()
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    PrivacyDataView()
        .environmentObject(AppEnvironment(dataStore: InMemoryDataStore()))
}

