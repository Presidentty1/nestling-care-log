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
        // Check if CoreData store file exists without triggering lazy initialization
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let coreDataURL = documentsPath.appendingPathComponent("Nestling.sqlite")
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
        // RemoteDataStore now uses Secrets.swift automatically
        // If credentials are provided, they should be set in Secrets.swift
        if SupabaseClientProvider.shared.isConfigured {
            return RemoteDataStore()
        }
        
        // Fallback to default
        return create()
    }
}

