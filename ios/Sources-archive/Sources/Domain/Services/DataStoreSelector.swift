import Foundation

enum DataStoreType {
    case inMemory
    case json
    case coreData
    case swiftData
}

/// Factory for selecting DataStore implementation.
/// Can be configured via environment variable or build setting.
class DataStoreSelector {
    static func create() -> DataStore {
        #if USE_REMOTE_STORE
        // Use RemoteDataStore if Supabase is configured
        if SupabaseClient.shared.isConfigured {
            // FUTURE: Get URL and key from config when Supabase is integrated
            // return RemoteDataStore(supabaseURL: url, anonKey: key)
        }
        #endif

        #if USE_SWIFT_DATA
        do {
            return try SwiftDataStore()
        } catch {
            Logger.dataError("Failed to create SwiftDataStore, falling back: \(error.localizedDescription)")
        }
        #elseif USE_CORE_DATA
        return CoreDataStore()
        #elseif USE_JSON_STORE
        return JSONBackedDataStore()
        #else
        // Default: JSON-backed store for offline-first behavior on fresh install
        // Can be migrated to SwiftData/CoreData later if needed
        return JSONBackedDataStore()
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

