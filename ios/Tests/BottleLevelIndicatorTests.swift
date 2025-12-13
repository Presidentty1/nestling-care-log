import XCTest
@testable import Nestling

final class BottleLevelIndicatorTests: XCTestCase {
    func testFullBottleShowsAllBarsFilled() {
        // Given - 8oz bottle (full)
        let indicator = BottleLevelIndicator(amount: 8.0, unit: .oz)

        // Then - should show 8 filled bars
        // This would be tested with snapshot testing or UI testing
        // For unit testing, we verify the calculation logic
        XCTAssertEqual(indicator.filledBars, 8)
    }

    func testHalfBottleShowsFourBarsFilled() {
        // Given - 4oz in 8oz bottle
        let indicator = BottleLevelIndicator(amount: 4.0, unit: .oz)

        // Then - should show 4 filled bars
        XCTAssertEqual(indicator.filledBars, 4)
    }

    func testMilliliterConversion() {
        // Given - 120ml (which is 4oz)
        let indicator = BottleLevelIndicator(amount: 120.0, unit: .ml)

        // Then - should show 4 filled bars (same as 4oz)
        XCTAssertEqual(indicator.filledBars, 4)
    }

    func testEmptyBottleShowsNoBarsFilled() {
        // Given - empty bottle
        let indicator = BottleLevelIndicator(amount: 0, unit: .oz)

        // Then - should show 0 filled bars
        XCTAssertEqual(indicator.filledBars, 0)
    }
}
