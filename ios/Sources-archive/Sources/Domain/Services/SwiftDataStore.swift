import Foundation
import SwiftData
import CloudKit

/// SwiftData implementation of DataStore with CloudKit sync support.
/// Provides optional cloud synchronization for multi-caregiver scenarios.
@MainActor
class SwiftDataStore: DataStore {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext

    init() throws {
        let schema = Schema([
            SyncBaby.self,
            SyncEvent.self,
            SyncPrediction.self,
            SyncAppSettings.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic // Enable CloudKit sync
        )

        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        modelContext = ModelContext(modelContainer)
    }

    // MARK: - Babies

    func fetchBabies() async throws -> [Baby] {
        let descriptor = FetchDescriptor<SyncBaby>()
        let syncBabies = try modelContext.fetch(descriptor)
        return syncBabies.map { $0.toDomainModel() }
    }

    func addBaby(_ baby: Baby) async throws {
        let syncBaby = SyncBaby.fromDomainModel(baby)
        modelContext.insert(syncBaby)
        try modelContext.save()
    }

    func updateBaby(_ baby: Baby) async throws {
        let babyId = baby.id
        let descriptor = FetchDescriptor<SyncBaby>(
            predicate: #Predicate<SyncBaby> { $0.id == babyId }
        )

        guard let existingBaby = try modelContext.fetch(descriptor).first else {
            throw DataStoreError.notFound("Baby with id \(babyId)")
        }

        // Update properties
        existingBaby.name = baby.name
        existingBaby.dateOfBirth = baby.dateOfBirth
        existingBaby.sex = baby.sex?.rawValue
        existingBaby.timezone = baby.timezone
        existingBaby.primaryFeedingStyle = baby.primaryFeedingStyle?.rawValue
        existingBaby.updatedAt = baby.updatedAt

        try modelContext.save()
    }

    func deleteBaby(_ baby: Baby) async throws {
        let babyId = baby.id
        let descriptor = FetchDescriptor<SyncBaby>(
            predicate: #Predicate<SyncBaby> { $0.id == babyId }
        )

        guard let syncBaby = try modelContext.fetch(descriptor).first else {
            throw DataStoreError.notFound("Baby with id \(babyId)")
        }

        modelContext.delete(syncBaby)
        try modelContext.save()
    }

    // MARK: - Events

    func fetchEvents(for baby: Baby, on date: Date) async throws -> [Event] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return try await fetchEvents(for: baby, from: startOfDay, to: endOfDay)
    }

    func fetchEvents(for baby: Baby, from startDate: Date, to endDate: Date) async throws -> [Event] {
        let babyId = baby.id
        let descriptor = FetchDescriptor<SyncEvent>(
            predicate: #Predicate<SyncEvent> {
                $0.babyId == babyId && $0.startTime >= startDate && $0.startTime < endDate
            },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )

