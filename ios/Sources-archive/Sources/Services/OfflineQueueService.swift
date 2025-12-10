import Foundation

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
@MainActor
class OfflineQueueService: ObservableObject {
    static let shared = OfflineQueueService()

    @Published private(set) var pendingCount: Int = 0
    @Published private(set) var isSyncing: Bool = false

    private var queue: [QueuedOperation] = []
    private let queueKey = "nestling-offline-queue"
    private let maxRetries = 3
    private var dataStore: DataStore
    private var syncTask: Task<Void, Never>?

    private init() {
        self.dataStore = DataStoreSelector.create()
        loadQueue()

        // Listen for connectivity changes
        Task {
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
    func queueOperation(_ operation: QueuedOperation) {
        queue.append(operation)
        pendingCount = queue.count
        saveQueue()
        Logger.dataInfo("Queued operation: \(operation.operationType) (\(pendingCount) pending)")
    }

    /// Process all queued operations
    func processQueue() async {
        guard !queue.isEmpty && !isSyncing else { return }

        isSyncing = true
        defer { isSyncing = false }

        Logger.dataInfo("Processing offline queue (\(queue.count) operations)")

        var processed = 0
        var failed = 0

        // Process operations in order
        for operation in queue.sorted(by: { $0.timestamp < $1.timestamp }) {
            do {
                try await executeOperation(operation)
                removeOperation(operation)
                processed += 1
            } catch {
                Logger.dataError("Operation failed: \(operation.operationType) - \(error.localizedDescription)")

                if operation.retryCount < maxRetries {
                    // Retry later
                    updateOperationRetryCount(operation, operation.retryCount + 1)
                } else {
                    // Give up after max retries
                    removeOperation(operation)
                    failed += 1
                }
            }
        }

        pendingCount = queue.count

        if processed > 0 {
            Logger.dataInfo("Successfully synced \(processed) operations")
            // Could show success toast here
        }

        if failed > 0 {
            Logger.dataError("Failed to sync \(failed) operations after max retries")
            // Could show error toast here
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

    // MARK: - Queue Management

    private func loadQueue() {
        if let data = UserDefaults.standard.data(forKey: queueKey),
           let decoded = try? JSONDecoder().decode([QueuedOperation].self, from: data) {
            queue = decoded
            pendingCount = queue.count
        }
    }

    private func saveQueue() {
        if let data = try? JSONEncoder().encode(queue) {
            UserDefaults.standard.set(data, forKey: queueKey)
        }
    }

    private func removeOperation(_ operation: QueuedOperation) {
        queue.removeAll { $0.id == operation.id }
        saveQueue()
    }

    private func updateOperationRetryCount(_ operation: QueuedOperation, _ retryCount: Int) {
        if let index = queue.firstIndex(where: { $0.id == operation.id }) {
            queue[index].retryCount = retryCount
            saveQueue()
        }
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
    func queueBabyOperation(_ operationType: QueuedOperation.OperationType, baby: Baby) {
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

        queueOperation(operation)
    }

    /// Queue an event operation
    func queueEventOperation(_ operationType: QueuedOperation.OperationType, event: Event) {
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

        queueOperation(operation)
    }

    /// Queue a settings operation
    func queueSettingsOperation(settings: AppSettings) {
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

        queueOperation(operation)
    }
}


