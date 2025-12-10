import Foundation
import CoreData
import CloudKit
import Combine

enum DataStoreType {
    case inMemory
    case json
    case coreData
}

/// Factory for selecting DataStore implementation.
/// Can be configured via environment variable or build setting.
class DataStoreSelector {
    static func create() -> DataStore {
        #if USE_REMOTE_STORE
        // Use RemoteDataStore if Supabase is configured
        if SupabaseClientProvider.shared.isConfigured {
            // TODO: Get URL and key from config
            // return RemoteDataStore(supabaseURL: url, anonKey: key)
        }
        #endif
        
        #if USE_CORE_DATA
        return CoreDataDataStore()
        #elseif USE_JSON_STORE
        return JSONBackedDataStore()
        #else
        // Default: Use Core Data if available, fallback to JSON
        // Check if CoreData store file exists without triggering lazy initialization
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let coreDataURL = documentsPath.appendingPathComponent("Nestling.sqlite")
        // App Group container (must match widgets/intents capabilities)
        let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.nestling.app.shared")?
            .appendingPathComponent("Nestling.sqlite")
        
        // Check both possible locations
        let coreDataExists = FileManager.default.fileExists(atPath: coreDataURL.path) ||
                            (appGroupURL != nil && FileManager.default.fileExists(atPath: appGroupURL!.path))
        
        if coreDataExists {
            return CoreDataDataStore()
        } else {
            return JSONBackedDataStore()
        }
        #endif
    }
    
    static func createForPreview() -> DataStore {
        return InMemoryDataStore()
    }
    
    /// Create RemoteDataStore if Supabase is configured, otherwise fallback
    static func createWithRemoteFallback(supabaseURL: String? = nil, anonKey: String? = nil) -> DataStore {
        // RemoteDataStore now uses environment variables automatically
        // If credentials are provided, they should be set via SUPABASE_URL and SUPABASE_ANON_KEY environment variables
        if SupabaseClientProvider.shared.isConfigured {
            // RemoteDataStore requires additional setup - fallback for now
            // return RemoteDataStore()
        }
        
        // Fallback to default
        return create()
    }
}

