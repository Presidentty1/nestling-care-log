import XCTest
@testable import Nestling

final class IntegrationTests: XCTestCase {
    var dataStore: JSONBackedDataStore!
    var baby: Baby!

    override func setUp() {
        super.setUp()
        dataStore = JSONBackedDataStore()
        baby = Baby(
            name: "Integration Test Baby",
            dateOfBirth: Date(),
            sex: .female,
            timezone: "America/New_York"
        )
    }

    override func tearDown() {
        dataStore = nil
        baby = nil
        super.tearDown()
    }

    // MARK: - Onboarding Flow Integration Test

    func testCompleteOnboardingFlow() async throws {
        // Given - fresh onboarding coordinator
        var onboardingComplete = false
        let coordinator = OnboardingCoordinator(dataStore: dataStore) {
            onboardingComplete = true
        }

        // When - complete onboarding
        coordinator.babyName = "Test Baby"
        coordinator.dateOfBirth = Date()
        coordinator.primaryGoal = "better_naps"
        coordinator.next() // babyInfo -> goalSelection
        coordinator.next() // goalSelection -> complete

        // Wait for completion
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Then - baby should be created and settings saved
        let babies = try await dataStore.fetchBabies()
        XCTAssertEqual(babies.count, 1)
        XCTAssertEqual(babies[0].name, "Test Baby")

        let settings = try await dataStore.fetchAppSettings()
        XCTAssertTrue(settings.onboardingCompleted)
        XCTAssertEqual(settings.primaryGoal, "better_naps")
    }

    // MARK: - Event Logging Flow Integration Test

    func testEventLoggingFlow() async throws {
        // Given - baby exists
        try await dataStore.addBaby(baby)

        // When - log multiple events
        let feedEvent = Event(
            babyId: baby.id,
            type: .feed,
            subtype: "bottle",
            amount: 120,
            unit: "ml"
        )

        let diaperEvent = Event(
            babyId: baby.id,
            type: .diaper,
            subtype: "wet"
        )

        let sleepEvent = Event(
            babyId: baby.id,
            type: .sleep,
            subtype: "nap",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600) // 1 hour
        )

        try await dataStore.addEvent(feedEvent)
        try await dataStore.addEvent(diaperEvent)
        try await dataStore.addEvent(sleepEvent)

        // Then - events should be retrievable
        let todayEvents = try await dataStore.fetchEvents(for: baby, on: Date())
        XCTAssertEqual(todayEvents.count, 3)

        let allEvents = try await dataStore.fetchEvents(
            for: baby,
            from: Date.distantPast,
            to: Date.distantFuture
        )
        XCTAssertEqual(allEvents.count, 3)

