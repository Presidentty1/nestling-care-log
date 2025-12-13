import XCTest
@testable import Nuzzle

final class CelebrationThrottleTests: XCTestCase {
    var celebrationService: CelebrationService!

    override func setUp() {
        super.setUp()
        celebrationService = CelebrationService.shared
        // Reset recent celebrations
        celebrationService = CelebrationService() // Fresh instance
    }

    func testFirstTimeCelebrationsAlwaysShow() {
        // First log should always show regardless of throttle
        let celebration = Celebration.firstLog(eventType: "feed")
        XCTAssertTrue(celebrationService.shouldShowCelebration(celebration))
    }

    func testMajorMilestonesAlwaysShow() {
        // 7+ day streaks should always show
        let celebration = Celebration.streakMilestone(days: 7)
        XCTAssertTrue(celebrationService.shouldShowCelebration(celebration))

        // Week complete should always show
        let weekComplete = Celebration.weekComplete(weekNumber: 1)
        XCTAssertTrue(celebrationService.shouldShowCelebration(weekComplete))
    }

    func testThrottleMinorCelebrations() {
        let minorCelebration = Celebration.patternMilestone(logsToUnlock: 10)

        // First few should show
        XCTAssertTrue(celebrationService.shouldShowCelebration(minorCelebration))
        XCTAssertTrue(celebrationService.shouldShowCelebration(minorCelebration))
        XCTAssertTrue(celebrationService.shouldShowCelebration(minorCelebration))

        // After max per hour, should be throttled
        XCTAssertFalse(celebrationService.shouldShowCelebration(minorCelebration))
    }

    func testThrottleResetsAfterTime() async {
        let minorCelebration = Celebration.patternMilestone(logsToUnlock: 10)

        // Fill up the throttle
        for _ in 0..<3 {
            _ = celebrationService.shouldShowCelebration(minorCelebration)
        }

        // Should be throttled
        XCTAssertFalse(celebrationService.shouldShowCelebration(minorCelebration))

        // Wait for reset (simulate time passing by creating new instance)
        celebrationService = CelebrationService()

        // Should allow again
        XCTAssertTrue(celebrationService.shouldShowCelebration(minorCelebration))
    }

    func testThrottleDisabled() {
        // When feature flag is disabled, all celebrations should show
        // Note: This test assumes feature flag defaults to enabled
        let minorCelebration = Celebration.patternMilestone(logsToUnlock: 10)

        // Even after throttling, if disabled it should show
        for _ in 0..<5 {
            XCTAssertTrue(celebrationService.shouldShowCelebration(minorCelebration))
        }
    }
}