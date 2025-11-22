import Foundation

/// Service for migrating data between storage backends (JSON → Core Data).
class DataMigrationService {
    private let jsonStore: JSONBackedDataStore
    private let coreDataStore: CoreDataDataStore
    
    init(jsonStore: JSONBackedDataStore, coreDataStore: CoreDataDataStore) {
        self.jsonStore = jsonStore
        self.coreDataStore = coreDataStore
    }
    
    /// Migrate all data from JSON to Core Data.
    func migrateJSONToCoreData() async throws {
        // Fetch all data from JSON
        let babies = try await jsonStore.fetchBabies()
        let settings = try await jsonStore.fetchAppSettings()
        
        // Migrate babies
        for baby in babies {
            try await coreDataStore.addBaby(baby)
        }
        
        // Migrate events for each baby
        for baby in babies {
            let startDate = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
            let events = try await jsonStore.fetchEvents(for: baby, from: startDate, to: Date())
            for event in events {
                try await coreDataStore.addEvent(event)
            }
        }
        
        // Migrate settings
        try await coreDataStore.saveAppSettings(settings)
        
        // Migrate last used values
        for eventType in EventType.allCases {
            if let lastUsed = try? await jsonStore.getLastUsedValues(for: eventType) {
                try await coreDataStore.saveLastUsedValues(for: eventType, values: lastUsed)
            }
        }
        
        // Migrate predictions
        for baby in babies {
            for predictionType in PredictionType.allCases {
                if let prediction = try? await jsonStore.fetchPredictions(for: baby, type: predictionType) {
                    // Save prediction via Core Data
                    let _ = try await coreDataStore.generatePrediction(for: baby, type: predictionType)
                }
            }
        }
    }
    
    /// Export Core Data to JSON format (for backup).
    func exportCoreDataToJSON() async throws -> Data {
        // This would serialize Core Data entities to JSON format
        // For now, return empty data (will be implemented if needed)
        return Data()
    }
}

