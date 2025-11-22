import Foundation
import CoreData

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
        // TODO: Update database filename from Nestling.sqlite to Nuzzle.sqlite when ready
        let coreDataURL = documentsPath.appendingPathComponent("Nestling.sqlite")
        // TODO: Update app group ID from group.com.nestling.app to group.com.nuzzle.app when ready
        let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.nestling.app")?
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

