import CoreData
import Foundation

class CoreDataStack {
    static let shared = CoreDataStack()
    
    private var storeLoadSemaphore: DispatchSemaphore?
    private var storeLoadError: Error?
    private var storeLoadComplete = false
    
    lazy var persistentContainer: NSPersistentContainer = {
        print("Initializing CoreData persistentContainer...")
        let container = NSPersistentContainer(name: "Nestling")
        
        // Configure for App Groups (shared with widgets)
        let storeURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.nestling.app")?
            .appendingPathComponent("Nestling.sqlite")
        
        let defaultURL = container.persistentStoreDescriptions.first?.url ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Nestling.sqlite")
        let description = NSPersistentStoreDescription(url: storeURL ?? defaultURL)
        description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        
        container.persistentStoreDescriptions = [description]
        
        // Use semaphore to wait for store to load (with timeout)
        let semaphore = DispatchSemaphore(value: 0)
        storeLoadSemaphore = semaphore
        
        container.loadPersistentStores { description, error in
            if let error = error {
                print("ERROR: Core Data store failed to load: \(error.localizedDescription)")
                self.storeLoadError = error
            } else {
                print("Core Data store loaded successfully at: \(description.url?.path ?? "unknown")")
            }
            self.storeLoadComplete = true
            semaphore.signal()
        }
        
        // Wait for store to load (max 5 seconds)
        let timeout = semaphore.wait(timeout: .now() + 5.0)
        if timeout == .timedOut {
            print("WARNING: Core Data store loading timed out after 5 seconds - contexts may not work properly")
        }
        
        if let error = storeLoadError {
            print("ERROR: Core Data initialization failed: \(error.localizedDescription)")
        }
        
        // Optimize for UI
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        print("CoreData container initialized and ready: storeLoadComplete=\(storeLoadComplete)")
        storeLoadSemaphore = nil
        return container
    }()
    
    /// Check if persistent stores are loaded and ready
    var isStoreReady: Bool {
        return storeLoadComplete && !persistentContainer.persistentStoreCoordinator.persistentStores.isEmpty
    }
    
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    func newBackgroundContext() -> NSManagedObjectContext {
        persistentContainer.newBackgroundContext()
    }
    
    func save() throws {
        let context = viewContext
        if context.hasChanges {
            try context.save()
        }
    }
    
    func save(context: NSManagedObjectContext) throws {
        if context.hasChanges {
            try context.save()
        }
    }
    
    // MARK: - Migration Support
    
    func checkAndPerformMigrationIfNeeded() throws {
        let storeURL = persistentContainer.persistentStoreDescriptions.first?.url
        guard let storeURL = storeURL else { return }
        
        let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: storeURL)
        let currentModel = persistentContainer.managedObjectModel
        
        // Check if migration is needed
        if !currentModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) {
            // Migration will be handled automatically via lightweight migration
            // For complex migrations, add custom migration logic here
        }
    }
}

