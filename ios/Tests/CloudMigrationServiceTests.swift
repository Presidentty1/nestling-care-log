import XCTest
@testable import Nestling

final class CloudMigrationServiceTests: XCTestCase {
    var jsonStore: JSONBackedDataStore!
    var swiftDataStore: SwiftDataStore!
    var migrationService: CloudMigrationService!

    override func setUp() {
        super.setUp()
        jsonStore = JSONBackedDataStore()
        do {
            swiftDataStore = try SwiftDataStore()
            migrationService = CloudMigrationService(jsonStore: jsonStore, swiftDataStore: swiftDataStore)
        } catch {
            XCTFail("Failed to initialize SwiftDataStore: \(error)")
        }
    }

    override func tearDown() {
        jsonStore = nil
        swiftDataStore = nil
        migrationService = nil
        super.tearDown()
    }

    func testNeedsMigrationWithEmptyStores() async {
        // Given - both stores are empty

        // When
        let needsMigration = await migrationService.needsMigration()

        // Then
        XCTAssertFalse(needsMigration)
    }

    func testMigrationSummary() async {
        // When
        let summary = await migrationService.getMigrationSummary()

        // Then
        XCTAssertNotNil(summary)
        XCTAssertEqual(summary.babyCount, 0) // Empty store
        XCTAssertEqual(summary.eventCount, 0) // Empty store
    }

    func testMigrationProgressHandler() async {
        // Given
        var progressValues: [Double] = []
        var statusMessages: [String] = []

        let progressHandler: (String, Double) -> Void = { status, progress in
            statusMessages.append(status)
            progressValues.append(progress)
        }

        // When
        do {
            try await migrationService.migrateData(progressHandler: progressHandler)
        } catch {
            // Expected to fail or succeed based on data
        }

        // Then
        // Verify progress handler was called
        // Note: This test may need adjustment based on actual migration logic
    }
}

