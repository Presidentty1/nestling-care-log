import Foundation
import CoreData

/// Represents a queued operation that failed due to network issues
struct QueuedOperation: Codable {
    let id: UUID
    let operationType: OperationType
    let entityType: EntityType
    let entityId: UUID?
    let data: Data // JSON-encoded operation data
    let timestamp: Date
    var retryCount: Int

    enum OperationType: String, Codable {
        case addBaby
        case updateBaby
        case deleteBaby
        case addEvent
        case updateEvent
        case deleteEvent
        case updateSettings
    }

    enum EntityType: String, Codable {
        case baby
        case event
        case settings
    }
}

/// Service for queuing operations when offline and syncing when connectivity is restored
/// Uses Core Data for persistent queue storage
@MainActor
class OfflineQueueService: ObservableObject {
    static let shared = OfflineQueueService()

    @Published private(set) var pendingCount: Int = 0
    @Published private(set) var isSyncing: Bool = false

    private var dataStore: DataStore
    private var syncTask: Task<Void, Never>?
    private let maxRetries = 3
    
    // Core Data context for queue storage
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "OfflineQueue")
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                Logger.dataError("Failed to load offline queue store: \(error.localizedDescription)")
            }
        }
        return container
    }()

    private init() {
        self.dataStore = DataStoreSelector.create()
        
        Task {
            await loadQueueFromCoreData()
            await setupConnectivityMonitoring()
        }
    }

    private func setupConnectivityMonitoring() async {
        for await _ in NetworkMonitor.shared.$isConnected.values {
            if NetworkMonitor.shared.isConnected && pendingCount > 0 && !isSyncing {
                await processQueue()
            }
        }
    }

    /// Queue an operation for later execution
    func queueOperation(_ operation: QueuedOperation) async {
        await saveOperationToCoreData(operation)
        await updatePendingCount()
        Logger.dataInfo("Queued operation: \(operation.operationType) (\(pendingCount) pending)")
    }

    /// Process all queued operations
    func processQueue() async {
        guard pendingCount > 0 && !isSyncing else { return }

        isSyncing = true
        defer { isSyncing = false }

        Logger.dataInfo("Processing offline queue (\(pendingCount) operations)")

        let operations = await loadOperationsFromCoreData()
        
        var processed = 0
        var failed = 0

        // Process operations in order
        for operation in operations.sorted(by: { $0.timestamp < $1.timestamp }) {
            do {
                try await executeOperation(operation)
                await removeOperationFromCoreData(operation)
                processed += 1
            } catch {
                Logger.dataError("Operation failed: \(operation.operationType) - \(error.localizedDescription)")

                if operation.retryCount < maxRetries {
                    // Retry later
                    await updateOperationRetryCount(operation, operation.retryCount + 1)
                } else {
                    // Give up after max retries
                    await removeOperationFromCoreData(operation)
                    failed += 1
                }
            }
        }

        await updatePendingCount()

        if processed > 0 {
            Logger.dataInfo("Successfully synced \(processed) operations")
        }

        if failed > 0 {
            Logger.dataError("Failed to sync \(failed) operations after max retries")
        }
    }

    private func executeOperation(_ operation: QueuedOperation) async throws {
        switch operation.operationType {
        case .addBaby:
            let baby = try decodeBaby(from: operation.data)
            try await dataStore.addBaby(baby)

        case .updateBaby:
            let baby = try decodeBaby(from: operation.data)
            try await dataStore.updateBaby(baby)

        case .deleteBaby:
            let baby = try decodeBaby(from: operation.data)
            try await dataStore.deleteBaby(baby)

        case .addEvent:
            let event = try decodeEvent(from: operation.data)
            try await dataStore.addEvent(event)

        case .updateEvent:
            let event = try decodeEvent(from: operation.data)
            try await dataStore.updateEvent(event)

        case .deleteEvent:
            let event = try decodeEvent(from: operation.data)
            try await dataStore.deleteEvent(event)

        case .updateSettings:
            let settings = try decodeSettings(from: operation.data)
            try await dataStore.saveAppSettings(settings)
        }
    }

    // MARK: - Core Data Queue Management

    private func loadQueueFromCoreData() async {
        await updatePendingCount()
    }

    private func saveOperationToCoreData(_ operation: QueuedOperation) async {
        await persistentContainer.performBackgroundTask { context in
            let queueItem = NSEntityDescription.insertNewObject(forEntityName: "QueuedOperationEntity", into: context)
            queueItem.setValue(operation.id, forKey: "id")
            queueItem.setValue(operation.operationType.rawValue, forKey: "operationType")
            queueItem.setValue(operation.entityType.rawValue, forKey: "entityType")
            queueItem.setValue(operation.entityId, forKey: "entityId")
            queueItem.setValue(operation.data, forKey: "data")
            queueItem.setValue(operation.timestamp, forKey: "timestamp")
            queueItem.setValue(operation.retryCount, forKey: "retryCount")
            
            try? context.save()
        }
    }

    private func loadOperationsFromCoreData() async -> [QueuedOperation] {
        await persistentContainer.performBackgroundTask { context in
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "QueuedOperationEntity")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
            
            guard let results = try? context.fetch(fetchRequest) else {
                return []
            }
            
            return results.compactMap { obj -> QueuedOperation? in
                guard let id = obj.value(forKey: "id") as? UUID,
                      let opTypeRaw = obj.value(forKey: "operationType") as? String,
                      let operationType = QueuedOperation.OperationType(rawValue: opTypeRaw),
                      let entityTypeRaw = obj.value(forKey: "entityType") as? String,
                      let entityType = QueuedOperation.EntityType(rawValue: entityTypeRaw),
                      let data = obj.value(forKey: "data") as? Data,
                      let timestamp = obj.value(forKey: "timestamp") as? Date else {
                    return nil
                }
                
                let entityId = obj.value(forKey: "entityId") as? UUID
                let retryCount = obj.value(forKey: "retryCount") as? Int ?? 0
                
                return QueuedOperation(
                    id: id,
                    operationType: operationType,
                    entityType: entityType,
                    entityId: entityId,
                    data: data,
                    timestamp: timestamp,
                    retryCount: retryCount
                )
            }
        }
    }

    private func removeOperationFromCoreData(_ operation: QueuedOperation) async {
        await persistentContainer.performBackgroundTask { context in
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "QueuedOperationEntity")
            fetchRequest.predicate = NSPredicate(format: "id == %@", operation.id as CVarArg)
            
            if let results = try? context.fetch(fetchRequest), let obj = results.first {
                context.delete(obj)
                try? context.save()
            }
        }
    }

    private func updateOperationRetryCount(_ operation: QueuedOperation, _ retryCount: Int) async {
        await persistentContainer.performBackgroundTask { context in
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "QueuedOperationEntity")
            fetchRequest.predicate = NSPredicate(format: "id == %@", operation.id as CVarArg)
            
            if let results = try? context.fetch(fetchRequest), let obj = results.first {
                obj.setValue(retryCount, forKey: "retryCount")
                try? context.save()
            }
        }
    }

    private func updatePendingCount() async {
        let operations = await loadOperationsFromCoreData()
        pendingCount = operations.count
    }

    // MARK: - Data Decoding Helpers

    private func decodeBaby(from data: Data) throws -> Baby {
        try JSONDecoder().decode(Baby.self, from: data)
    }

    private func decodeEvent(from data: Data) throws -> Event {
        try JSONDecoder().decode(Event.self, from: data)
    }

    private func decodeSettings(from data: Data) throws -> AppSettings {
        try JSONDecoder().decode(AppSettings.self, from: data)
    }

    // MARK: - Public API for DataStore Integration

    /// Queue a baby operation
    func queueBabyOperation(_ operationType: QueuedOperation.OperationType, baby: Baby) async {
        guard operationType == .addBaby || operationType == .updateBaby || operationType == .deleteBaby else {
            Logger.dataError("Invalid operation type for baby: \(operationType)")
            return
        }

        guard let data = try? JSONEncoder().encode(baby) else {
            Logger.dataError("Failed to encode baby for queuing")
            return
        }

        let operation = QueuedOperation(
            id: UUID(),
            operationType: operationType,
            entityType: .baby,
            entityId: baby.id,
            data: data,
            timestamp: Date(),
            retryCount: 0
        )

        await queueOperation(operation)
    }

    /// Queue an event operation
    func queueEventOperation(_ operationType: QueuedOperation.OperationType, event: Event) async {
        guard operationType == .addEvent || operationType == .updateEvent || operationType == .deleteEvent else {
            Logger.dataError("Invalid operation type for event: \(operationType)")
            return
        }

        guard let data = try? JSONEncoder().encode(event) else {
            Logger.dataError("Failed to encode event for queuing")
            return
        }

        let operation = QueuedOperation(
            id: UUID(),
            operationType: operationType,
            entityType: .event,
            entityId: event.id,
            data: data,
            timestamp: Date(),
            retryCount: 0
        )

        await queueOperation(operation)
    }

    /// Queue a settings operation
    func queueSettingsOperation(settings: AppSettings) async {
        guard let data = try? JSONEncoder().encode(settings) else {
            Logger.dataError("Failed to encode settings for queuing")
            return
        }

        let operation = QueuedOperation(
            id: UUID(),
            operationType: .updateSettings,
            entityType: .settings,
            entityId: nil,
            data: data,
            timestamp: Date(),
            retryCount: 0
        )

        await queueOperation(operation)
    }
}




