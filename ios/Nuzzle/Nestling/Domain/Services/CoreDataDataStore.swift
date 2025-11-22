import Foundation
import CoreData

/// Core Data implementation of DataStore protocol.
/// Provides persistent storage with migration support.
class CoreDataDataStore: DataStore {
    private let stack: CoreDataStack
    private let queue = DispatchQueue(label: "com.nestling.coredata", attributes: .concurrent)
    
    init(stack: CoreDataStack = .shared) {
        self.stack = stack
        // Ensure CoreData stack is initialized
        _ = stack.persistentContainer
    }
    
    /// Ensure CoreData store is ready before performing operations
    private func ensureStoreReady() async throws {
        if !stack.isStoreReady {
            print("WARNING: CoreData store not ready yet, waiting...")
            // Wait up to 2 seconds for store to be ready
            for _ in 0..<20 {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                if stack.isStoreReady {
                    print("CoreData store is now ready")
                    return
                }
            }
            throw NSError(domain: "CoreDataDataStore", code: -1, userInfo: [NSLocalizedDescriptionKey: "CoreData store not ready after waiting"])
        }
    }
    
    // MARK: - Babies
    
    func fetchBabies() async throws -> [Baby] {
        return try await withCheckedThrowingContinuation { continuation in
            let context = self.stack.newBackgroundContext()
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
        return try await withCheckedThrowingContinuation { continuation in
            let context = self.stack.newBackgroundContext()
            context.perform {
                let entity = BabyEntity(context: context)
                entity.update(from: baby)
                
                do {
                    try self.stack.save(context: context)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func updateBaby(_ baby: Baby) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let context = self.stack.newBackgroundContext()
            context.perform {
                let request = NSFetchRequest<BabyEntity>(entityName: "BabyEntity")
                request.predicate = NSPredicate(format: "id == %@", baby.id as CVarArg)
                
                do {
                    if let entity = try context.fetch(request).first {
                        entity.update(from: baby)
                        try self.stack.save(context: context)
                    }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func deleteBaby(_ baby: Baby) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let context = self.stack.newBackgroundContext()
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
                        
                        try self.stack.save(context: context)
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
        print("CoreDataDataStore.fetchEvents called for baby: \(baby.id), date: \(date)")
        let startTime = Date()
        
        // Ensure store is ready before using contexts
        try await ensureStoreReady()
        
        return try await withCheckedThrowingContinuation { continuation in
            let context = self.stack.newBackgroundContext()
            print("Created background context, calling perform...")
            
            // Add timeout wrapper
            var hasResumed = false
            let lock = NSLock()
            
            // Timeout task
            let timeoutTask = DispatchWorkItem {
                lock.lock()
                if !hasResumed {
                    hasResumed = true
                    lock.unlock()
                    print("ERROR: fetchEvents timed out - context.perform never executed")
                    continuation.resume(throwing: NSError(domain: "CoreDataDataStore", code: -2, userInfo: [NSLocalizedDescriptionKey: "Fetch timed out - CoreData store may not be ready"]))
                } else {
                    lock.unlock()
                }
            }
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 5.0, execute: timeoutTask)
            
            context.perform {
                lock.lock()
                if hasResumed {
                    lock.unlock()
                    print("WARNING: fetchEvents continuation already resumed (timeout or cancelled)")
                    return
                }
                hasResumed = true
                lock.unlock()
                timeoutTask.cancel()
                
                print("Inside context.perform block")
                do {
                    let calendar = Calendar.current
                    let startOfDay = calendar.startOfDay(for: date)
                    let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
                    
                    print("Date range: \(startOfDay) to \(endOfDay)")
                    
                    let request = NSFetchRequest<EventEntity>(entityName: "EventEntity")
                    request.predicate = NSPredicate(format: "babyId == %@ AND startTime >= %@ AND startTime < %@", 
                                                   baby.id as CVarArg, startOfDay as NSDate, endOfDay as NSDate)
                    request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
                    
                    // Add fetch limit to prevent hanging on large datasets
                    request.fetchLimit = 1000
                    
                    print("Executing fetch request...")
                    let entities = try context.fetch(request)
                    print("Fetch completed, got \(entities.count) entities")
                    
                    let events = entities.compactMap { entity -> Event? in
                        // Use compactMap to filter out any invalid entities
                        do {
                            return entity.toEvent()
                        } catch {
                            print("Warning: Failed to convert EventEntity to Event: \(error)")
                            return nil
                        }
                    }
                    
                    let elapsed = Date().timeIntervalSince(startTime)
                    print("fetchEvents completed successfully in \(elapsed) seconds, returning \(events.count) events")
                    if events.count > 0 {
                        print("Sample event: type=\(events.first!.type), startTime=\(events.first!.startTime), babyId=\(events.first!.babyId)")
                    }
                    continuation.resume(returning: events)
                } catch {
                    let elapsed = Date().timeIntervalSince(startTime)
                    print("ERROR: fetchEvents failed after \(elapsed) seconds: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func fetchEvents(for baby: Baby, from startDate: Date, to endDate: Date) async throws -> [Event] {
        return try await withCheckedThrowingContinuation { continuation in
            let context = self.stack.newBackgroundContext()
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
        print("CoreDataDataStore.addEvent called: type=\(event.type), babyId=\(event.babyId), startTime=\(event.startTime)")
        // Domain-level validation
        try EventValidator.validate(event)
        
        // Ensure store is ready before using contexts
        try await ensureStoreReady()
        
        return try await withCheckedThrowingContinuation { continuation in
            let context = self.stack.newBackgroundContext()
            
            // Add timeout wrapper
            var hasResumed = false
            let lock = NSLock()
            let timeoutTask = DispatchWorkItem {
                lock.lock()
                if !hasResumed {
                    hasResumed = true
                    lock.unlock()
                    print("ERROR: addEvent timed out - context.perform never executed")
                    continuation.resume(throwing: NSError(domain: "CoreDataDataStore", code: -2, userInfo: [NSLocalizedDescriptionKey: "Save timed out - CoreData store may not be ready"]))
                } else {
                    lock.unlock()
                }
            }
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 5.0, execute: timeoutTask)
            
            context.perform {
                lock.lock()
                if hasResumed {
                    lock.unlock()
                    print("WARNING: addEvent continuation already resumed (timeout or cancelled)")
                    return
                }
                hasResumed = true
                lock.unlock()
                timeoutTask.cancel()
                
                let entity = EventEntity(context: context)
                entity.update(from: event)
                
                do {
                    try self.stack.save(context: context)
                    print("CoreDataDataStore.addEvent: Event saved successfully with id=\(event.id)")
                    continuation.resume()
                } catch {
                    print("CoreDataDataStore.addEvent ERROR: Failed to save event: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func updateEvent(_ event: Event) async throws {
        // Domain-level validation
        try EventValidator.validate(event)
        
        return try await withCheckedThrowingContinuation { continuation in
            let context = self.stack.newBackgroundContext()
            context.perform {
                let request = NSFetchRequest<EventEntity>(entityName: "EventEntity")
                request.predicate = NSPredicate(format: "id == %@", event.id as CVarArg)
                
                do {
                    if let entity = try context.fetch(request).first {
                        entity.update(from: event)
                        try self.stack.save(context: context)
                    }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func deleteEvent(_ event: Event) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let context = self.stack.newBackgroundContext()
            context.perform {
                let request = NSFetchRequest<EventEntity>(entityName: "EventEntity")
                request.predicate = NSPredicate(format: "id == %@", event.id as CVarArg)
                
                do {
                    if let entity = try context.fetch(request).first {
                        context.delete(entity)
                        try self.stack.save(context: context)
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
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Prediction?, Error>) in
            let context = self.stack.newBackgroundContext()
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
        return try await withCheckedThrowingContinuation { continuation in
            let context = self.stack.newBackgroundContext()
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
                    try self.stack.save(context: context)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Settings
    
    func fetchAppSettings() async throws -> AppSettings {
        return try await withCheckedThrowingContinuation { continuation in
            let context = self.stack.newBackgroundContext()
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
                        try? self.stack.save(context: context)
                        continuation.resume(returning: defaults)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func saveAppSettings(_ settings: AppSettings) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let context = self.stack.newBackgroundContext()
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
                    try self.stack.save(context: context)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Active Sleep
    
    func getActiveSleep(for baby: Baby) async throws -> Event? {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Event?, Error>) in
            let context = self.stack.newBackgroundContext()
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
        return try await withCheckedThrowingContinuation { continuation in
            let context = self.stack.newBackgroundContext()
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
                    try self.stack.save(context: context)
                    continuation.resume(returning: sleepEvent)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func stopActiveSleep(for baby: Baby) async throws -> Event {
        return try await withCheckedThrowingContinuation { continuation in
            let context = self.stack.newBackgroundContext()
            context.perform {
                let request = NSFetchRequest<EventEntity>(entityName: "EventEntity")
                request.predicate = NSPredicate(format: "babyId == %@ AND type == %@ AND endTime == nil",
                                               baby.id as CVarArg, EventType.sleep.rawValue)
                request.fetchLimit = 1
                
                do {
                    if let entity = try context.fetch(request).first {
                        entity.endTime = Date()
                        let event = entity.toEvent()
                        try self.stack.save(context: context)
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
                        try self.stack.save(context: context)
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
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<LastUsedValues?, Error>) in
            let context = self.stack.newBackgroundContext()
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
        return try await withCheckedThrowingContinuation { continuation in
            let context = self.stack.newBackgroundContext()
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
                    try self.stack.save(context: context)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Delete All Data
    
    /// Delete all data from Core Data (for privacy/data deletion feature)
    func deleteAllData() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let context = self.stack.newBackgroundContext()
            context.perform {
                do {
                    // Delete all events
                    let eventRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "EventEntity")
                    let deleteEvents = NSBatchDeleteRequest(fetchRequest: eventRequest)
                    try context.execute(deleteEvents)
                    
                    // Delete all babies
                    let babyRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "BabyEntity")
                    let deleteBabies = NSBatchDeleteRequest(fetchRequest: babyRequest)
                    try context.execute(deleteBabies)
                    
                    // Delete all predictions
                    let predictionRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "PredictionCacheEntity")
                    let deletePredictions = NSBatchDeleteRequest(fetchRequest: predictionRequest)
                    try context.execute(deletePredictions)
                    
                    // Delete all last used values
                    let lastUsedRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "LastUsedValuesEntity")
                    let deleteLastUsed = NSBatchDeleteRequest(fetchRequest: lastUsedRequest)
                    try context.execute(deleteLastUsed)
                    
                    // Note: We keep AppSettingsEntity so the app doesn't crash on next launch
                    // The onboarding flow will check if babies exist and reset if needed
                    
                    try self.stack.save(context: context)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

