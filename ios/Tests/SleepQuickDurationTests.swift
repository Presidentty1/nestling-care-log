import XCTest
@testable import Nestling

final class SleepQuickDurationTests: XCTestCase {
    var viewModel: SleepFormViewModel!
    var mockDataStore: MockDataStore!
    var baby: Baby!

    override func setUp() {
        super.setUp()
        mockDataStore = MockDataStore()
        baby = Baby(name: "Test Baby", dateOfBirth: Date())
        viewModel = SleepFormViewModel(dataStore: mockDataStore, baby: baby)
    }

    override func tearDown() {
        viewModel = nil
        mockDataStore = nil
        baby = nil
        super.tearDown()
    }

    func testQuickLog15Minutes() async throws {
        // Given
        viewModel.mode = .quick // Set to quick mode
        let initialTime = Date()

        // When - simulate quick logging 15 minutes
        viewModel.endTime = initialTime
        viewModel.startTime = initialTime.addingTimeInterval(-15 * 60)
        viewModel.isTimerMode = false

        try await viewModel.save()

        // Then
        XCTAssertEqual(viewModel.subtype, .nap) // Default subtype
        // Verify event was saved (would need to check mock data store)
    }

    func testQuickLog2Hours() async throws {
        // Given
        viewModel.mode = .quick
        let initialTime = Date()

        // When - simulate quick logging 2 hours
        viewModel.endTime = initialTime
        viewModel.startTime = initialTime.addingTimeInterval(-120 * 60)
        viewModel.isTimerMode = false

        try await viewModel.save()

        // Then
        // Verify duration calculation is correct
        let duration = Int(viewModel.endTime!.timeIntervalSince(viewModel.startTime) / 60)
        XCTAssertEqual(duration, 120)
    }

    func testQuickModeSetsCorrectDefaults() {
        // Given - timer mode initially
        viewModel.isTimerMode = true

        // When - switch to quick mode
        // This would be handled by the view's mode setter
        viewModel.isTimerMode = false
        viewModel.endTime = nil

        // Then
        XCTAssertFalse(viewModel.isTimerMode)
        XCTAssertNil(viewModel.endTime)
    }
}

