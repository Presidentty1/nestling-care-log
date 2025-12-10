import SwiftUI

struct CloudSyncStatusView: View {
    @StateObject private var viewModel = CloudSyncStatusViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacingXL) {
                    // Status Card
                    VStack(alignment: .leading, spacing: .spacingMD) {
                        HStack {
                            Text("Cloud Sync Status")
                                .font(.headline)
                                .foregroundColor(Color.adaptiveForeground(colorScheme))

                            Spacer()

                            syncStatusIcon()
                        }

                        VStack(alignment: .leading, spacing: .spacingSM) {
                            Text("Status: \(viewModel.syncStatus.description)")
                                .font(.body)
                                .foregroundColor(Color.adaptiveForeground(colorScheme))

                            if let lastSync = viewModel.lastSyncTime {
                                Text("Last sync: \(lastSync.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                            }

                            if viewModel.isCloudKitEnabled {
                                Text("iCloud account connected")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            } else {
                                Text("iCloud account not available")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    .padding(.spacingMD)
                    .background(Color.adaptiveSurface(colorScheme))
                    .cornerRadius(.radiusMD)

                    // Migration Section (if needed)
                    if viewModel.needsMigration {
                        VStack(alignment: .leading, spacing: .spacingMD) {
                            Text("Migrate to Cloud Sync")
                                .font(.headline)
                                .foregroundColor(Color.adaptiveForeground(colorScheme))

                            Text("Move your existing data to iCloud for seamless sync across devices and caregivers.")
                                .font(.body)
                                .foregroundColor(Color.adaptiveTextSecondary(colorScheme))

                            if let summary = viewModel.migrationSummary {
                                Text("Data to migrate: \(summary.description)")
                                    .font(.caption)
                                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                            }

                            if viewModel.isMigrating {
                                VStack(spacing: .spacingSM) {
                                    ProgressView(value: viewModel.migrationProgress)
                                        .progressViewStyle(.linear)

                                    Text(viewModel.migrationStatus)
                                        .font(.caption)
                                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                                }
                            } else {
                                PrimaryButton("Start Migration") {
                                    Task {
                                        await viewModel.startMigration()
                                    }
                                }
                            }
                        }
                        .padding(.spacingMD)
                        .background(Color.adaptiveSurface(colorScheme))
                        .cornerRadius(.radiusMD)
                    }

                    // Manual Sync
                    VStack(alignment: .leading, spacing: .spacingMD) {
                        Text("Manual Sync")
                            .font(.headline)
                            .foregroundColor(Color.adaptiveForeground(colorScheme))

                        Text("Force a sync with iCloud now.")
                            .font(.body)
                            .foregroundColor(Color.adaptiveTextSecondary(colorScheme))

                        PrimaryButton(viewModel.isSyncing ? "Syncing..." : "Sync Now") {
                            Task {
                                await viewModel.manualSync()
                            }
                        }
                        .disabled(viewModel.isSyncing)
                    }
                    .padding(.spacingMD)
                    .background(Color.adaptiveSurface(colorScheme))
                    .cornerRadius(.radiusMD)

                    // Multi-Caregiver Info
                    VStack(alignment: .leading, spacing: .spacingMD) {
                        Text("Multi-Caregiver Sync")
                            .font(.headline)
                            .foregroundColor(Color.adaptiveForeground(colorScheme))

                        Text("Share access with partners, grandparents, or babysitters. Everyone with access to this iCloud account can view and add events.")
                            .font(.body)
                            .foregroundColor(Color.adaptiveTextSecondary(colorScheme))

                        HStack {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(Color.adaptivePrimary(colorScheme))
                            Text("Family sharing enabled")
                                .font(.caption)
                                .foregroundColor(Color.adaptivePrimary(colorScheme))
                        }
                    }
                    .padding(.spacingMD)
                    .background(Color.adaptiveSurface(colorScheme))
                    .cornerRadius(.radiusMD)

                    Spacer()
                }
                .padding(.spacingMD)
            }
            .navigationTitle("Cloud Sync")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                }
            }
            .task {
                await viewModel.checkStatus()
            }
        }
    }

    private func syncStatusIcon() -> some View {
        switch viewModel.syncStatus {
        case .synced:
            Image(systemName: "checkmark.icloud.fill")
                .foregroundColor(.green)
        case .syncing:
            ProgressView()
                .scaleEffect(0.7)
        case .error:
            Image(systemName: "exclamationmark.icloud.fill")
                .foregroundColor(.red)
        case .offline:
            Image(systemName: "icloud.slash")
                .foregroundColor(.orange)
        }
    }
}

@MainActor
class CloudSyncStatusViewModel: ObservableObject {
    @Published var syncStatus: CloudSyncStatus = .offline
    @Published var lastSyncTime: Date?
    @Published var isCloudKitEnabled: Bool = false
    @Published var needsMigration: Bool = false
    @Published var migrationSummary: MigrationSummary?
    @Published var isMigrating: Bool = false
    @Published var migrationProgress: Double = 0.0
    @Published var migrationStatus: String = ""
    @Published var isSyncing: Bool = false

    private var migrationService: CloudMigrationService?

    init() {
        // Initialize migration service if SwiftData is available
        do {
            let jsonStore = JSONBackedDataStore()
            let swiftDataStore = try SwiftDataStore()
            migrationService = CloudMigrationService(jsonStore: jsonStore, swiftDataStore: swiftDataStore)
        } catch {
            Logger.dataError("Failed to initialize SwiftData store: \(error.localizedDescription)")
        }
    }

    func checkStatus() async {
        // Check CloudKit availability
        isCloudKitEnabled = true // Assume available for now - could check CKContainer.accountStatus

        // Check if migration is needed
        if let service = migrationService {
            needsMigration = await service.needsMigration()
            if needsMigration {
                migrationSummary = await service.getMigrationSummary()
            }
        }

        // Set default sync status
        syncStatus = .synced
        lastSyncTime = Date()
    }

    func startMigration() async {
        guard let service = migrationService else { return }

        isMigrating = true
        migrationProgress = 0.0

        do {
            try await service.migrateData { [weak self] status, progress in
                Task { @MainActor in
                    self?.migrationStatus = status
                    self?.migrationProgress = progress
                }
            }

            // Migration successful
            await MainActor.run {
                self.needsMigration = false
                self.migrationSummary = nil
                self.isMigrating = false
            }

            // Show success message
            Logger.info("Cloud migration completed successfully")

        } catch {
            await MainActor.run {
                self.isMigrating = false
                self.migrationStatus = "Migration failed: \(error.localizedDescription)"
            }
            Logger.dataError("Cloud migration failed: \(error.localizedDescription)")
        }
    }

    func manualSync() async {
        isSyncing = true

        // Simulate sync operation
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        lastSyncTime = Date()
        isSyncing = false
    }
}

enum CloudSyncStatus {
    case synced
    case syncing
    case error
    case offline

    var description: String {
        switch self {
        case .synced: return "Synced"
        case .syncing: return "Syncing"
        case .error: return "Sync Error"
        case .offline: return "Offline"
        }
    }
}