// MARK: - CloudKit Sync Service (inlined to ensure target inclusion)

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
    private let eventRecordType = "Event"
    private let daysBackToSync = 30
    
    private init() {
        let containerID = "iCloud.com.nestling.app"
        self.container = CKContainer(identifier: containerID)
        self.privateDatabase = container.privateCloudDatabase
        self.dataStore = DataStoreSelector.create()
        
        // Check if sync is enabled
        self.isEnabled = UserDefaults.standard.bool(forKey: "cloudkit_sync_enabled")
    }
    
    // MARK: - Sync Control
    
    func enable() async throws {
        let status = try await container.accountStatus()
        guard status == .available else {
            let message = cloudKitErrorMessage(for: status)
            throw NSError(domain: "CloudKitSync", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
        }
        
        isEnabled = true
        UserDefaults.standard.set(true, forKey: "cloudkit_sync_enabled")
        await syncAll()
    }
    
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
    
    func syncAll() async {
        guard isEnabled else { return }
        guard !isSyncing else { return }
        
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            try await syncBabies()
            try await syncEvents()
            try await pullRemoteEvents()
            
            lastSyncTime = Date()
            syncError = nil
            print("CloudKit sync completed successfully")
        } catch {
            syncError = error
            print("CloudKit sync failed: \(error.localizedDescription)")
        }
    }
    
    private func syncBabies() async throws {
        let babies = try await dataStore.fetchBabies()
        for baby in babies {
            try await uploadBaby(baby)
        }
    }
    
    private func syncEvents() async throws {
        let startDate = Calendar.current.date(byAdding: .day, value: -daysBackToSync, to: Date()) ?? Date()
        let endDate = Date()
        
        let babies = try await dataStore.fetchBabies()
        for baby in babies {
            let events = try await dataStore.fetchEvents(for: baby, from: startDate, to: endDate)
            for event in events {
                try await uploadEvent(event)
            }
        }
    }
    
    private func uploadBaby(_ baby: Baby) async throws {
        let record = CKRecord(recordType: "Baby", recordID: CKRecord.ID(recordName: baby.id.uuidString))
        record["name"] = baby.name as CKRecordValue
        record["dateOfBirth"] = baby.dateOfBirth as CKRecordValue
        record["sex"] = baby.sex?.rawValue as CKRecordValue?
        record["primaryFeedingStyle"] = baby.primaryFeedingStyle?.rawValue as CKRecordValue?
        record["timezone"] = baby.timezone as CKRecordValue
        record["createdAt"] = baby.createdAt as CKRecordValue
        record["updatedAt"] = baby.updatedAt as CKRecordValue
        
        try await privateDatabase.save(record)
    }
    
    private func uploadEvent(_ event: Event) async throws {
        let recordID = CKRecord.ID(recordName: event.id.uuidString)
        let remoteRecord = try? await privateDatabase.record(for: recordID)
        let remoteUpdatedAt = remoteRecord?["updatedAt"] as? Date ?? .distantPast
        
        let winner = resolveConflict(
            local: event,
            remote: remoteRecord as Any,
            timestamp: event.updatedAt,
            remoteTimestamp: remoteUpdatedAt
        )
        
        guard winner is Event else { return }
        
        let record = record(from: event, recordID: recordID)
        try await privateDatabase.modifyRecords(saving: [record], deleting: [])
    }
    
    private func record(from event: Event, recordID: CKRecord.ID? = nil) -> CKRecord {
        let record = CKRecord(recordType: eventRecordType, recordID: recordID ?? CKRecord.ID(recordName: event.id.uuidString))
        record["babyId"] = event.babyId.uuidString as CKRecordValue
        record["type"] = event.type.rawValue as CKRecordValue
        if let subtype = event.subtype { record["subtype"] = subtype as CKRecordValue }
        record["startTime"] = event.startTime as CKRecordValue
        if let endTime = event.endTime { record["endTime"] = endTime as CKRecordValue }
        if let amount = event.amount { record["amount"] = amount as CKRecordValue }
        if let unit = event.unit { record["unit"] = unit as CKRecordValue }
        if let side = event.side { record["side"] = side as CKRecordValue }
        if let note = event.note { record["note"] = note as CKRecordValue }
        if let photos = event.photoUrls { record["photoUrls"] = photos as CKRecordValue }
        record["createdAt"] = event.createdAt as CKRecordValue
        record["updatedAt"] = event.updatedAt as CKRecordValue
        return record
    }
    
    // MARK: - Download & Merge
    
    private func pullRemoteEvents() async throws {
        let startDate = Calendar.current.date(byAdding: .day, value: -daysBackToSync, to: Date()) ?? Date()
        let endDate = Date()
        
        let babies = try await dataStore.fetchBabies()
        var localEventsById: [UUID: Event] = [:]
        for baby in babies {
            let localEvents = try await dataStore.fetchEvents(for: baby, from: startDate, to: endDate)
            for event in localEvents {
                localEventsById[event.id] = event
            }
        }
        
        let remoteEvents = try await fetchRemoteEvents(from: startDate, to: endDate)
        
        for remoteEvent in remoteEvents {
            let local = localEventsById[remoteEvent.id]
            let resolved = resolveConflict(
                local: local as Any,
                remote: remoteEvent as Any,
                timestamp: local?.updatedAt ?? .distantPast,
                remoteTimestamp: remoteEvent.updatedAt
            )
            
            guard let winner = resolved as? Event else { continue }
            
            if let local = local {
                if winner.updatedAt > local.updatedAt {
                    try await dataStore.updateEvent(winner)
                }
            } else {
                try await dataStore.addEvent(winner)
            }
        }
    }
    
    private func fetchRemoteEvents(from startDate: Date, to endDate: Date) async throws -> [Event] {
        let predicate = NSPredicate(format: "startTime >= %@ AND startTime <= %@", startDate as NSDate, endDate as NSDate)
        let query = CKQuery(recordType: eventRecordType, predicate: predicate)
        var fetched: [Event] = []
        
        try await withCheckedThrowingContinuation { continuation in
            let operation = CKQueryOperation(query: query)
            operation.recordMatchedBlock = { _, result in
                switch result {
                case .success(let record):
                    if let event = self.event(from: record) {
                        fetched.append(event)
                    }
                case .failure(let error):
                    print("Failed to fetch record: \(error.localizedDescription)")
                }
            }
            
            operation.queryResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume(returning: ())
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            self.privateDatabase.add(operation)
        }
        
        return fetched
    }
    
    private func event(from record: CKRecord) -> Event? {
        guard let babyIdString = record["babyId"] as? String,
              let babyId = UUID(uuidString: babyIdString),
              let typeRaw = record["type"] as? String,
              let eventType = EventType(rawValue: typeRaw),
              let startTime = record["startTime"] as? Date,
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date else {
            return nil
        }
        
        let endTime = record["endTime"] as? Date
        let amount = record["amount"] as? Double
        let unit = record["unit"] as? String
        let subtype = record["subtype"] as? String
        let side = record["side"] as? String
        let note = record["note"] as? String
        let photos = record["photoUrls"] as? [String]
        
        return Event(
            id: UUID(uuidString: record.recordID.recordName) ?? UUID(),
            babyId: babyId,
            type: eventType,
            subtype: subtype,
            startTime: startTime,
            endTime: endTime,
            amount: amount,
            unit: unit,
            side: side,
            note: note,
            photoUrls: photos,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    // MARK: - Conflict Resolution
    
    func resolveConflict(local: Any, remote: Any, timestamp localTimestamp: Date, remoteTimestamp: Date) -> Any {
        if localTimestamp > remoteTimestamp {
            print("Conflict resolved: keeping local version")
            return local
        } else {
            print("Conflict resolved: keeping remote version")
            return remote
        }
    }
}

