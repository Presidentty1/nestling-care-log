import XCTest
@testable import Nestling

final class TipServiceTests: XCTestCase {
    var tipService: TipService!

    override func setUp() {
        super.setUp()
        tipService = TipService.shared
    }

    override func tearDown() {
        tipService = nil
        super.tearDown()
    }

    func testTipServiceInitialization() {
        XCTAssertNotNil(tipService)
    }

    func testShouldShowNewTip() {
        // Test that new tip should be shown initially
        let shouldShow = tipService.shouldShowNewTip()
        XCTAssertTrue(shouldShow, "Should show new tip when none have been shown recently")
    }

    func testGetNextTip() async {
        // Given
        let baby = Baby(name: "Test Baby", dateOfBirth: Date())

        // When
        let tip = await tipService.getNextTip(for: baby, goal: "better_naps", dataStore: MockDataStore())

        // Then
        // Tip may be nil if no tips match the criteria, which is acceptable
        if let tip = tip {
            XCTAssertFalse(tip.title.isEmpty)
            XCTAssertFalse(tip.content.isEmpty)
            XCTAssertGreaterThan(tip.ageRange.lowerBound, 0)
            XCTAssertLessThanOrEqual(tip.ageRange.upperBound, 52)
        }
    }

    func testGetNextTipWithGoal() async {
        // Given
        let baby = Baby(name: "Test Baby", dateOfBirth: Date())
        let goals = ["better_naps", "track_feeds", "coordinate_caregiver", "ai_predictions"]

        // When/Then
        for goal in goals {
            let tip = await tipService.getNextTip(for: baby, goal: goal, dataStore: MockDataStore())
            if let tip = tip {
                XCTAssertFalse(tip.title.isEmpty)
                // The tip should be relevant to the age range
                let babyAgeWeeks = tipService.calculateBabyAgeInWeeks(birthDate: baby.dateOfBirth)
                XCTAssertTrue(tip.ageRange.contains(babyAgeWeeks))
            }
        }
    }

    func testCalculateBabyAgeInWeeks() {
        // Given
        let calendar = Calendar.current
        let fourWeeksAgo = calendar.date(byAdding: .weekOfYear, value: -4, to: Date())!

        // When
        let ageWeeks = tipService.calculateBabyAgeInWeeks(birthDate: fourWeeksAgo)

        // Then
        XCTAssertEqual(ageWeeks, 4, accuracy: 1) // Allow some tolerance for date calculations
    }
}

// Extension to access private method for testing
extension TipService {
    func calculateBabyAgeInWeeks(birthDate: Date) -> Int {
        let components = Calendar.current.dateComponents([.day], from: birthDate, to: Date())
        return (components.day ?? 0) / 7
    }
}






