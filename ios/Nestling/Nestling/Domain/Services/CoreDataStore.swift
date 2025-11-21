import Foundation
import CoreData
import os.signpost

/// Core Data implementation of the DataStore protocol.
/// Provides persistent, offline-first data storage for the iOS app.
@MainActor
class CoreDataStore: DataStore {
    private let logger = Logger(subsystem: "com.nestling.app", category: "CoreDataStore")
    private lazy var signpostID = OSSignpostID(log: SignpostLogger.dataStore)

    // MARK: - Core Data Stack

    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "NestlingDataModel")

        // Enable automatic lightweight migration
        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description?.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)

        container.loadPersistentStores { [weak self] (storeDescription, error) in
            if let error = error as NSError? {
                self?.logger.error("Failed to load Core Data stack: \(error.localizedDescription)")

                // For development, delete and recreate the store on error
                #if DEBUG
                if let url = storeDescription.url {
                    try? FileManager.default.removeItem(at: url)
                    self?.logger.info("Deleted corrupted store, attempting to recreate")
                    container.loadPersistentStores { (storeDescription, error) in
                        if let error = error as NSError? {
                            fatalError("Failed to recreate Core Data stack: \(error.localizedDescription)")
                        }
                    }
                }
                #else
                fatalError("Failed to load Core Data stack: \(error.localizedDescription)")
                #endif
            }
        }

        // Merge policy for conflict resolution
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true

        return container
    }()

    private var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    // Background context for heavy operations
    private lazy var backgroundContext: NSManagedObjectContext = {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.automaticallyMergesChangesFromParent = true
        return context
    }()

    init() {
        logger.info("CoreDataStore initialized")
    }

    // MARK: - Private Helper Methods

    private func saveContext(_ context: NSManagedObjectContext) async throws {
        guard context.hasChanges else { return }

        try await context.perform {
            do {
                try context.save()
            } catch {
                context.rollback()
                throw error
            }
        }
    }

    private func fetchBabyMO(id: UUID, context: NSManagedObjectContext) throws -> BabyMO? {
        let request = BabyMO.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private func fetchEventMO(id: UUID, context: NSManagedObjectContext) throws -> EventMO? {
        let request = EventMO.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private func fetchPredictionMO(babyId: UUID, type: PredictionType, context: NSManagedObjectContext) throws -> PredictionMO? {
        let request = PredictionMO.fetchRequest()
        request.predicate = NSPredicate(format: "babyId == %@ AND type == %@", babyId as CVarArg, type.rawValue)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    // MARK: - Babies

    func fetchBabies() async throws -> [Baby] {
        let signpostID = OSSignpostID(log: SignpostLogger.dataStore)
        os_signpost(.begin, log: SignpostLogger.dataStore, name: "FetchBabies", signpostID: signpostID)

        let babies: [Baby] = try await backgroundContext.perform {
            let request = BabyMO.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

            let babyMOs = try self.backgroundContext.fetch(request)
            return babyMOs.map { $0.toBaby() }
        }

        os_signpost(.end, log: SignpostLogger.dataStore, name: "FetchBabies", signpostID: signpostID)
        return babies
    }

    func addBaby(_ baby: Baby) async throws {
        try await backgroundContext.perform {
            let babyMO = BabyMO(context: self.backgroundContext)
            babyMO.configure(with: baby)
        }
        try await saveContext(backgroundContext)
        logger.info("Added baby: \(baby.name)")
    }

    func updateBaby(_ baby: Baby) async throws {
        try await backgroundContext.perform {
            guard let babyMO = try self.fetchBabyMO(id: baby.id, context: self.backgroundContext) else {
                throw NSError(domain: "CoreDataStore", code: 404, userInfo: [NSLocalizedDescriptionKey: "Baby not found"])
            }
            babyMO.configure(with: baby)
        }
        try await saveContext(backgroundContext)
        logger.info("Updated baby: \(baby.name)")
    }

    func deleteBaby(_ baby: Baby) async throws {
        try await backgroundContext.perform {
            guard let babyMO = try self.fetchBabyMO(id: baby.id, context: self.backgroundContext) else {
                throw NSError(domain: "CoreDataStore", code: 404, userInfo: [NSLocalizedDescriptionKey: "Baby not found"])
            }
            self.backgroundContext.delete(babyMO)
        }
        try await saveContext(backgroundContext)
        logger.info("Deleted baby: \(baby.name)")
    }

    // MARK: - Events

    func fetchEvents(for baby: Baby, on date: Date) async throws -> [Event] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return try await fetchEvents(for: baby, from: startOfDay, to: endOfDay)
    }

    func fetchEvents(for baby: Baby, from startDate: Date, to endDate: Date) async throws -> [Event] {
        let signpostID = OSSignpostID(log: SignpostLogger.dataStore)
        os_signpost(.begin, log: SignpostLogger.dataStore, name: "FetchEvents", signpostID: signpostID)

        let events: [Event] = try await backgroundContext.perform {
            let request = EventMO.fetchRequest()
            request.predicate = NSPredicate(
                format: "babyId == %@ AND startTime >= %@ AND startTime < %@",
                baby.id as CVarArg, startDate as CVarArg, endDate as CVarArg
            )
            request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]

            let eventMOs = try self.backgroundContext.fetch(request)
            return eventMOs.map { $0.toEvent() }
        }

        os_signpost(.end, log: SignpostLogger.dataStore, name: "FetchEvents", signpostID: signpostID)
        return events
    }

    func addEvent(_ event: Event) async throws {
        try await backgroundContext.perform {
            let eventMO = EventMO(context: self.backgroundContext)
            eventMO.configure(with: event)
        }
        try await saveContext(backgroundContext)
        logger.info("Added event: \(event.type.rawValue)")
    }

    func updateEvent(_ event: Event) async throws {
        try await backgroundContext.perform {
            guard let eventMO = try self.fetchEventMO(id: event.id, context: self.backgroundContext) else {
                throw NSError(domain: "CoreDataStore", code: 404, userInfo: [NSLocalizedDescriptionKey: "Event not found"])
            }
            eventMO.configure(with: event)
        }
        try await saveContext(backgroundContext)
        logger.info("Updated event: \(event.type.rawValue)")
    }

    func deleteEvent(_ event: Event) async throws {
        try await backgroundContext.perform {
            guard let eventMO = try self.fetchEventMO(id: event.id, context: self.backgroundContext) else {
                throw NSError(domain: "CoreDataStore", code: 404, userInfo: [NSLocalizedDescriptionKey: "Event not found"])
            }
            self.backgroundContext.delete(eventMO)
        }
        try await saveContext(backgroundContext)
        logger.info("Deleted event: \(event.type.rawValue)")
    }

    // MARK: - Predictions

    func fetchPredictions(for baby: Baby, type: PredictionType) async throws -> Prediction? {
        try await backgroundContext.perform {
            guard let predictionMO = try self.fetchPredictionMO(babyId: baby.id, type: type, context: self.backgroundContext) else {
                return nil
            }
            return predictionMO.toPrediction()
        }
    }

    func generatePrediction(for baby: Baby, type: PredictionType) async throws -> Prediction {
        // Simple prediction logic - in a real app, this would use ML models
        let now = Date()
        var predictedTime: Date
        var confidence: Double
        var explanation: String

        switch type {
        case .nextFeed:
            // Predict next feed based on typical intervals
            predictedTime = now.addingTimeInterval(3 * 60 * 60) // 3 hours from now
            confidence = 0.7
            explanation = "Based on typical feeding patterns"
        case .nextNap:
            // Predict next nap based on time of day
            let hour = Calendar.current.component(.hour, from: now)
            if hour < 12 {
                predictedTime = now.addingTimeInterval(2 * 60 * 60) // Morning nap
            } else {
                predictedTime = now.addingTimeInterval(4 * 60 * 60) // Afternoon nap
            }
            confidence = 0.75
            explanation = "Based on time of day and typical nap windows"
        }

        let prediction = Prediction(
            babyId: baby.id,
            type: type,
            predictedTime: predictedTime,
            confidence: confidence,
            explanation: explanation
        )

        // Save to Core Data
        try await backgroundContext.perform {
            let predictionMO = PredictionMO(context: self.backgroundContext)
            predictionMO.configure(with: prediction)
        }
        try await saveContext(backgroundContext)

        return prediction
    }

    // MARK: - Settings

    func fetchAppSettings() async throws -> AppSettings {
        try await backgroundContext.perform {
            let request = AppSettingsMO.fetchRequest()
            request.fetchLimit = 1

            if let settingsMO = try self.backgroundContext.fetch(request).first {
                return settingsMO.toAppSettings()
            } else {
                // Create default settings
                let defaultSettings = AppSettings.default()
                let settingsMO = AppSettingsMO(context: self.backgroundContext)
                settingsMO.configure(with: defaultSettings)
                try self.backgroundContext.save()
                return defaultSettings
            }
        }
    }

    func saveAppSettings(_ settings: AppSettings) async throws {
        try await backgroundContext.perform {
            let request = AppSettingsMO.fetchRequest()
            request.fetchLimit = 1

            let settingsMO: AppSettingsMO
            if let existing = try self.backgroundContext.fetch(request).first {
                settingsMO = existing
            } else {
                settingsMO = AppSettingsMO(context: self.backgroundContext)
            }

            settingsMO.configure(with: settings)
        }
        try await saveContext(backgroundContext)
    }

    // MARK: - Active Sleep Tracking

    func getActiveSleep(for baby: Baby) async throws -> Event? {
        try await backgroundContext.perform {
            let request = EventMO.fetchRequest()
            request.predicate = NSPredicate(
                format: "babyId == %@ AND type == %@ AND endTime == nil",
                baby.id as CVarArg, EventType.sleep.rawValue
            )
            request.fetchLimit = 1

            guard let eventMO = try self.backgroundContext.fetch(request).first else {
                return nil
            }
            return eventMO.toEvent()
        }
    }

    func startActiveSleep(for baby: Baby) async throws -> Event {
        let activeSleep = Event(
            babyId: baby.id,
            type: .sleep,
            subtype: "nap",
            startTime: Date(),
            endTime: nil
        )

        try await addEvent(activeSleep)
        return activeSleep
    }

    func stopActiveSleep(for baby: Baby) async throws -> Event {
        guard let activeSleep = try await getActiveSleep(for: baby) else {
            throw NSError(domain: "CoreDataStore", code: 404, userInfo: [NSLocalizedDescriptionKey: "No active sleep found"])
        }

        let completedSleep = Event(
            id: activeSleep.id,
            babyId: activeSleep.babyId,
            type: activeSleep.type,
            subtype: activeSleep.subtype,
            startTime: activeSleep.startTime,
            endTime: Date(),
            amount: activeSleep.amount,
            unit: activeSleep.unit,
            side: activeSleep.side,
            note: activeSleep.note,
            createdAt: activeSleep.createdAt,
            updatedAt: Date()
        )

        try await updateEvent(completedSleep)
        return completedSleep
    }

    // MARK: - Last Used Values

    func getLastUsedValues(for eventType: EventType) async throws -> LastUsedValues? {
        try await backgroundContext.perform {
            let request = LastUsedValuesMO.fetchRequest()
            request.predicate = NSPredicate(format: "eventType == %@", eventType.rawValue)
            request.fetchLimit = 1

            guard let valuesMO = try self.backgroundContext.fetch(request).first else {
                return nil
            }
            return valuesMO.toLastUsedValues()
        }
    }

    func saveLastUsedValues(for eventType: EventType, values: LastUsedValues) async throws {
        try await backgroundContext.perform {
            let request = LastUsedValuesMO.fetchRequest()
            request.predicate = NSPredicate(format: "eventType == %@", eventType.rawValue)
            request.fetchLimit = 1

            let valuesMO: LastUsedValuesMO
            if let existing = try self.backgroundContext.fetch(request).first {
                valuesMO = existing
            } else {
                valuesMO = LastUsedValuesMO(context: self.backgroundContext)
            }

            valuesMO.configure(with: values, for: eventType)
        }
        try await saveContext(backgroundContext)
    }
}
