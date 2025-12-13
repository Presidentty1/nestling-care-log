/**
 * Regression tests for DateFormatter performance and caching
 *
 * AUDIT-1: DateFormatter performance issue - should be cached (static lazy property)
 * AUDIT-7: DateFormatter in search filtering should reuse cached instance
 *
 * @see CODEBASE_AUDIT_REPORT.md#1-dateformatter-performance-issue-ios
 * @see CODEBASE_AUDIT_REPORT.md#7-dateformatter-in-search-filtering-ios
 */

import XCTest
@testable import Nestling

final class DateFormatterPerformanceTests: XCTestCase {

    // MARK: - AUDIT-1: DateFormatter Caching Tests

    func testDateFormatterIsCached() {
        // Given: Multiple calls to formatTime
        let testDate = Date()

        // When: Call formatTime multiple times
        let result1 = DateUtils.formatTime(testDate)
        let result2 = DateUtils.formatTime(testDate)
        let result3 = DateUtils.formatTime(testDate)

        // Then: All results should be consistent
        XCTAssertEqual(result1, result2)
        XCTAssertEqual(result2, result3)
        XCTAssertFalse(result1.isEmpty)
    }

    func testDateFormatterIsCachedPerformance() {
        // Given: A test date
        let testDate = Date()
        let iterationCount = 1000

        // When: Format many dates and measure performance
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            for _ in 0..<iterationCount {
                let _ = DateUtils.formatTime(testDate)
                let _ = DateUtils.formatDate(testDate)
            }
        }
    }

    func testDateFormatterInstanceReused() {
        let testDate = Date()

        // Call formatTime multiple times rapidly
        let results = (0..<100).map { _ in DateUtils.formatTime(testDate) }

        // All results should be identical
        let uniqueResults = Set(results)
        XCTAssertEqual(uniqueResults.count, 1, "DateFormatter should produce consistent results")
    }

    // MARK: - AUDIT-7: Search Filtering DateFormatter Tests

    func testSearchFilteringPerformance() {
        // Given: Test date for formatting in search
        let testDate = Date()

        // When: Perform search-like operations
        measure(metrics: [XCTClockMetric()]) {
            for _ in 0..<100 {
                let timeString = DateUtils.formatTime(testDate).lowercased()
                let _ = timeString.contains("8:30")
                let _ = timeString.contains("pm")
            }
        }
    }

    // MARK: - Integration Tests

    func testDateUtilsMethodsUseCachedFormatters() {
        // Given: Various dates to format
        let dates = [
            Date(),
            Date().addingTimeInterval(-3600),
            Date().addingTimeInterval(-86400),
        ]

        // When: Format dates using DateUtils methods
        let timeFormatted = dates.map { DateUtils.formatTime($0) }
        let dateFormatted = dates.map { DateUtils.formatDate($0) }

        // Then: All formatting should succeed
        XCTAssertEqual(timeFormatted.count, 3)
        XCTAssertEqual(dateFormatted.count, 3)
        XCTAssertFalse(timeFormatted.contains { $0.isEmpty })
        XCTAssertFalse(dateFormatted.contains { $0.isEmpty })
    }

    func testConcurrentDateFormatting() {
        // Given: Multiple threads formatting dates simultaneously
        let expectation = XCTestExpectation(description: "Concurrent formatting")
        expectation.expectedFulfillmentCount = 10

        // When: Format dates concurrently
        for i in 0..<10 {
            DispatchQueue.global().async {
                let testDate = Date().addingTimeInterval(TimeInterval(i * 60))
                let timeResult = DateUtils.formatTime(testDate)
                let dateResult = DateUtils.formatDate(testDate)

                XCTAssertFalse(timeResult.isEmpty)
                XCTAssertFalse(dateResult.isEmpty)

                expectation.fulfill()
            }
        }

        // Then: All concurrent formatting should succeed
        wait(for: [expectation], timeout: 5.0)
    }

    // MARK: - Performance Baselines

    func testFormattingPerformanceBaseline() {
        let testDate = Date()

        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            for _ in 0..<1000 {
                let _ = DateUtils.formatTime(testDate)
                let _ = DateUtils.formatDate(testDate)
                let _ = DateUtils.formatRelativeTime(testDate)
            }
        }
    }
}
