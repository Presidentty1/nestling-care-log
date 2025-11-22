import XCTest
@testable import Nuzzle

final class DateUtilsTests: XCTestCase {
    func testFormatRelativeTime() {
        let now = Date()
        let oneMinuteAgo = now.addingTimeInterval(-60)
        let oneHourAgo = now.addingTimeInterval(-3600)
        let oneDayAgo = now.addingTimeInterval(-86400)
        
        XCTAssertEqual(DateUtils.formatRelativeTime(oneMinuteAgo), "1m ago")
        XCTAssertEqual(DateUtils.formatRelativeTime(oneHourAgo), "1h ago")
        XCTAssertEqual(DateUtils.formatRelativeTime(oneDayAgo), "1d ago")
    }
    
    func testFormatDuration() {
        XCTAssertEqual(DateUtils.formatDuration(minutes: 30), "30m")
        XCTAssertEqual(DateUtils.formatDuration(minutes: 60), "1h")
        XCTAssertEqual(DateUtils.formatDuration(minutes: 90), "1h 30m")
        XCTAssertEqual(DateUtils.formatDuration(minutes: 0), "0m")
        XCTAssertEqual(DateUtils.formatDuration(minutes: -5), "0m") // Negative handled
    }
    
    func testStartOfDay() {
        let date = Date()
        let start = DateUtils.startOfDay(for: date)
        let calendar = Calendar.current
        
        XCTAssertEqual(calendar.component(.hour, from: start), 0)
        XCTAssertEqual(calendar.component(.minute, from: start), 0)
    }
    
    // MARK: - DST Tests
    
    func testDSTForwardTransition() {
        // Simulate DST forward (spring forward) - 2 AM becomes 3 AM
        // This test verifies durations don't become negative
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 3
        components.day = 10 // DST start in US (approximate)
        components.hour = 1
        components.minute = 0
        
        guard let beforeDST = calendar.date(from: components),
              let afterDST = calendar.date(byAdding: .hour, value: 2, to: beforeDST) else {
            XCTFail("Could not create DST test dates")
            return
        }
        
        let duration = DateUtils.durationMinutes(from: beforeDST, to: afterDST)
        XCTAssertGreaterThanOrEqual(duration, 60, "Duration should be at least 60 minutes (may be 120 due to DST)")
        XCTAssertLessThanOrEqual(duration, 120, "Duration should not exceed 120 minutes")
    }
    
    func testDSTBackwardTransition() {
        // Simulate DST backward (fall back) - 2 AM becomes 1 AM
        // This test verifies durations are calculated correctly
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 11
        components.day = 3 // DST end in US (approximate)
        components.hour = 1
        components.minute = 0
        
        guard let beforeFallback = calendar.date(from: components),
              let afterFallback = calendar.date(byAdding: .hour, value: 2, to: beforeFallback) else {
            XCTFail("Could not create DST test dates")
            return
        }
        
        let duration = DateUtils.durationMinutes(from: beforeFallback, to: afterFallback)
        XCTAssertGreaterThanOrEqual(duration, 60, "Duration should be at least 60 minutes")
        XCTAssertLessThanOrEqual(duration, 180, "Duration may be up to 180 minutes due to DST")
    }
    
    func testMidnightRollover() {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 1
        components.hour = 23
        components.minute = 59
        
        guard let beforeMidnight = calendar.date(from: components),
              let afterMidnight = calendar.date(byAdding: .minute, value: 2, to: beforeMidnight) else {
            XCTFail("Could not create midnight test dates")
            return
        }
        
        let bucket1 = DateUtils.dayBucket(for: beforeMidnight)
        let bucket2 = DateUtils.dayBucket(for: afterMidnight)
        
        // Should be different day buckets
        XCTAssertNotEqual(bucket1, bucket2, "Dates across midnight should have different buckets")
    }
    
    func testTimezoneChange() {
        let date = Date()
        let pst = TimeZone(identifier: "America/Los_Angeles")!
        let est = TimeZone(identifier: "America/New_York")!
        
        let adjusted = DateUtils.adjustForTimezone(date, from: pst, to: est)
        let offset = est.secondsFromGMT(for: date) - pst.secondsFromGMT(for: date)
        
        XCTAssertEqual(adjusted.timeIntervalSince(date), TimeInterval(offset), accuracy: 1.0)
    }
    
    func testDurationNeverNegative() {
        let start = Date()
        let end = start.addingTimeInterval(-3600) // 1 hour before start
        
        let duration = DateUtils.durationMinutes(from: start, to: end)
        XCTAssertGreaterThanOrEqual(duration, 0, "Duration should never be negative")
        XCTAssertEqual(duration, 60, "Should calculate absolute duration")
    }
    
    func testSameDayCheck() {
        let calendar = Calendar.current
        let date1 = Date()
        let date2 = calendar.date(byAdding: .hour, value: 12, to: date1)!
        
        XCTAssertTrue(DateUtils.isSameDay(date1, date2), "Same day dates should be identified")
        
        let date3 = calendar.date(byAdding: .day, value: 1, to: date1)!
        XCTAssertFalse(DateUtils.isSameDay(date1, date3), "Different day dates should not match")
    }
}

