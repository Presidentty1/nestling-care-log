import Foundation
import CloudKit

/// CloudKit-based authentication service for Nestling.
/// Handles account status checking, account creation, and data migration.
@MainActor
class CloudKitAuthService {
    static let shared = CloudKitAuthService()

    private let container = CKContainer(identifier: AppConfig.cloudKitContainerIdentifier)
    private let privateDatabase = CKContainer(identifier: AppConfig.cloudKitContainerIdentifier).privateCloudDatabase

    private init() {}

    // MARK: - Account Status

    /// Check CloudKit account status
    func checkAccountStatus() async -> CKAccountStatus {
        do {
            let status = try await container.accountStatus()
            return status
        } catch {
            Logger.authError("CloudKit account status check failed: \(error.localizedDescription)")
            return .couldNotDetermine
        }
    }

    /// Get detailed account information
    func getAccountInfo() async -> (status: CKAccountStatus, userRecordID: CKRecord.ID?) {
        let status = await checkAccountStatus()

        guard status == .available else {
            return (status, nil)
        }

        do {
            let userRecordID = try await container.userRecordID()
            return (status, userRecordID)
        } catch {
            Logger.authError("Failed to get user record ID: \(error.localizedDescription)")
            return (status, nil)
        }
    }

    // MARK: - Authentication

    /// Attempt to authenticate with CloudKit (account must already exist)
    func authenticate() async throws {
        let (status, userRecordID) = await getAccountInfo()

        switch status {
        case .available:
            guard let userRecordID = userRecordID else {
                throw CloudKitAuthError.accountNotFound
            }

            // Verify we can access the private database
            let query = CKQuery(recordType: "Account", predicate: NSPredicate(value: true))
            do {
                let _ = try await privateDatabase.records(matching: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: 1)
                // Success - account exists and is accessible
            } catch CKError.unknownItem {
                // Account doesn't exist in our database, create it
                try await createAccountRecord(userRecordID: userRecordID)
            }

        case .noAccount:
            throw CloudKitAuthError.noCloudKitAccount

        case .restricted:
            throw CloudKitAuthError.accountRestricted

        case .couldNotDetermine:
            throw CloudKitAuthError.accountStatusUnknown

        @unknown default:
            throw CloudKitAuthError.accountStatusUnknown
        }
    }

    /// Create a new account record in CloudKit
    func createAccount(userRecordID: CKRecord.ID) async throws {
        try await createAccountRecord(userRecordID: userRecordID)
    }

    private func createAccountRecord(userRecordID: CKRecord.ID) async throws {
        let accountRecord = CKRecord(recordType: "Account", recordID: userRecordID)
        accountRecord["accountType"] = "cloudkit"
        accountRecord["createdAt"] = Date()

        do {
            let _ = try await privateDatabase.save(accountRecord)
        } catch {
            throw CloudKitAuthError.accountCreationFailed
        }
    }

    // MARK: - Data Migration

