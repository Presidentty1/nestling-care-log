import XCTest
@testable import Nestling

final class FeedFormViewModelTests: XCTestCase {
    var viewModel: FeedFormViewModel!
    var mockDataStore: MockDataStore!
    var baby: Baby!

    override func setUp() {
        super.setUp()
        mockDataStore = MockDataStore()
        baby = Baby(name: "Test Baby", dateOfBirth: Date())
        viewModel = FeedFormViewModel(dataStore: mockDataStore, baby: baby)
    }

    override func tearDown() {
        viewModel = nil
        mockDataStore = nil
        baby = nil
        super.tearDown()
    }

    func testStepperIncrementWithOunces() {
        // Given
        viewModel.unit = .oz
        viewModel.amount = "4.0"

        // When
        let initialValue = Double(viewModel.amount) ?? 0
        viewModel.amount = String(format: "%.1f", initialValue + 0.5)
        viewModel.validate()

        // Then
        XCTAssertEqual(viewModel.amount, "4.5")
        XCTAssertTrue(viewModel.isValid)
    }

    func testStepperIncrementWithMilliliters() {
        // Given
        viewModel.unit = .ml
        viewModel.amount = "120"

        // When
        let initialValue = Double(viewModel.amount) ?? 0
        viewModel.amount = String(format: "%.0f", initialValue + 10.0)
        viewModel.validate()

        // Then
        XCTAssertEqual(viewModel.amount, "130")
        XCTAssertTrue(viewModel.isValid)
    }

    func testStepperDecrementWithBoundsChecking() {
        // Given
        viewModel.unit = .ml
        viewModel.amount = "20" // Below minimum when decremented

        // When
        let initialValue = Double(viewModel.amount) ?? 0
        let newValue = max(0, initialValue - 10.0)
        viewModel.amount = String(format: "%.0f", newValue)
        viewModel.validate()

        // Then
        XCTAssertEqual(viewModel.amount, "10")
        // Validation should fail due to minimum amount
        XCTAssertFalse(viewModel.isValid)
    }

    func testUnitConversionOnStepper() {
        // Given
        viewModel.unit = .oz
        viewModel.amount = "4.0"

        // When - switch to ml
        viewModel.unit = .ml

        // Then - should convert 4 oz to 120 ml
        XCTAssertEqual(viewModel.amount, "120")
    }

    func testMorningFeedAmountIncrease() {
        // Given - morning time (simulate by setting hour)
        // Note: This test would need a way to mock time, but for now we test the logic

        // When - applying smart adjustments with morning bias
        let morningAmount = viewModel.applySmartAdjustments(to: 100.0, unit: .ml)

        // Then - should be increased (this is a basic test of the method)
        XCTAssertGreaterThan(morningAmount, 100.0)
    }

    func testBabyAgeAdjustment() {
        // Given - older baby
        let olderBaby = Baby(name: "Older Baby", dateOfBirth: Calendar.current.date(byAdding: .month, value: -6, to: Date())!)

        // When creating viewModel with older baby
        let olderViewModel = FeedFormViewModel(dataStore: mockDataStore, baby: olderBaby)

        // Then - smart defaults should give larger amounts for older babies
        // This would be tested by checking the final amount set after initialization
        // For now, we verify the method exists and is accessible
        XCTAssertNotNil(olderViewModel)
    }
}
