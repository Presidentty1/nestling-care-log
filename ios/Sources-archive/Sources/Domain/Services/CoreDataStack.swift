import CoreData
import Foundation

class CoreDataStack {
    static let shared = CoreDataStack()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Nestling")
        
        // Configure for App Groups (shared with widgets)
        let storeURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.nestling.app")?
            .appendingPathComponent("Nestling.sqlite")
        
        // Use fallback URL if App Group or default description is unavailable
        let fallbackURL: URL
        if let defaultURL = container.persistentStoreDescriptions.first?.url {
            fallbackURL = defaultURL
        } else {
            // Last resort: use Documents directory
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            fallbackURL = documentsURL.appendingPathComponent("Nestling.sqlite")
        }
        
        let description = NSPersistentStoreDescription(url: storeURL ?? fallbackURL)
        description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { description, error in
            if let error = error {
                // Log error and report to crash reporter instead of crashing
                Logger.error("Core Data store failed to load: \(error.localizedDescription)")
                CrashReporter.shared.reportError(error, context: [
                    "storeDescription": description.url?.absoluteString ?? "unknown",
                    "storeType": description.type
                ])
                
                // Attempt to use fallback location or in-memory store
                // The app will fall back to JSONBackedDataStore via DataStoreSelector
                // This prevents the app from crashing on Core Data initialization failure
            }
        }
        
        // Optimize for UI
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
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


