import Foundation
import CoreData

/// Core Data implementation of DataStore protocol.
/// Provides persistent storage with migration support.
class CoreDataDataStore: DataStore {
    private let stack: CoreDataStack
    private let queue = DispatchQueue(label: "com.nestling.coredata", attributes: .concurrent)
    
    init(stack: CoreDataStack = .shared) {
        self.stack = stack
    }
    
    // MARK: - Babies
    
    func fetchBabies() async throws -> [Baby] {
        return await withCheckedContinuation { continuation in
            let context = stack.newBackgroundContext()
            context.perform {
                let request = NSFetchRequest<BabyEntity>(entityName: "BabyEntity")
                do {
                    let entities = try context.fetch(request)
                    let babies = entities.map { $0.toBaby() }
                    continuation.resume(returning: babies)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func addBaby(_ baby: Baby) async throws {
        return await withCheckedContinuation { continuation in
            let context = stack.newBackgroundContext()
            context.perform {
                let entity = BabyEntity(context: context)
                entity.update(from: baby)
                
                do {
                    try stack.save(context: context)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func updateBaby(_ baby: Baby) async throws {
        return await withCheckedContinuation { continuation in
            let context = stack.newBackgroundContext()
            context.perform {
                let request = NSFetchRequest<BabyEntity>(entityName: "BabyEntity")
                request.predicate = NSPredicate(format: "id == %@", baby.id as CVarArg)
                
                do {
                    if let entity = try context.fetch(request).first {
                        entity.update(from: baby)
                        try stack.save(context: context)
                    }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func deleteBaby(_ baby: Baby) async throws {
        return await withCheckedContinuation { continuation in
            let context = stack.newBackgroundContext()
            context.perform {
                let request = NSFetchRequest<BabyEntity>(entityName: "BabyEntity")
                request.predicate = NSPredicate(format: "id == %@", baby.id as CVarArg)
                
                do {
                    if let entity = try context.fetch(request).first {
                        context.delete(entity)
                        // Also delete associated events
                        let eventRequest = NSFetchRequest<EventEntity>(entityName: "EventEntity")
                        eventRequest.predicate = NSPredicate(format: "babyId == %@", baby.id as CVarArg)
                        let events = try context.fetch(eventRequest)
                        events.forEach { context.delete($0) }
                        
                        try stack.save(context: context)
                    }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Events
    
    func fetchEvents(for baby: Baby, on date: Date) async throws -> [Event] {
        return await withCheckedContinuation { continuation in
            let context = stack.newBackgroundContext()
            context.perform {
                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: date)
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
                
                let request = NSFetchRequest<EventEntity>(entityName: "EventEntity")
                request.predicate = NSPredicate(format: "babyId == %@ AND startTime >= %@ AND startTime < %@", 
                                               baby.id as CVarArg, startOfDay as NSDate, endOfDay as NSDate)
                request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
                
                do {
                    let entities = try context.fetch(request)
                    let events = entities.map { $0.toEvent() }
                    continuation.resume(returning: events)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func fetchEvents(for baby: Baby, from startDate: Date, to endDate: Date) async throws -> [Event] {
        return await withCheckedContinuation { continuation in
            let context = stack.newBackgroundContext()
            context.perform {
                let request = NSFetchRequest<EventEntity>(entityName: "EventEntity")
                request.predicate = NSPredicate(format: "babyId == %@ AND startTime >= %@ AND startTime <= %@",
                                               baby.id as CVarArg, startDate as NSDate, endDate as NSDate)
                request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
                
                do {
                    let entities = try context.fetch(request)
                    let events = entities.map { $0.toEvent() }
                    continuation.resume(returning: events)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func addEvent(_ event: Event) async throws {
        // Domain-level validation
        try EventValidator.validate(event)
        
        return await withCheckedContinuation { continuation in
            let context = stack.newBackgroundContext()
            context.perform {
                let entity = EventEntity(context: context)
                entity.update(from: event)
                
                do {
                    try stack.save(context: context)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func updateEvent(_ event: Event) async throws {
        // Domain-level validation
        try EventValidator.validate(event)
        
        return await withCheckedContinuation { continuation in
            let context = stack.newBackgroundContext()
            context.perform {
                let request = NSFetchRequest<EventEntity>(entityName: "EventEntity")
                request.predicate = NSPredicate(format: "id == %@", event.id as CVarArg)
                
                do {
                    if let entity = try context.fetch(request).first {
                        entity.update(from: event)
                        try stack.save(context: context)
                    }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func deleteEvent(_ event: Event) async throws {
        return await withCheckedContinuation { continuation in
            let context = stack.newBackgroundContext()
            context.perform {
                let request = NSFetchRequest<EventEntity>(entityName: "EventEntity")
                request.predicate = NSPredicate(format: "id == %@", event.id as CVarArg)
                
                do {
                    if let entity = try context.fetch(request).first {
                        context.delete(entity)
                        try stack.save(context: context)
                    }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Predictions
    
    func fetchPredictions(for baby: Baby, type: PredictionType) async throws -> Prediction? {
        return await withCheckedContinuation { continuation in
            let context = stack.newBackgroundContext()
            context.perform {
                let request = NSFetchRequest<PredictionCacheEntity>(entityName: "PredictionCacheEntity")
                request.predicate = NSPredicate(format: "babyId == %@ AND type == %@",
                                               baby.id as CVarArg, type.rawValue)
                request.fetchLimit = 1
                
                do {
                    if let entity = try context.fetch(request).first {
                        continuation.resume(returning: entity.toPrediction())
                    } else {
                        continuation.resume(returning: nil)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func generatePrediction(for baby: Baby, type: PredictionType) async throws -> Prediction {
        // Use PredictionsEngine for on-device predictions
        let engine = PredictionsEngine(dataStore: self)
        
        let prediction: Prediction
        switch type {
        case .nextNap:
            prediction = try await engine.predictNextNap(for: baby)
        case .nextFeed:
            prediction = try await engine.predictNextFeed(for: baby)
        }
        
        try await savePrediction(prediction)
        return prediction
    }
    
    private func savePrediction(_ prediction: Prediction) async throws {
        return await withCheckedContinuation { continuation in
            let context = stack.newBackgroundContext()
            context.perform {
                let request = NSFetchRequest<PredictionCacheEntity>(entityName: "PredictionCacheEntity")
                request.predicate = NSPredicate(format: "babyId == %@ AND type == %@",
                                               prediction.babyId as CVarArg, prediction.type.rawValue)
                
                do {
                    if let entity = try context.fetch(request).first {
                        entity.update(from: prediction)
                    } else {
                        let entity = PredictionCacheEntity(context: context)
                        entity.update(from: prediction)
                    }
                    try stack.save(context: context)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Settings
    
    func fetchAppSettings() async throws -> AppSettings {
        return await withCheckedContinuation { continuation in
            let context = stack.newBackgroundContext()
            context.perform {
                let request = NSFetchRequest<AppSettingsEntity>(entityName: "AppSettingsEntity")
                request.fetchLimit = 1
                
                do {
                    if let entity = try context.fetch(request).first {
                        continuation.resume(returning: entity.toAppSettings())
                    } else {
                        // Return defaults and create entity
                        let defaults = AppSettings.default()
                        let entity = AppSettingsEntity(context: context)
                        entity.update(from: defaults)
                        try? stack.save(context: context)
                        continuation.resume(returning: defaults)
                    }
                } catch {
                    continuation.resume(returning: AppSettings.default())
                }
            }
        }
    }
    
    func saveAppSettings(_ settings: AppSettings) async throws {
        return await withCheckedContinuation { continuation in
            let context = stack.newBackgroundContext()
            context.perform {
                let request = NSFetchRequest<AppSettingsEntity>(entityName: "AppSettingsEntity")
                request.fetchLimit = 1
                
                do {
                    if let entity = try context.fetch(request).first {
                        entity.update(from: settings)
                    } else {
                        let entity = AppSettingsEntity(context: context)
                        entity.update(from: settings)
                    }
                    try stack.save(context: context)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Active Sleep
    
    func getActiveSleep(for baby: Baby) async throws -> Event? {
        return await withCheckedContinuation { continuation in
            let context = stack.newBackgroundContext()
            context.perform {
                let request = NSFetchRequest<EventEntity>(entityName: "EventEntity")
                request.predicate = NSPredicate(format: "babyId == %@ AND type == %@ AND endTime == nil",
                                               baby.id as CVarArg, EventType.sleep.rawValue)
                request.fetchLimit = 1
                
                do {
                    if let entity = try context.fetch(request).first {
                        continuation.resume(returning: entity.toEvent())
                    } else {
                        continuation.resume(returning: nil)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func startActiveSleep(for baby: Baby) async throws -> Event {
        return await withCheckedContinuation { continuation in
            let context = stack.newBackgroundContext()
            context.perform {
                let entity = EventEntity(context: context)
                let sleepEvent = Event(
                    babyId: baby.id,
                    type: .sleep,
                    subtype: "nap",
                    startTime: Date(),
                    endTime: nil
                )
                entity.update(from: sleepEvent)
                
                do {
                    try stack.save(context: context)
                    continuation.resume(returning: sleepEvent)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func stopActiveSleep(for baby: Baby) async throws -> Event {
        return await withCheckedContinuation { continuation in
            let context = stack.newBackgroundContext()
            context.perform {
                let request = NSFetchRequest<EventEntity>(entityName: "EventEntity")
                request.predicate = NSPredicate(format: "babyId == %@ AND type == %@ AND endTime == nil",
                                               baby.id as CVarArg, EventType.sleep.rawValue)
                request.fetchLimit = 1
                
                do {
                    if let entity = try context.fetch(request).first {
                        entity.endTime = Date()
                        let event = entity.toEvent()
                        try stack.save(context: context)
                        continuation.resume(returning: event)
                    } else {
                        // Create default sleep event
                        let now = Date()
                        let startTime = now.addingTimeInterval(-600)
                        let sleepEvent = Event(
                            babyId: baby.id,
                            type: .sleep,
                            subtype: "nap",
                            startTime: startTime,
                            endTime: now,
                            note: "Quick log nap (10 min)"
                        )
                        let newEntity = EventEntity(context: context)
                        newEntity.update(from: sleepEvent)
                        try stack.save(context: context)
                        continuation.resume(returning: sleepEvent)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Last Used Values
    
    func getLastUsedValues(for eventType: EventType) async throws -> LastUsedValues? {
        return await withCheckedContinuation { continuation in
            let context = stack.newBackgroundContext()
            context.perform {
                let request = NSFetchRequest<LastUsedValuesEntity>(entityName: "LastUsedValuesEntity")
                request.predicate = NSPredicate(format: "eventType == %@", eventType.rawValue)
                request.fetchLimit = 1
                
                do {
                    if let entity = try context.fetch(request).first {
                        continuation.resume(returning: entity.toLastUsedValues())
                    } else {
                        continuation.resume(returning: nil)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func saveLastUsedValues(for eventType: EventType, values: LastUsedValues) async throws {
        return await withCheckedContinuation { continuation in
            let context = stack.newBackgroundContext()
            context.perform {
                let request = NSFetchRequest<LastUsedValuesEntity>(entityName: "LastUsedValuesEntity")
                request.predicate = NSPredicate(format: "eventType == %@", eventType.rawValue)
                
                do {
                    if let entity = try context.fetch(request).first {
                        entity.update(from: values)
                    } else {
                        let entity = LastUsedValuesEntity(context: context)
                        entity.eventType = eventType.rawValue
                        entity.update(from: values)
                    }
                    try stack.save(context: context)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Data Persistence
    
    func forceSyncIfNeeded() async throws {
        // Core Data automatically saves on context save
        // This method ensures all pending changes are persisted
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let context = stack.newBackgroundContext()
            context.perform {
                do {
                    try stack.save(context: context)
                    // Also save main context
                    try stack.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

