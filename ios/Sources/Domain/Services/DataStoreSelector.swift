import Foundation

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
        if SupabaseClient.shared.isConfigured {
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
        if FileManager.default.fileExists(atPath: CoreDataStack.shared.persistentContainer.persistentStoreDescriptions.first?.url?.path ?? "") {
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
        if let url = supabaseURL, let key = anonKey {
            SupabaseClient.shared.configure(url: url, anonKey: key)
            if SupabaseClient.shared.isConfigured {
                return RemoteDataStore(supabaseURL: url, anonKey: key)
            }
        }
        
        // Fallback to default
        return create()
    }
}