        // Check specific event properties
        let feedEvents = allEvents.filter { $0.type == .feed }
        XCTAssertEqual(feedEvents.count, 1)
        XCTAssertEqual(feedEvents[0].amount, 120)
        XCTAssertEqual(feedEvents[0].unit, "ml")
    }

    // MARK: - Achievement System Integration Test

    func testAchievementUnlockingFlow() async throws {
        // Given - baby exists
        try await dataStore.addBaby(baby)

        // When - log first event
        let event = Event(babyId: baby.id, type: .feed, amount: 100, unit: "ml")
        try await dataStore.addEvent(event)

        // Then - check for achievements
        let newAchievements = await AchievementService.shared.checkForNewAchievements(
            baby: baby,
            dataStore: dataStore
        )

        // Should unlock "Getting Started" achievement
        XCTAssertFalse(newAchievements.isEmpty)
        let firstAchievement = newAchievements.first
        XCTAssertEqual(firstAchievement?.id, "first_log")
    }

    // MARK: - Data Export Integration Test

    func testDataExportFlow() async throws {
        // Given - baby with events exists
        try await dataStore.addBaby(baby)

        let events = [
            Event(babyId: baby.id, type: .feed, amount: 100, unit: "ml"),
            Event(babyId: baby.id, type: .diaper, subtype: "wet"),
            Event(babyId: baby.id, type: .sleep, startTime: Date(), endTime: Date().addingTimeInterval(7200))
        ]

        for event in events {
            try await dataStore.addEvent(event)
        }

        // When - export data
        let exportService = DataExportService(dataStore: dataStore)

        // Test CSV export
        let csvURL = try await exportService.exportData(for: baby, format: .csv)
        XCTAssertTrue(FileManager.default.fileExists(atPath: csvURL.path))

        // Test JSON export
        let jsonURL = try await exportService.exportData(for: baby, format: .json)
        XCTAssertTrue(FileManager.default.fileExists(atPath: jsonURL.path))

        // Verify CSV content
        let csvContent = try String(contentsOf: csvURL)
        XCTAssertTrue(csvContent.contains("Date,Time,Event Type"))
        XCTAssertTrue(csvContent.contains("feed"))
        XCTAssertTrue(csvContent.contains("diaper"))
        XCTAssertTrue(csvContent.contains("sleep"))

        // Verify JSON content
        let jsonContent = try String(contentsOf: jsonURL)
        let jsonData = jsonContent.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
        XCTAssertNotNil(json["events"])
        XCTAssertNotNil(json["exportInfo"])
    }

    // MARK: - Offline Queue Integration Test

    func testOfflineQueueFlow() async throws {
        // Given - offline queue service
        let queueService = OfflineQueueService.shared

        // When - queue operations while "offline"
        let baby = Baby(name: "Offline Test Baby", dateOfBirth: Date())
        queueService.queueBabyOperation(.addBaby, baby: baby)

        let event = Event(babyId: baby.id, type: .feed, amount: 100, unit: "ml")
        queueService.queueEventOperation(.addEvent, event: event)

        // Then - operations should be queued
        XCTAssertEqual(queueService.pendingCount, 2)

        // When - process queue (simulating reconnection)
        await queueService.processQueue()

        // Then - queue should be processed
        // Note: In real integration, this would sync to a server
        // For this test, we verify the queue processing doesn't crash
        XCTAssertEqual(queueService.pendingCount, 0)
    }

    // MARK: - Settings Persistence Integration Test

    func testSettingsPersistenceFlow() async throws {
        // Given - initial settings
        var settings = try await dataStore.fetchAppSettings()
        let originalUnit = settings.preferredUnit

        // When - modify and save settings
        settings.preferredUnit = originalUnit == "ml" ? "oz" : "ml"
        settings.aiDataSharingEnabled = !settings.aiDataSharingEnabled
        settings.primaryGoal = "better_naps"

        try await dataStore.saveAppSettings(settings)

        // Then - settings should persist
        let loadedSettings = try await dataStore.fetchAppSettings()
        XCTAssertEqual(loadedSettings.preferredUnit, settings.preferredUnit)
        XCTAssertEqual(loadedSettings.aiDataSharingEnabled, settings.aiDataSharingEnabled)
        XCTAssertEqual(loadedSettings.primaryGoal, settings.primaryGoal)
    }

    // MARK: - Prediction System Integration Test

    func testPredictionFlow() async throws {
        // Given - baby with sleep data
        try await dataStore.addBaby(baby)

        // Add some sleep events for pattern analysis
        let yesterday = Date().addingTimeInterval(-86400)
        let sleepEvents = [
            Event(babyId: baby.id, type: .sleep, startTime: yesterday.addingTimeInterval(-3600), endTime: yesterday),
            Event(babyId: baby.id, type: .sleep, startTime: yesterday.addingTimeInterval(7200), endTime: yesterday.addingTimeInterval(10800))
        ]

        for event in sleepEvents {
            try await dataStore.addEvent(event)
        }

        // When - generate nap prediction
        let prediction = try await dataStore.generatePrediction(for: baby, type: .nextNap)

        // Then - prediction should be created
        XCTAssertEqual(prediction.babyId, baby.id)
        XCTAssertEqual(prediction.type, .nextNap)
        XCTAssertGreaterThan(prediction.confidence, 0)
        XCTAssertFalse(prediction.reasoning.isEmpty)

        // And should be retrievable
        let retrievedPrediction = try await dataStore.fetchPredictions(for: baby, type: .nextNap)
        XCTAssertNotNil(retrievedPrediction)
        XCTAssertEqual(retrievedPrediction?.id, prediction.id)
    }
}