    /// Migrate local data to CloudKit
    func migrateLocalData(babies: [Baby], events: [Event]) async throws {
        // Create zone for app data if it doesn't exist
        let zoneID = CKRecordZone.ID(zoneName: "NestlingData", ownerName: CKCurrentUserDefaultName)
        let zone = CKRecordZone(zoneID: zoneID)

        do {
            let _ = try await privateDatabase.save(zone)
        } catch CKError.zoneNotFound {
            // Zone doesn't exist, create it
            let _ = try await privateDatabase.save(zone)
        } catch CKError.userDeletedZone {
            // User deleted zone, recreate it
            let _ = try await privateDatabase.save(zone)
        }

        // Migrate babies
        for baby in babies {
            let babyRecord = CKRecord(recordType: "Baby", recordID: CKRecord.ID(recordName: baby.id.uuidString, zoneID: zoneID))
            babyRecord["name"] = baby.name
            babyRecord["dateOfBirth"] = baby.dateOfBirth
            babyRecord["sex"] = baby.sex?.rawValue
            babyRecord["timezone"] = baby.timezone
            babyRecord["createdAt"] = baby.createdAt
            babyRecord["updatedAt"] = baby.updatedAt

            let _ = try await privateDatabase.save(babyRecord)
        }

        // Migrate events (in batches to avoid limits)
        let batchSize = 100
        for i in stride(from: 0, to: events.count, by: batchSize) {
            let batch = Array(events[i..<min(i + batchSize, events.count)])
            var recordsToSave: [CKRecord] = []

            for event in batch {
                let eventRecord = CKRecord(recordType: "Event", recordID: CKRecord.ID(recordName: event.id.uuidString, zoneID: zoneID))
                eventRecord["babyId"] = event.babyId.uuidString
                eventRecord["type"] = event.type.rawValue
                eventRecord["subtype"] = event.subtype
                eventRecord["amount"] = event.amount
                eventRecord["unit"] = event.unit
                eventRecord["side"] = event.side
                eventRecord["startTime"] = event.startTime
                eventRecord["endTime"] = event.endTime
                eventRecord["durationMinutes"] = event.durationMinutes
                eventRecord["note"] = event.note
                eventRecord["createdAt"] = event.createdAt
                eventRecord["updatedAt"] = event.updatedAt

                recordsToSave.append(eventRecord)
            }

            let _ = try await privateDatabase.modifyRecords(saving: recordsToSave, deleting: [], savePolicy: .allKeys)
        }
    }

    // MARK: - Account Deletion

    /// Delete CloudKit account data
    func deleteAccountData() async throws {
        // Note: CloudKit doesn't allow programmatic account deletion
        // This is a limitation - we can only delete our app's data
        // User must contact support for full account deletion

        let zoneID = CKRecordZone.ID(zoneName: "NestlingData", ownerName: CKCurrentUserDefaultName)

        // Delete all records in our zone
        let query = CKQuery(recordType: "Baby", predicate: NSPredicate(value: true))
        let (results, _) = try await privateDatabase.records(matching: query, inZoneWith: zoneID)

        var recordIDsToDelete: [CKRecord.ID] = []
        for result in results {
            recordIDsToDelete.append(result.0)
        }

        // Also delete events
        let eventQuery = CKQuery(recordType: "Event", predicate: NSPredicate(value: true))
        let (eventResults, _) = try await privateDatabase.records(matching: eventQuery, inZoneWith: zoneID)

        for result in eventResults {
            recordIDsToDelete.append(result.0)
        }

        if !recordIDsToDelete.isEmpty {
            let _ = try await privateDatabase.modifyRecords(saving: [], deleting: recordIDsToDelete, savePolicy: .allKeys)
        }

        // Delete the zone
        do {
            try await privateDatabase.deleteRecordZone(withID: zoneID)
        } catch {
            // Zone might not exist, ignore
        }
    }
}

// MARK: - Errors

enum CloudKitAuthError: LocalizedError {
    case noCloudKitAccount
    case accountRestricted
    case accountStatusUnknown
    case accountNotFound
    case accountCreationFailed
    case migrationFailed
    case dataDeletionFailed

    var errorDescription: String? {
        switch self {
        case .noCloudKitAccount:
            return "No iCloud account found. Please sign in to iCloud in Settings."
        case .accountRestricted:
            return "iCloud account is restricted. Please check parental controls or contact support."
        case .accountStatusUnknown:
            return "Unable to verify iCloud account status. Please try again."
        case .accountNotFound:
            return "Account not found in Nestling. Please contact support."
        case .accountCreationFailed:
            return "Failed to create account. Please try again."
        case .migrationFailed:
            return "Failed to migrate local data to iCloud. Please contact support."
        case .dataDeletionFailed:
            return "Failed to delete account data. Please contact support."
        }
    }
}

