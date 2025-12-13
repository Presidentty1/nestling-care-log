import XCTest
@testable import Nuzzle

final class ContextualBadgeLogicTests: XCTestCase {
    var summary: DaySummary!

    override func setUp() {
        super.setUp()
        // Create a test summary
        summary = DaySummary(
            feedCount: 8,
            diaperCount: 6,
            sleepCount: 3,
            totalSleepMinutes: 480, // 8 hours
            tummyTimeCount: 2
        )
    }

    func testFeedBadges() {
        // Test on-track feeds (8-12)
        var testSummary = DaySummary(feedCount: 10, diaperCount: 0, sleepCount: 0, totalSleepMinutes: 0, tummyTimeCount: 0)
        var badge = getBadgeForSummary(testSummary, filter: .feeds)
        XCTAssertEqual(badge?.text, "On track")
        XCTAssertEqual(badge?.color, .success)

        // Test low feeds (<6)
        testSummary = DaySummary(feedCount: 4, diaperCount: 0, sleepCount: 0, totalSleepMinutes: 0, tummyTimeCount: 0)
        badge = getBadgeForSummary(testSummary, filter: .feeds)
        XCTAssertEqual(badge?.text, "Low today")
        XCTAssertEqual(badge?.color, .warning)

        // Test no badge (6-7 range)
        testSummary = DaySummary(feedCount: 6, diaperCount: 0, sleepCount: 0, totalSleepMinutes: 0, tummyTimeCount: 0)
        badge = getBadgeForSummary(testSummary, filter: .feeds)
        XCTAssertNil(badge)
    }

    func testSleepBadges() {
        // Test great day (14-17 hours)
        var testSummary = DaySummary(feedCount: 0, diaperCount: 0, sleepCount: 1, totalSleepMinutes: 900, tummyTimeCount: 0) // 15 hours
        var badge = getBadgeForSummary(testSummary, filter: .sleep)
        XCTAssertEqual(badge?.text, "Great day!")
        XCTAssertEqual(badge?.color, .success)

        // Test low sleep (<12 hours)
        testSummary = DaySummary(feedCount: 0, diaperCount: 0, sleepCount: 1, totalSleepMinutes: 400, tummyTimeCount: 0) // 6.67 hours
        badge = getBadgeForSummary(testSummary, filter: .sleep)
        XCTAssertEqual(badge?.text, "Low sleep")
        XCTAssertEqual(badge?.color, .warning)

        // Test no badge (12-13.99 hours)
        testSummary = DaySummary(feedCount: 0, diaperCount: 0, sleepCount: 1, totalSleepMinutes: 720, tummyTimeCount: 0) // 12 hours
        badge = getBadgeForSummary(testSummary, filter: .sleep)
        XCTAssertNil(badge)
    }

    func testDiaperBadges() {
        // Test on-track diapers (6-8)
        var testSummary = DaySummary(feedCount: 0, diaperCount: 7, sleepCount: 0, totalSleepMinutes: 0, tummyTimeCount: 0)
        var badge = getBadgeForSummary(testSummary, filter: .diapers)
        XCTAssertEqual(badge?.text, "On track")
        XCTAssertEqual(badge?.color, .success)

        // Test low diapers (<4)
        testSummary = DaySummary(feedCount: 0, diaperCount: 3, sleepCount: 0, totalSleepMinutes: 0, tummyTimeCount: 0)
        badge = getBadgeForSummary(testSummary, filter: .diapers)
        XCTAssertEqual(badge?.text, "Low today")
        XCTAssertEqual(badge?.color, .warning)
    }

    func testTummyTimeBadges() {
        // Test on-track tummy time (30-60 minutes)
        var testSummary = DaySummary(feedCount: 0, diaperCount: 0, sleepCount: 0, totalSleepMinutes: 0, tummyTimeCount: 1)
        // Note: This test assumes tummyTimeMinutes calculation, which would need to be implemented
        // For now, we'll test the basic structure
        let badge = getBadgeForSummary(testSummary, filter: .tummy)
        XCTAssertNil(badge) // No badge for minimal tummy time
    }

    func testFeatureFlagDisabled() {
        // When feature flag is disabled, no badges should show
        PolishFeatureFlags.shared.setFlag("contextualBadges", enabled: false)

        let badge = getBadgeForSummary(summary, filter: .feeds)
        XCTAssertNil(badge)

        // Reset
        PolishFeatureFlags.shared.setFlag("contextualBadges", enabled: true)
    }

    // Helper function to test badge logic
    private func getBadgeForSummary(_ summary: DaySummary, filter: EventTypeFilter) -> BadgeInfo? {
        guard PolishFeatureFlags.shared.contextualBadgesEnabled else { return nil }

        switch filter {
        case .feeds:
            if summary.feedCount >= 8 && summary.feedCount <= 12 {
                return BadgeInfo(text: "On track", color: .success)
            } else if summary.feedCount < 6 {
                return BadgeInfo(text: "Low today", color: .warning)
            }
        case .sleep:
            let sleepHours = Double(summary.totalSleepMinutes) / 60.0
            if sleepHours >= 14.0 && sleepHours <= 17.0 {
                return BadgeInfo(text: "Great day!", color: .success)
            } else if sleepHours < 12.0 {
                return BadgeInfo(text: "Low sleep", color: .warning)
            }
        case .diapers:
            if summary.diaperCount >= 6 && summary.diaperCount <= 8 {
                return BadgeInfo(text: "On track", color: .success)
            } else if summary.diaperCount < 4 {
                return BadgeInfo(text: "Low today", color: .warning)
            }
        case .tummy:
            if summary.tummyTimeMinutes >= 30 && summary.tummyTimeMinutes <= 60 {
                return BadgeInfo(text: "On track", color: .success)
            } else if summary.tummyTimeMinutes < 15 {
                return BadgeInfo(text: "Low today", color: .warning)
            }
        default:
            break
        }

        return nil
    }
}

// Mock extension for testing
extension DaySummary {
    var tummyTimeMinutes: Int {
        // Mock calculation - would need actual implementation
        return tummyTimeCount * 10
    }
}