        let syncEvents = try modelContext.fetch(descriptor)
        return syncEvents.map { $0.toDomainModel() }
    }

    func addEvent(_ event: Event) async throws {
        let syncEvent = SyncEvent.fromDomainModel(event)
        modelContext.insert(syncEvent)
        try modelContext.save()
    }

    func updateEvent(_ event: Event) async throws {
        let eventId = event.id
        let descriptor = FetchDescriptor<SyncEvent>(
            predicate: #Predicate<SyncEvent> { $0.id == eventId }
        )

        guard let existingEvent = try modelContext.fetch(descriptor).first else {
            throw DataStoreError.notFound("Event with id \(eventId)")
        }

        // Update all properties
        existingEvent.babyId = event.babyId
        existingEvent.type = event.type.rawValue
        existingEvent.subtype = event.subtype
        existingEvent.startTime = event.startTime
        existingEvent.endTime = event.endTime
        existingEvent.amount = event.amount
        existingEvent.unit = event.unit
        existingEvent.side = event.side
        existingEvent.note = event.note
        existingEvent.updatedAt = event.updatedAt

        try modelContext.save()
    }

    func deleteEvent(_ event: Event) async throws {
        let eventId = event.id
        let descriptor = FetchDescriptor<SyncEvent>(
            predicate: #Predicate<SyncEvent> { $0.id == eventId }
        )

        guard let syncEvent = try modelContext.fetch(descriptor).first else {
            throw DataStoreError.notFound("Event with id \(eventId)")
        }

        modelContext.delete(syncEvent)
        try modelContext.save()
    }

    // MARK: - Predictions

    func fetchPredictions(for baby: Baby, type: PredictionType) async throws -> Prediction? {
        let babyId = baby.id
        let typeString = type.rawValue

        let descriptor = FetchDescriptor<SyncPrediction>(
            predicate: #Predicate<SyncPrediction> {
                $0.babyId == babyId && $0.type == typeString && $0.expiresAt > Date()
            }
        )

        let syncPredictions = try modelContext.fetch(descriptor)
        return syncPredictions.first?.toDomainModel()
    }

    func generatePrediction(for baby: Baby, type: PredictionType) async throws -> Prediction {
        // This would contain prediction logic - for now, return a mock prediction
        // In a real implementation, this would call the prediction service
        let prediction = Prediction(
            id: UUID(),
            babyId: baby.id,
            type: type,
            predictedTime: Date().addingTimeInterval(3600), // 1 hour from now
            confidence: 0.8,
            reasoning: "Based on recent patterns",
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(7200) // 2 hours
        )

        // Store the prediction
        let syncPrediction = SyncPrediction(
            id: prediction.id,
            babyId: prediction.babyId,
            type: prediction.type.rawValue,
            predictedTime: prediction.predictedTime,
            confidence: prediction.confidence,
            reasoning: prediction.reasoning,
            createdAt: prediction.createdAt,
            expiresAt: prediction.expiresAt
        )

        modelContext.insert(syncPrediction)
        try modelContext.save()

        return prediction
    }

    // MARK: - Settings

    func fetchAppSettings() async throws -> AppSettings {
        let descriptor = FetchDescriptor<SyncAppSettings>()

        if let syncSettings = try modelContext.fetch(descriptor).first {
            return syncSettings.toDomainModel()
        } else {
            // Create default settings
            let defaultSettings = AppSettings.default()
            try await saveAppSettings(defaultSettings)
            return defaultSettings
        }
    }

    func saveAppSettings(_ settings: AppSettings) async throws {
        // Delete existing settings
        let descriptor = FetchDescriptor<SyncAppSettings>()
        let existingSettings = try modelContext.fetch(descriptor)
        existingSettings.forEach { modelContext.delete($0) }

        // Insert new settings
        let syncSettings = SyncAppSettings(from: settings)
        modelContext.insert(syncSettings)
        try modelContext.save()
    }

    // MARK: - Active Sleep Tracking

    func getActiveSleep(for baby: Baby) async throws -> Event? {
        let babyId = baby.id
        let descriptor = FetchDescriptor<SyncEvent>(
            predicate: #Predicate<SyncEvent> {
                $0.babyId == babyId && $0.type == EventType.sleep.rawValue && $0.endTime == nil
            }
        )

        let syncEvents = try modelContext.fetch(descriptor)
        return syncEvents.first?.toDomainModel()
    }

    func startActiveSleep(for baby: Baby) async throws -> Event {
        let event = Event(
            babyId: baby.id,
            type: .sleep,
            subtype: "active",
            startTime: Date()
        )

        try await addEvent(event)
        return event
    }

    func stopActiveSleep(for baby: Baby) async throws -> Event {
        guard let activeSleep = try await getActiveSleep(for: baby) else {
            throw DataStoreError.notFound("No active sleep found for baby")
        }

        let completedEvent = Event(
            id: activeSleep.id,
            babyId: activeSleep.babyId,
            type: activeSleep.type,
            subtype: activeSleep.subtype,
            startTime: activeSleep.startTime,
            endTime: Date(),
            note: activeSleep.note,
            createdAt: activeSleep.createdAt,
            updatedAt: Date()
        )

        try await updateEvent(completedEvent)
        return completedEvent
    }

    // MARK: - Last Used Values

    func getLastUsedValues(for eventType: EventType) async throws -> LastUsedValues? {
        // For SwiftData implementation, we could store this in a separate table
        // For now, return nil - this could be enhanced later
        return nil
    }

    func saveLastUsedValues(for eventType: EventType, values: LastUsedValues) async throws {
        // For SwiftData implementation, we could store this in a separate table
        // For now, do nothing - this could be enhanced later
    }

    // MARK: - Data Persistence

    func forceSyncIfNeeded() async throws {
        // SwiftData with CloudKit handles syncing automatically
        // We could trigger a manual sync here if needed
        try modelContext.save()
    }
}

// MARK: - Extensions

extension SyncPrediction {
    func toDomainModel() -> Prediction {
        return Prediction(
            id: id,
            babyId: babyId,
            type: PredictionType(rawValue: type) ?? .nextNap,
            predictedTime: predictedTime,
            confidence: confidence,
            reasoning: reasoning,
            createdAt: createdAt,
            expiresAt: expiresAt
        )
    }
}