import SwiftUI
import Foundation

struct DataMigrationView: View {
    @EnvironmentObject var environment: AppEnvironment
    @Environment(\.dismiss) var dismiss
    @State private var isMigrating = false
    @State private var migrationStatus: String?
    @State private var showSuccess = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Import data from JSON storage to Core Data. This is a one-time migration that improves performance and enables advanced features.")
                        .font(.body)
                        .foregroundColor(.mutedForeground)
                }
                
                Section {
                    if isMigrating {
                        HStack {
                            ProgressView()
                            Text("Migrating data...")
                                .font(.body)
                                .foregroundColor(.mutedForeground)
                        }
                    } else {
                        PrimaryButton("Import from JSON", icon: "arrow.down.circle.fill") {
                            migrateData()
                        }
                    }
                    
                    if let status = migrationStatus {
                        Text(status)
                            .font(.caption)
                            .foregroundColor(.mutedForeground)
                    }
                }
                
                Section {
                    InfoBanner(
                        title: "Migration Info",
                        message: "After migration, JSON storage will remain as a backup. You can still export to JSON.",
                        variant: .info
                    )
                }
            }
            .navigationTitle("Data Migration")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Migration Complete", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Data has been successfully migrated to Core Data.")
            }
        }
    }
    
    private func migrateData() {
        isMigrating = true
        migrationStatus = "Starting migration..."
        
        Task {
            do {
                // TODO: Implement JSON to CoreData migration
                // This requires manual copying of data from JSONBackedDataStore to CoreDataDataStore
                let jsonStore = JSONBackedDataStore()
                let coreDataStore = CoreDataDataStore()
                
                // Fetch all babies and events from JSON store
                let babies = try await jsonStore.fetchBabies()
                migrationStatus = "Found \(babies.count) babies to migrate"
                
                // Add each baby and its events to CoreData
                for baby in babies {
                    try await coreDataStore.addBaby(baby)
                    let events = try await jsonStore.fetchEvents(for: baby, from: .distantPast, to: .distantFuture)
                    for event in events {
                        try await coreDataStore.addEvent(event)
                    }
                }
                
                migrationStatus = "Migration completed successfully"
                
                await MainActor.run {
                    isMigrating = false
                    migrationStatus = "Migration completed successfully"
                    showSuccess = true
                }
                await environment.refreshBabies()
                environment.refreshSettings()
                
                Haptics.success()
            } catch {
                await MainActor.run {
                    isMigrating = false
                    migrationStatus = "Error: \(error.localizedDescription)"
                }
                Haptics.error()
            }
        }
    }
}

#Preview {
    DataMigrationView()
        .environmentObject(AppEnvironment(dataStore: InMemoryDataStore()))
}

