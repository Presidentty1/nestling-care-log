import XCTest
@testable import Nestling

final class EventValidatorTests: XCTestCase {

    func testValidFeedEvent() {
        let event = Event(
            babyId: UUID().uuidString,
            type: .feed,
            subtype: "bottle",
            amount: 120,
            unit: "ml",
            startTime: Date(),
            note: "Test feed"
        )

        XCTAssertNoThrow(try EventValidator.validate(event))
    }

    func testInvalidFeedAmount() {
        let event = Event(
            babyId: UUID().uuidString,
            type: .feed,
            subtype: "bottle",
            amount: 0, // Invalid: zero amount
            unit: "ml",
            startTime: Date()
        )

        XCTAssertThrowsError(try EventValidator.validate(event)) { error in
            XCTAssertTrue(error.localizedDescription.contains("amount"))
        }
    }

    func testValidSleepEvent() {
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(3600) // 1 hour later

        XCTAssertNoThrow(try EventValidator.validateSleep(startTime: startTime, endTime: endTime))
    }

    func testInvalidSleepEndBeforeStart() {
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(-3600) // 1 hour earlier

        XCTAssertThrowsError(try EventValidator.validateSleep(startTime: startTime, endTime: endTime))
    }

    func testInvalidSleepTooShort() {
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(10) // Only 10 seconds

        XCTAssertThrowsError(try EventValidator.validateSleep(startTime: startTime, endTime: endTime))
    }

    func testValidDiaperEvent() {
        let event = Event(
            babyId: UUID().uuidString,
            type: .diaper,
            subtype: "wet",
            startTime: Date()
        )

        XCTAssertNoThrow(try EventValidator.validate(event))
    }

    func testValidTummyTimeEvent() {
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(600) // 10 minutes

        let event = Event(
            babyId: UUID().uuidString,
            type: .tummyTime,
            startTime: startTime,
            endTime: endTime
        )

        XCTAssertNoThrow(try EventValidator.validate(event))
    }

    func testInvalidTummyTimeTooLong() {
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(7200) // 2 hours (too long)

        let event = Event(
            babyId: UUID().uuidString,
            type: .tummyTime,
            startTime: startTime,
            endTime: endTime
        )

        XCTAssertThrowsError(try EventValidator.validate(event))
    }

    func testInvalidEmptyBabyId() {
        let event = Event(
            babyId: "", // Invalid: empty baby ID
            type: .feed,
            startTime: Date()
        )

        XCTAssertThrowsError(try EventValidator.validate(event))
    }

    func testInvalidFutureStartTime() {
        let futureTime = Date().addingTimeInterval(86400) // Tomorrow

        let event = Event(
            babyId: UUID().uuidString,
            type: .feed,
            startTime: futureTime // Invalid: future time
        )

        XCTAssertThrowsError(try EventValidator.validate(event))
    }

    func testValidEventWithNotes() {
        let event = Event(
            babyId: UUID().uuidString,
            type: .feed,
            subtype: "breast",
            startTime: Date(),
            note: "This is a valid note with some details about the feeding session"
        )

        XCTAssertNoThrow(try EventValidator.validate(event))
    }

    func testInvalidNoteTooLong() {
        let longNote = String(repeating: "a", count: 1001) // Over 1000 characters

        let event = Event(
            babyId: UUID().uuidString,
            type: .feed,
            startTime: Date(),
            note: longNote
        )

        XCTAssertThrowsError(try EventValidator.validate(event))
    }
}