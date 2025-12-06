import XCTest
@testable import Nestling

final class DateUtilsTests: XCTestCase {

    func testDaysTextSingular() {
        XCTAssertEqual(DateUtils.daysText(for: 1), "1 day")
    }

    func testDaysTextPlural() {
        XCTAssertEqual(DateUtils.daysText(for: 0), "0 days")
        XCTAssertEqual(DateUtils.daysText(for: 2), "2 days")
        XCTAssertEqual(DateUtils.daysText(for: 10), "10 days")
    }

    func testFormatRelativeTimeJustNow() {
        let now = Date()
        let result = DateUtils.formatRelativeTime(now)
        XCTAssertEqual(result, "Just now")
    }

    func testFormatRelativeTimeMinutes() {
        let fiveMinutesAgo = Date().addingTimeInterval(-300) // 5 minutes ago
        let result = DateUtils.formatRelativeTime(fiveMinutesAgo)
        XCTAssertEqual(result, "5m ago")
    }

    func testFormatRelativeTimeHours() {
        let twoHoursAgo = Date().addingTimeInterval(-7200) // 2 hours ago
        let result = DateUtils.formatRelativeTime(twoHoursAgo)
        XCTAssertEqual(result, "2h ago")
    }

    func testFormatRelativeTimeDays() {
        let threeDaysAgo = Date().addingTimeInterval(-259200) // 3 days ago
        let result = DateUtils.formatRelativeTime(threeDaysAgo)
        XCTAssertEqual(result, "3d ago")
    }

    func testFormatTimeWithLocale() {
        let date = Date()
        let result = DateUtils.formatTime(date)

        // Test that it returns a non-empty string
        XCTAssertFalse(result.isEmpty)

        // Test that it contains expected time format elements
        let hasTimeElements = result.contains(":") || result.contains("AM") || result.contains("PM") ||
                             result.contains("am") || result.contains("pm")
        XCTAssertTrue(hasTimeElements, "Time format should contain time elements")
    }

    func testFormatDurationHoursAndMinutes() {
        XCTAssertEqual(DateUtils.formatDuration(90), "1h 30m")
        XCTAssertEqual(DateUtils.formatDuration(60), "1h 0m")
        XCTAssertEqual(DateUtils.formatDuration(30), "30m")
        XCTAssertEqual(DateUtils.formatDuration(150), "2h 30m")
    }

    func testFormatDurationEdgeCases() {
        XCTAssertEqual(DateUtils.formatDuration(0), "0m")
        XCTAssertEqual(DateUtils.formatDuration(-30), "-30m") // Should handle negative (though unlikely)
    }
}