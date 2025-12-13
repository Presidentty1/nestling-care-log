import SwiftUI
import Supabase
import Auth

struct PrivacyDataView: View {
    @EnvironmentObject var environment: AppEnvironment
    @Environment(\.dismiss) var dismiss
    @State private var showDeleteConfirmation = false
    @State private var deleteConfirmationText = ""
    @State private var showShareSheet = false
    @State private var csvURL: URL?
    @State private var showImportPicker = false
    @State private var analyticsEnabled = UserDefaults.standard.object(forKey: "analytics_enabled") as? Bool ?? true
    @State private var isLoggedIn = false
    @State private var showDeleteAccountConfirmation = false
    @State private var deleteAccountConfirmationText = ""
    
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
                            
                            Text("Export your events as CSV, JSON, or PDF. The file can be shared or saved to Files.")
                                .font(.body)
                                .foregroundColor(.mutedForeground)
                            
                            HStack(spacing: .spacingSM) {
                                PrimaryButton("Export CSV", icon: "square.and.arrow.up") {
                                    exportToCSV()
                                }
                                
                                SecondaryButton("Export JSON", icon: "doc.text") {
                                    exportToJSON()
                                }
                                
                                SecondaryButton("Export PDF", icon: "doc.fill") {
                                    exportToPDF()
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
                    
                    // Analytics Opt-Out Section
                    CardView {
                        VStack(alignment: .leading, spacing: .spacingSM) {
                            HStack {
                                Text("Analytics")
                                    .font(.headline)
                                    .foregroundColor(.foreground)
                                
                                Spacer()
                                
                                Toggle("", isOn: $analyticsEnabled)
                                    .onChange(of: analyticsEnabled) { _, enabled in
                                        AnalyticsService.shared.setEnabled(enabled)
                                        Haptics.light()
                                    }
                            }
                            
                            Text("We collect minimal, privacy-respecting analytics to improve the app. No personal information is tracked. You can turn this off at any time without affecting core app functionality.")
                                .font(.body)
                                .foregroundColor(.mutedForeground)
                        }
                        .padding(.spacingMD)
                    }
                    .padding(.horizontal, .spacingMD)
                    
                    // Privacy Explanation Section
                    InfoBanner(
                        title: "Your Privacy Matters",
                        message: "All your data is stored locally on your device. iCloud sync only happens when you explicitly enable family sharing. We never sell your data or use third-party tracking.",
                        variant: .info
                    )
                    .padding(.horizontal, .spacingMD)

                    // Account Deletion Section (only show if logged in)
                    if isLoggedIn {
                        CardView {
                            VStack(alignment: .leading, spacing: .spacingSM) {
                                Text("Delete Account")
                                    .font(.headline)
                                    .foregroundColor(.destructive)

                                Text("This will permanently delete your account and all associated data from our servers. You will be signed out and local data will also be deleted.")
                                    .font(.body)
                                    .foregroundColor(.mutedForeground)

                                DestructiveButton("Delete Account") {
                                    showDeleteAccountConfirmation = true
                                }
                                .padding(.top, .spacingSM)
                            }
                        }
                        .padding(.horizontal, .spacingMD)
                    }

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
            .task {
                isLoggedIn = await checkSupabaseSession()
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
            .alert("Delete Account?", isPresented: $showDeleteAccountConfirmation) {
                TextField("Type DELETE ACCOUNT to confirm", text: $deleteAccountConfirmationText)
                Button("Cancel", role: .cancel) {
                    deleteAccountConfirmationText = ""
                }
                Button("Delete Account", role: .destructive) {
                    if deleteAccountConfirmationText == "DELETE ACCOUNT" {
                        deleteAccount()
                    }
                    deleteAccountConfirmationText = ""
                }
            } message: {
                Text("This will permanently delete your account and all data from our servers. This action cannot be undone.")
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
                
                // Get user preferences for formatting
                let settings = try? await environment.dataStore.fetchAppSettings()
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .none
                
                let timeFormatter = DateFormatter()
                timeFormatter.timeStyle = .short
                timeFormatter.dateStyle = .none
                
                // Generate CSV with header
                var csv = "Date,Time,Type,Subtype,Amount,Unit,Duration (min),Note\n"
                
                // Sort events chronologically (oldest first for CSV)
                for event in events.sorted(by: { $0.startTime < $1.startTime }) {
                    let date = dateFormatter.string(from: event.startTime)
                    let time = timeFormatter.string(from: event.startTime)
                    let type = event.type.displayName
                    let subtype = event.subtype ?? ""
                    
                    // Format amount based on unit
                    let amount: String
                    if let eventAmount = event.amount {
                        if let settings = settings, settings.preferredUnit == "oz", event.unit == "ml" {
                            // Convert ml to oz for display if user prefers imperial
                            amount = String(format: "%.2f", eventAmount / AppConstants.mlPerOz)
                        } else {
                            amount = String(format: "%.0f", eventAmount)
                        }
                    } else {
                        amount = ""
                    }
                    
                    let unit = event.unit ?? ""
                    let duration = event.durationMinutes.map { String($0) } ?? ""
                    
                    // Escape note (replace commas with semicolons, escape quotes)
                    var note = (event.note ?? "").replacingOccurrences(of: ",", with: ";")
                    if note.contains("\"") {
                        note = "\"" + note.replacingOccurrences(of: "\"", with: "\"\"") + "\""
                    }
                    
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
            do {
                // Delete all data based on the data store type
                if let jsonStore = environment.dataStore as? JSONBackedDataStore {
                    jsonStore.reset()
                } else if let inMemoryStore = environment.dataStore as? InMemoryDataStore {
                    inMemoryStore.reset()
                } else if let coreDataStore = environment.dataStore as? CoreDataDataStore {
                    try await coreDataStore.deleteAllData()
                }
                
                // Refresh app state
                await environment.refreshBabies()
                environment.refreshSettings()
                
                Haptics.error()
                
                await MainActor.run {
                    dismiss()
                    // App will show onboarding on next launch since no babies exist
                }
            } catch {
                print("Error deleting all data: \(error)")
                Haptics.error()
            }
        }
    }

    private func checkSupabaseSession() async -> Bool {
        do {
            let client = try SupabaseClientProvider.shared.getClient()
            return (try? await client.auth.session) != nil
        } catch {
            return false
        }
    }

    private func deleteAccount() {
        Task {
            do {
                // First, try to delete from Supabase if configured
                if isLoggedIn {
                    do {
                        let client = try SupabaseClientProvider.shared.getClient()
                        
                        // Call delete-user-account edge function using Supabase functions API
                        let response: DeleteAccountResponse = try await client.functions.invoke(
                            "delete-user-account",
                            options: FunctionInvokeOptions(body: [String: String]())
                        )
                        
                        if response.success {
                            print("Account deleted successfully from Supabase")
                        } else {
                            let errorMessage = response.error ?? "Unknown error"
                            print("Failed to delete account from Supabase: \(errorMessage)")
                            // Continue with local deletion even if server deletion fails
                        }
                    } catch {
                        print("Failed to delete account from Supabase: \(error)")
                        // Continue with local deletion even if Supabase deletion fails
                    }
                }

                // Delete all local data
                await deleteAllDataLocally()

                Haptics.error()

                await MainActor.run {
                    dismiss()
                    // App will show onboarding on next launch since no babies exist
                }
            } catch {
                print("Error deleting account: \(error)")
                Haptics.error()
            }
        }
    }

    private func deleteAllDataLocally() async {
        do {
            // Delete all data based on the data store type
            if let jsonStore = environment.dataStore as? JSONBackedDataStore {
                jsonStore.reset()
            } else if let inMemoryStore = environment.dataStore as? InMemoryDataStore {
                inMemoryStore.reset()
            } else if let coreDataStore = environment.dataStore as? CoreDataDataStore {
                try await coreDataStore.deleteAllData()
            }

            // Clear any cached auth data
            UserDefaults.standard.removeObject(forKey: "auth_session")
            UserDefaults.standard.removeObject(forKey: "user_email")

            // Refresh app state
            await environment.refreshBabies()
            environment.refreshSettings()

        } catch {
            print("Error deleting local data: \(error)")
        }
    }

    private struct DeleteAccountResponse: Decodable {
        let success: Bool
        let error: String?
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

