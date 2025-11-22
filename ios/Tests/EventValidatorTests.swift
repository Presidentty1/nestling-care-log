import XCTest
@testable import Nuzzle

final class EventValidatorTests: XCTestCase {
    var baby: Baby!
    
    override func setUp() {
        super.setUp()
        baby = Baby.mock()
    }
    
    func testValidateFeedWithZeroAmount() {
        let event = Event(
            babyId: baby.id,
            type: .feed,
            subtype: "bottle",
            amount: 0,
            unit: "ml"
        )
        
        XCTAssertThrowsError(try EventValidator.validate(event)) { error in
            XCTAssertEqual(error as? EventValidationError, .zeroAmount)
        }
    }
    
    func testValidateFeedWithNegativeAmount() {
        let event = Event(
            babyId: baby.id,
            type: .feed,
            subtype: "bottle",
            amount: -10,
            unit: "ml"
        )
        
        XCTAssertThrowsError(try EventValidator.validate(event)) { error in
            XCTAssertEqual(error as? EventValidationError, .negativeAmount)
        }
    }
    
    func testValidateBreastFeedWithoutAmount() {
        // Breast feeds don't require amount
        let event = Event(
            babyId: baby.id,
            type: .feed,
            subtype: "breast",
            amount: nil,
            unit: nil
        )
        
        XCTAssertNoThrow(try EventValidator.validate(event))
    }
    
    func testValidateSleepWithEndBeforeStart() {
        let start = Date()
        let end = start.addingTimeInterval(-3600) // 1 hour before start
        
        let event = Event(
            babyId: baby.id,
            type: .sleep,
            subtype: "nap",
            startTime: start,
            endTime: end
        )
        
        XCTAssertThrowsError(try EventValidator.validate(event)) { error in
            XCTAssertEqual(error as? EventValidationError, .endBeforeStart)
        }
    }
    
    func testValidateSleepWithZeroDuration() {
        let start = Date()
        let end = start // Same time = 0 duration
        
        let event = Event(
            babyId: baby.id,
            type: .sleep,
            subtype: "nap",
            startTime: start,
            endTime: end,
            durationMinutes: 0
        )
        
        XCTAssertThrowsError(try EventValidator.validate(event)) { error in
            XCTAssertEqual(error as? EventValidationError, .zeroDuration)
        }
    }
    
    func testValidateSleepWithNegativeDuration() {
        let event = Event(
            babyId: baby.id,
            type: .sleep,
            subtype: "nap",
            startTime: Date(),
            durationMinutes: -10
        )
        
        XCTAssertThrowsError(try EventValidator.validate(event)) { error in
            XCTAssertEqual(error as? EventValidationError, .negativeDuration)
        }
    }
    
    func testValidateEventInFuture() {
        let futureDate = Date().addingTimeInterval(48 * 3600) // 48 hours in future
        
        let event = Event(
            babyId: baby.id,
            type: .feed,
            subtype: "bottle",
            amount: 120,
            unit: "ml",
            startTime: futureDate
        )
        
        XCTAssertThrowsError(try EventValidator.validate(event)) { error in
            XCTAssertEqual(error as? EventValidationError, .invalidDateRange)
        }
    }
    
    func testValidateValidEvent() {
        let event = Event(
            babyId: baby.id,
            type: .feed,
            subtype: "bottle",
            amount: 120,
            unit: "ml",
            startTime: Date()
        )
        
        XCTAssertNoThrow(try EventValidator.validate(event))
    }
}

extension EventValidationError: Equatable {
    public static func == (lhs: EventValidationError, rhs: EventValidationError) -> Bool {
        switch (lhs, rhs) {
        case (.endBeforeStart, .endBeforeStart),
             (.negativeDuration, .negativeDuration),
             (.zeroDuration, .zeroDuration),
             (.zeroAmount, .zeroAmount),
             (.negativeAmount, .negativeAmount),
             (.invalidDateRange, .invalidDateRange):
            return true
        default:
            return false
        }
    }
}


