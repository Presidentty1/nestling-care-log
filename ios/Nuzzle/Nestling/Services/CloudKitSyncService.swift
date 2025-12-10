import Foundation
import CloudKit
import CoreData

/// CloudKit-based sync service for multi-caregiver support
/// Only syncs when user explicitly enables multi-caregiver sharing
@MainActor
class CloudKitSyncService: ObservableObject {
    static let shared = CloudKitSyncService()
    
    @Published private(set) var isSyncing = false
    @Published private(set) var lastSyncTime: Date?
    @Published private(set) var syncError: Error?
    @Published private(set) var isEnabled = false
    
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private var dataStore: DataStore
    
    private init() {
        // TODO: Update container identifier from com.nestling to com.nuzzle when ready
        let containerID = "iCloud.com.nestling.app"
        self.container = CKContainer(identifier: containerID)
        self.privateDatabase = container.privateCloudDatabase
        self.dataStore = DataStoreSelector.create()
        
        // Check if sync is enabled
        self.isEnabled = UserDefaults.standard.bool(forKey: "cloudkit_sync_enabled")
    }
    
    // MARK: - Sync Control
    
    /// Enable CloudKit sync (user must explicitly enable for multi-caregiver)
    func enable() async throws {
        // Check CloudKit account status
        let status = try await container.accountStatus()
        
        guard status == .available else {
            let message = cloudKitErrorMessage(for: status)
            throw NSError(domain: "CloudKitSync", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
        }
        
        isEnabled = true
        UserDefaults.standard.set(true, forKey: "cloudkit_sync_enabled")
        
        // Trigger initial sync
        await syncAll()
    }
    
    /// Disable CloudKit sync
    func disable() {
        isEnabled = false
        UserDefaults.standard.set(false, forKey: "cloudkit_sync_enabled")
    }
    
    private func cloudKitErrorMessage(for status: CKAccountStatus) -> String {
        switch status {
        case .couldNotDetermine:
            return "Could not determine iCloud status. Please check your iCloud settings."
        case .noAccount:
            return "No iCloud account found. Please sign in to iCloud in Settings."
        case .restricted:
            return "iCloud access is restricted. Please check parental controls or MDM settings."
        case .temporarilyUnavailable:
            return "iCloud is temporarily unavailable. Please try again later."
        case .available:
            return "iCloud is available"
        @unknown default:
            return "Unknown iCloud status"
        }
    }
    
    // MARK: - Sync Operations
    
    /// Sync all data to CloudKit
    func syncAll() async {
        guard isEnabled else { return }
        guard !isSyncing else { return }
        
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            // Sync babies
            try await syncBabies()
            
            // Sync events
            try await syncEvents()
            
            lastSyncTime = Date()
            syncError = nil
            Logger.dataInfo("CloudKit sync completed successfully")
        } catch {
            syncError = error
            Logger.dataError("CloudKit sync failed: \(error.localizedDescription)")
        }
    }
    
    private func syncBabies() async throws {
        let babies = try await dataStore.fetchBabies()
        
        for baby in babies {
            try await uploadBaby(baby)
        }
    }
    
    private func syncEvents() async throws {
        // Sync last 30 days of events
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        // Note: This would need to fetch all babies' events
        // For now, just log the intent
        Logger.dataInfo("Syncing events from last 30 days")
    }
    
    private func uploadBaby(_ baby: Baby) async throws {
        let record = CKRecord(recordType: "Baby", recordID: CKRecord.ID(recordName: baby.id.uuidString))
        record["name"] = baby.name as CKRecordValue
        record["dateOfBirth"] = baby.dateOfBirth as CKRecordValue
        record["sex"] = baby.sex as CKRecordValue?
        record["primaryFeedingStyle"] = baby.primaryFeedingStyle as CKRecordValue?
        record["timezone"] = baby.timezone as CKRecordValue
        record["createdAt"] = baby.createdAt as CKRecordValue
        record["updatedAt"] = baby.updatedAt as CKRecordValue
        
        try await privateDatabase.save(record)
    }
    
    // MARK: - Conflict Resolution
    
    /// Resolve conflicts using last-write-wins strategy
    func resolveConflict(local: Any, remote: Any, timestamp localTimestamp: Date, remoteTimestamp: Date) -> Any {
        // Last write wins
        if localTimestamp > remoteTimestamp {
            Logger.dataInfo("Conflict resolved: keeping local version")
            return local
        } else {
            Logger.dataInfo("Conflict resolved: keeping remote version")
            return remote
        }
    }
}
