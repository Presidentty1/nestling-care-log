import Foundation
import SwiftData

/// Service for migrating data from JSON-backed store to SwiftData/CloudKit store
@MainActor
class CloudMigrationService {
    private let jsonStore: JSONBackedDataStore
    private let swiftDataStore: SwiftDataStore

    init(jsonStore: JSONBackedDataStore, swiftDataStore: SwiftDataStore) {
        self.jsonStore = jsonStore
        self.swiftDataStore = swiftDataStore
    }

    /// Check if migration is needed (has local data but SwiftData is empty)
    func needsMigration() async -> Bool {
        do {
            let jsonBabies = try await jsonStore.fetchBabies()
            guard !jsonBabies.isEmpty else { return false }

            let swiftBabies = try await swiftDataStore.fetchBabies()
            return swiftBabies.isEmpty
        } catch {
            Logger.dataError("Failed to check migration status: \(error.localizedDescription)")
            return false
        }
    }

    /// Perform migration from JSON to SwiftData
    func migrateData(progressHandler: @escaping (String, Double) -> Void) async throws {
        progressHandler("Starting migration...", 0.0)

        // Migrate babies
        let babies = try await jsonStore.fetchBabies()
        for (index, baby) in babies.enumerated() {
            try await swiftDataStore.addBaby(baby)
            let progress = Double(index + 1) / Double(babies.count) * 0.5
            progressHandler("Migrating babies... (\(index + 1)/\(babies.count))", progress)
        }

        // Migrate events for each baby
        for (babyIndex, baby) in babies.enumerated() {
            let events = try await jsonStore.fetchEvents(for: baby, from: Date.distantPast, to: Date.distantFuture)
            for (eventIndex, event) in events.enumerated() {
                try await swiftDataStore.addEvent(event)
                let babyProgress = Double(babyIndex) / Double(babies.count)
                let eventProgress = Double(eventIndex) / Double(events.count) * (1.0 / Double(babies.count))
                let totalProgress = 0.5 + babyProgress + eventProgress
                progressHandler("Migrating events for \(baby.name)... (\(eventIndex + 1)/\(events.count))", totalProgress)
            }
        }

        // Migrate settings
        let settings = try await jsonStore.fetchAppSettings()
        try await swiftDataStore.saveAppSettings(settings)

        progressHandler("Migration complete!", 1.0)
    }

    /// Get summary of data that will be migrated
    func getMigrationSummary() async -> MigrationSummary {
        do {
            let babies = try await jsonStore.fetchBabies()
            var totalEvents = 0

            for baby in babies {
                let events = try await jsonStore.fetchEvents(for: baby, from: Date.distantPast, to: Date.distantFuture)
                totalEvents += events.count
            }

            return MigrationSummary(
                babyCount: babies.count,
                eventCount: totalEvents,
                estimatedSize: estimateDataSize(babies: babies, events: totalEvents)
            )
        } catch {
            Logger.dataError("Failed to get migration summary: \(error.localizedDescription)")
            return MigrationSummary(babyCount: 0, eventCount: 0, estimatedSize: "Unknown")
        }
    }

    private func estimateDataSize(babies: [Baby], events: Int) -> String {
        // Rough estimate: 1KB per baby, 2KB per event
        let estimatedBytes = (babies.count * 1024) + (events * 2048)
        let kb = estimatedBytes / 1024

        if kb < 1024 {
            return "\(kb) KB"
        } else {
            let mb = Double(kb) / 1024.0
            return String(format: "%.1f MB", mb)
        }
    }
}

struct MigrationSummary {
    let babyCount: Int
    let eventCount: Int
    let estimatedSize: String

    var description: String {
        "\(babyCount) babies, \(eventCount) events (\(estimatedSize))"
    }
}


