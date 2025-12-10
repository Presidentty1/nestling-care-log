import Foundation
import CloudKit
import Combine
import OSLog

/// Service for multi-caregiver sync using CloudKit
/// Only syncs when user explicitly enables family sharing
@MainActor
class CaregiverSyncService: ObservableObject {
    static let shared = CaregiverSyncService()
    
    @Published private(set) var isSyncing = false
    @Published private(set) var lastSyncTime: Date?
    @Published private(set) var pendingCount = 0
    @Published private(set) var isEnabled = false
    
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let sharedDatabase: CKDatabase
    private var dataStore: DataStore
    private var syncTask: Task<Void, Never>?
    
    private init() {
        let containerID = "iCloud.com.nestling.app"
        self.container = CKContainer(identifier: containerID)
        self.privateDatabase = container.privateCloudDatabase
        self.sharedDatabase = container.sharedCloudDatabase
        self.dataStore = DataStoreSelector.create()
        
        // Check if family sharing is enabled
        self.isEnabled = UserDefaults.standard.bool(forKey: "caregiver_sync_enabled")
        
        if isEnabled {
            setupSyncMonitoring()
        }
    }
    
    // MARK: - Enable/Disable
    
    /// Enable family sharing and sync
    func enable() async throws {
        // Check CloudKit account status
        let status = try await container.accountStatus()
        
        guard status == .available else {
            throw CaregiverSyncError.cloudKitUnavailable(status: status)
        }
        
        isEnabled = true
        UserDefaults.standard.set(true, forKey: "caregiver_sync_enabled")
        
        setupSyncMonitoring()
        
        // Trigger initial sync
        await syncAll()
    }
    
    /// Disable family sharing
    func disable() {
        isEnabled = false
        UserDefaults.standard.set(false, forKey: "caregiver_sync_enabled")
        
        syncTask?.cancel()
        syncTask = nil
    }
    
    // MARK: - Sync Operations
    
    private func setupSyncMonitoring() {
        syncTask = Task {
            for await _ in NetworkMonitor.shared.$isConnected.values {
                if NetworkMonitor.shared.isConnected && pendingCount > 0 && !isSyncing {
                    await syncAll()
                }
            }
        }
    }
    
