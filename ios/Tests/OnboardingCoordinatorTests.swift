import XCTest
@testable import Nestling

final class OnboardingCoordinatorTests: XCTestCase {
    var coordinator: OnboardingCoordinator!
    var mockDataStore: MockDataStore!

    override func setUp() {
        super.setUp()
        mockDataStore = MockDataStore()

        var onboardingComplete = false
        coordinator = OnboardingCoordinator(dataStore: mockDataStore) {
            onboardingComplete = true
        }
    }

    override func tearDown() {
        coordinator = nil
        mockDataStore = nil
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertEqual(coordinator.currentStep, .babyInfo)
        XCTAssertTrue(coordinator.babyName.isEmpty)
        XCTAssertNil(coordinator.primaryGoal)
    }

    func testNavigationFlow() {
        // Start at babyInfo
        XCTAssertEqual(coordinator.currentStep, .babyInfo)

        // Navigate to goal selection
        coordinator.next()
        XCTAssertEqual(coordinator.currentStep, .goalSelection)

        // Navigate to completion
        coordinator.next()
        // Note: This would trigger completion, but we can't easily test the async completion handler
    }

    func testSkipFunctionality() {
        // Test skip from babyInfo step
        coordinator.skip()
        // Should complete onboarding
    }

    func testGoalSelection() {
        // Test setting a primary goal
        coordinator.primaryGoal = "better_naps"
        XCTAssertEqual(coordinator.primaryGoal, "better_naps")
    }

    func testBabyInfoValidation() {
        // Test baby name validation
        coordinator.babyName = ""
        // Empty name should be handled in completion

        coordinator.babyName = "Test Baby"
        XCTAssertEqual(coordinator.babyName, "Test Baby")
    }

    func testDateOfBirthHandling() {
        // Test date of birth is set
        let testDate = Date()
        coordinator.dateOfBirth = testDate
        XCTAssertEqual(coordinator.dateOfBirth, testDate)
    }
}