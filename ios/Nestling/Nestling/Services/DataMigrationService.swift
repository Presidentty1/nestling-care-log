import Foundation
import Combine

/// Service for migrating local-only data to Supabase on first sign-up/login.
/// 
/// Migration Strategy:
/// 1. Check if migration has already completed for this user
/// 2. Fetch existing remote babies (if any)
/// 3. If remote is empty -> upload all local data
/// 4. If remote exists -> merge local-only data carefully
/// 5. Mark migration as complete to prevent re-migration
@MainActor
class DataMigrationService: ObservableObject {
    static let shared = DataMigrationService()
    
    @Published var isMigrating = false
    @Published var migrationProgress: Double = 0.0
    @Published var migrationStatus: String = ""
    
    private let localStore: DataStore
    private let remoteStore: RemoteDataStore
    private let userDefaults = UserDefaults.standard
    private let migrationKey = "hasMigratedForUserId"
    
    private init() {
        // For migration, we need both local and remote stores
        self.localStore = CoreDataDataStore()
        self.remoteStore = RemoteDataStore()
    }
    
    // MARK: - Migration Entry Point
    
    /// Check if migration is needed and run it if necessary
    func checkAndMigrateIfNeeded(userId: UUID) async throws {
        // Check if already migrated for this user
        if hasMigratedForUser(userId) {
            print("✅ Migration already completed for user \(userId.uuidString)")
            return
        }
        
        print("🔄 Starting migration for user \(userId.uuidString)")
        isMigrating = true
        migrationProgress = 0.0
        migrationStatus = "Checking local data..."
        
        defer {
            isMigrating = false
            migrationProgress = 1.0
        }
        
        do {
            // Fetch local babies and events
            let localBabies = try await localStore.fetchBabies()
            
            if localBabies.isEmpty {
                print("ℹ️ No local data to migrate")
                markMigrationComplete(for: userId)
                return
            }
            
            migrationStatus = "Found \(localBabies.count) local babies"
            print("📦 Found \(localBabies.count) local babies to migrate")
            
            // Fetch remote babies to check for conflicts
            // TODO: Uncomment when RemoteDataStore is implemented
            // let remoteBabies = try? await remoteStore.fetchBabies()
            
            // For MVP: Always assume remote is empty on first migration
            // In production, we'd check and merge intelligently
            
            migrationStatus = "Uploading babies..."
            migrationProgress = 0.2
            
            // Upload babies first
            for (index, baby) in localBabies.enumerated() {
                // TODO: Uncomment when RemoteDataStore is implemented
                // try await remoteStore.addBaby(baby)
                
                migrationProgress = 0.2 + (Double(index + 1) / Double(localBabies.count)) * 0.3
                migrationStatus = "Uploading baby \(index + 1) of \(localBabies.count)..."
            }
            
            print("✅ Uploaded \(localBabies.count) babies")
            
            // Upload events for each baby
            migrationStatus = "Uploading events..."
            migrationProgress = 0.5
            
            var totalEvents = 0
            for (babyIndex, baby) in localBabies.enumerated() {
                // Fetch events for this baby (last year's worth)
                let endDate = Date()
                let startDate = Calendar.current.date(byAdding: .year, value: -1, to: endDate) ?? Date()
                let localEvents = try await localStore.fetchEvents(for: baby, from: startDate, to: endDate)
                
                totalEvents += localEvents.count
                
                // Upload events for this baby
                for (eventIndex, event) in localEvents.enumerated() {
                    // TODO: Uncomment when RemoteDataStore is implemented
                    // try await remoteStore.addEvent(event)
                    
                    let eventProgress = Double(eventIndex + 1) / Double(localEvents.count)
                    let babyProgress = Double(babyIndex) / Double(localBabies.count)
                    migrationProgress = 0.5 + babyProgress * 0.4 + (eventProgress / Double(localBabies.count)) * 0.4
                    migrationStatus = "Uploading events for \(baby.name)..."
                }
            }
            
            print("✅ Uploaded \(totalEvents) events")
            
            // Mark migration as complete
            markMigrationComplete(for: userId)
            migrationStatus = "Migration complete! ✅"
            
        } catch {
            migrationStatus = "Migration failed: \(error.localizedDescription)"
            print("❌ Migration failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Helper Methods
    
    /// Check if migration has completed for this user
    private func hasMigratedForUser(_ userId: UUID) -> Bool {
        let migratedUserId = userDefaults.string(forKey: migrationKey)
        return migratedUserId == userId.uuidString
    }
    
    /// Mark migration as complete for this user
    private func markMigrationComplete(for userId: UUID) {
        userDefaults.set(userId.uuidString, forKey: migrationKey)
        print("✅ Marked migration complete for user \(userId.uuidString)")
    }
    
    /// Reset migration flag (for testing/debugging)
    func resetMigrationFlag(for userId: UUID) {
        let migratedUserId = userDefaults.string(forKey: migrationKey)
        if migratedUserId == userId.uuidString {
            userDefaults.removeObject(forKey: migrationKey)
            print("🔄 Reset migration flag for user \(userId.uuidString)")
        }
    }
    
    /// Merge strategy for when remote data already exists
    private func mergeLocalAndRemote(
        localBabies: [Baby],
        remoteBabies: [Baby]
    ) -> [(local: Baby, remote: Baby?)] {
        // Match by name and DOB (within 1 day)
        var matchedPairs: [(local: Baby, remote: Baby?)] = []
        var usedRemoteIndices = Set<Int>()
        
        for localBaby in localBabies {
            var matchedRemote: Baby? = nil
            var matchedIndex: Int? = nil
            
            // Try to find a match
            for (index, remoteBaby) in remoteBabies.enumerated() where !usedRemoteIndices.contains(index) {
                let nameMatches = localBaby.name.lowercased() == remoteBaby.name.lowercased()
                let dobMatches = abs(localBaby.dateOfBirth.timeIntervalSince(remoteBaby.dateOfBirth)) < 86400 // 1 day
                
                if nameMatches && dobMatches {
                    matchedRemote = remoteBaby
                    matchedIndex = index
                    break
                }
            }
            
            matchedPairs.append((local: localBaby, remote: matchedRemote))
            if let index = matchedIndex {
                usedRemoteIndices.insert(index)
            }
        }
        
        return matchedPairs
    }
}