    /// Sync all data with CloudKit shared database
    func syncAll() async {
        guard isEnabled else { return }
        guard NetworkMonitor.shared.isConnected else { return }
        guard !isSyncing else { return }
        
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            // Sync babies
            try await syncBabies()
            
            // Sync events
            try await syncEvents()
            
            lastSyncTime = Date()
            Logger.dataInfo("Caregiver sync completed successfully")
        } catch {
            Logger.dataError("Caregiver sync failed: \(error.localizedDescription)")
        }
    }
    
    private func syncBabies() async throws {
        let babies = try await dataStore.fetchBabies()
        
        for baby in babies {
            try await uploadBaby(baby)
        }
    }
    
    private func syncEvents() async throws {
        // Sync last 7 days of events
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        let babies = try await dataStore.fetchBabies()
        for baby in babies {
            let events = try await dataStore.fetchEvents(for: baby, from: sevenDaysAgo, to: Date())
            for event in events {
                try await uploadEvent(event, baby: baby)
            }
        }
    }
    
    private func uploadBaby(_ baby: Baby) async throws {
        let recordID = CKRecord.ID(recordName: baby.id.uuidString)
        let record = CKRecord(recordType: "Baby", recordID: recordID)
        
        record["name"] = baby.name as CKRecordValue
        record["dateOfBirth"] = baby.dateOfBirth as CKRecordValue
        record["sex"] = baby.sex?.rawValue as CKRecordValue?
        record["primaryFeedingStyle"] = baby.primaryFeedingStyle?.rawValue as CKRecordValue?
        record["timezone"] = baby.timezone as CKRecordValue
        record["createdAt"] = baby.createdAt as CKRecordValue
        record["updatedAt"] = baby.updatedAt as CKRecordValue
        
        try await sharedDatabase.save(record)
    }
    
    private func uploadEvent(_ event: Event, baby: Baby) async throws {
        let recordID = CKRecord.ID(recordName: event.id.uuidString)
        let record = CKRecord(recordType: "Event", recordID: recordID)
        
        // Create reference to baby
        let babyReference = CKRecord.Reference(recordID: CKRecord.ID(recordName: baby.id.uuidString), action: .deleteSelf)
        record["baby"] = babyReference
        
        record["type"] = event.type.rawValue as CKRecordValue
        record["subtype"] = event.subtype as CKRecordValue?
        record["amount"] = event.amount as CKRecordValue?
        record["unit"] = event.unit as CKRecordValue?
        record["side"] = event.side as CKRecordValue?
        record["startTime"] = event.startTime as CKRecordValue
        record["endTime"] = event.endTime as CKRecordValue?
        record["durationMinutes"] = event.durationMinutes as CKRecordValue?
        record["note"] = event.note as CKRecordValue?
        record["createdAt"] = event.createdAt as CKRecordValue
        record["updatedAt"] = event.updatedAt as CKRecordValue
        
        try await sharedDatabase.save(record)
    }
    
    // MARK: - Conflict Resolution
    
    /// Resolve conflicts using last-write-wins
    func resolveConflict<T>(local: T, remote: T, localTimestamp: Date, remoteTimestamp: Date) -> T {
        if localTimestamp >= remoteTimestamp {
            Logger.dataInfo("Caregiver sync conflict: keeping local version (newer)")
            return local
        } else {
            Logger.dataInfo("Caregiver sync conflict: keeping remote version (newer)")
            return remote
        }
    }
    
    // MARK: - Caregiver Management
    
    /// Invite a caregiver to share data
    func inviteCaregiver(email: String, role: CaregiverRole) async throws -> String {
        // Generate invite code
        let inviteCode = UUID().uuidString
        
        // Store invite in CloudKit
        let record = CKRecord(recordType: "Invite")
        record["email"] = email as CKRecordValue
        record["role"] = role.rawValue as CKRecordValue
        record["inviteCode"] = inviteCode as CKRecordValue
        record["createdAt"] = Date() as CKRecordValue
        record["status"] = "pending" as CKRecordValue
        
        try await sharedDatabase.save(record)
        
        // Track analytics
        AnalyticsService.shared.track(event: "caregiver_invited", properties: [
            "invited_role": role.rawValue
        ])
        
        return inviteCode
    }
    
    /// Accept an invite
    func acceptInvite(code: String) async throws {
        // Fetch invite record
        let query = CKQuery(recordType: "Invite", predicate: NSPredicate(format: "inviteCode == %@", code))
        let (results, _) = try await sharedDatabase.records(matching: query)
        
        guard let (_, result) = results.first(where: { _ in true }) else {
            throw CaregiverSyncError.inviteNotFound
        }
        
        guard case .success(let record) = result else {
            throw CaregiverSyncError.inviteFetchFailed
        }
        
        // Update invite status
        record["status"] = "accepted" as CKRecordValue
        record["acceptedAt"] = Date() as CKRecordValue
        
        try await sharedDatabase.save(record)
        
        // Enable sync
        try await enable()
        
        // Track analytics
        AnalyticsService.shared.track(event: "caregiver_joined", properties: [
            "role": record["role"] as? String ?? "member"
        ])
    }
    
    /// Revoke caregiver access
    func revokeCaregiver(userId: String) async throws {
        // Find and delete caregiver records
        let query = CKQuery(recordType: "Caregiver", predicate: NSPredicate(format: "userId == %@", userId))
        let (results, _) = try await sharedDatabase.records(matching: query)
        
        var recordIDsToDelete: [CKRecord.ID] = []
        for (recordID, _) in results {
            recordIDsToDelete.append(recordID)
        }
        
        if !recordIDsToDelete.isEmpty {
            _ = try await sharedDatabase.modifyRecords(saving: [], deleting: recordIDsToDelete)
        }
        
        // Track analytics
        AnalyticsService.shared.track(event: "caregiver_revoked", properties: [:])
    }
}

/// Caregiver role
enum CaregiverRole: String, Codable {
    case owner
    case admin
    case member
    case viewer
    
    var displayName: String {
        switch self {
        case .owner: return "Owner"
        case .admin: return "Admin"
        case .member: return "Caregiver"
        case .viewer: return "Viewer"
        }
    }
}

/// Caregiver sync errors
enum CaregiverSyncError: LocalizedError {
    case cloudKitUnavailable(status: CKAccountStatus)
    case inviteNotFound
    case inviteFetchFailed
    case syncFailed
    
    var errorDescription: String? {
        switch self {
        case .cloudKitUnavailable(let status):
            switch status {
            case .noAccount:
                return "No iCloud account found. Please sign in to iCloud in Settings."
            case .restricted:
                return "iCloud access is restricted. Please check parental controls."
            default:
                return "iCloud is currently unavailable. Please try again later."
            }
        case .inviteNotFound:
            return "Invite code not found or has expired."
        case .inviteFetchFailed:
            return "Could not fetch invite. Please check your internet connection."
        case .syncFailed:
            return "Sync failed. Your changes will be synced when connection is restored."
        }
    }
}

