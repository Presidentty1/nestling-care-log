import XCTest
@testable import Nestling

final class OfflineQueueServiceTests: XCTestCase {
    var queueService: OfflineQueueService!
    var mockDataStore: MockDataStore!

    override func setUp() {
        super.setUp()
        mockDataStore = MockDataStore()
        queueService = OfflineQueueService.shared
    }

    override func tearDown() {
        mockDataStore = nil
        queueService = nil
        super.tearDown()
    }

    func testQueueOperation() {
        // Given
        let operation = QueuedOperation(
            id: UUID(),
            operationType: .addEvent,
            entityType: .event,
            entityId: UUID(),
            data: Data(),
            timestamp: Date(),
            retryCount: 0
        )

        // When
        queueService.queueOperation(operation)

        // Then
        XCTAssertEqual(queueService.pendingCount, 1)
    }

    func testProcessQueueWithEmptyQueue() async {
        // Given - empty queue

        // When
        await queueService.processQueue()

        // Then - should not crash
        XCTAssertEqual(queueService.pendingCount, 0)
    }

    func testQueueBabyOperation() {
        // Given
        let baby = Baby(
            name: "Test Baby",
            dateOfBirth: Date(),
            sex: .female,
            timezone: "America/New_York"
        )

        // When
        queueService.queueBabyOperation(.addBaby, baby: baby)

        // Then
        XCTAssertEqual(queueService.pendingCount, 1)
    }

    func testQueueEventOperation() {
        // Given
        let event = Event(
            babyId: UUID(),
            type: .feed,
            subtype: "bottle",
            amount: 100,
            unit: "ml"
        )

        // When
        queueService.queueEventOperation(.addEvent, event: event)

        // Then
        XCTAssertEqual(queueService.pendingCount, 1)
    }

    func testQueueSettingsOperation() {
        // Given
        let settings = AppSettings()

        // When
        queueService.queueSettingsOperation(settings: settings)

        // Then
        XCTAssertEqual(queueService.pendingCount, 1)
    }
}

// MARK: - Mock DataStore for testing
class MockDataStore: DataStore {
    func fetchBabies() async throws -> [Baby] { [] }
    func addBaby(_ baby: Baby) async throws {}
    func updateBaby(_ baby: Baby) async throws {}
    func deleteBaby(_ baby: Baby) async throws {}

    func fetchEvents(for baby: Baby, on date: Date) async throws -> [Event] { [] }
    func fetchEvents(for baby: Baby, from startDate: Date, to endDate: Date) async throws -> [Event] { [] }
    func addEvent(_ event: Event) async throws {}
    func updateEvent(_ event: Event) async throws {}
    func deleteEvent(_ event: Event) async throws {}

    func fetchPredictions(for baby: Baby, type: PredictionType) async throws -> Prediction? { nil }
    func generatePrediction(for baby: Baby, type: PredictionType) async throws -> Prediction {
        Prediction(id: UUID(), babyId: baby.id, type: type, predictedTime: Date(), confidence: 0.8, reasoning: "Test", createdAt: Date(), expiresAt: Date())
    }

    func fetchAppSettings() async throws -> AppSettings { AppSettings() }
    func saveAppSettings(_ settings: AppSettings) async throws {}

    func getActiveSleep(for baby: Baby) async throws -> Event? { nil }
    func startActiveSleep(for baby: Baby) async throws -> Event {
        Event(babyId: baby.id, type: .sleep, subtype: "active")
    }
    func stopActiveSleep(for baby: Baby) async throws -> Event {
        Event(babyId: baby.id, type: .sleep, subtype: "completed")
    }

    func getLastUsedValues(for eventType: EventType) async throws -> LastUsedValues? { nil }
    func saveLastUsedValues(for eventType: EventType, values: LastUsedValues) async throws {}

    func forceSyncIfNeeded() async throws {}
}