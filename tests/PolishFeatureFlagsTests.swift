import XCTest
@testable import Nuzzle

final class PolishFeatureFlagsTests: XCTestCase {
    var flags: PolishFeatureFlags!

    override func setUp() {
        super.setUp()
        flags = PolishFeatureFlags.shared
        // Reset to defaults
        flags.resetAllToDefaults()
    }

    override func tearDown() {
        flags.resetAllToDefaults()
        super.tearDown()
    }

    func testDefaultValues() {
        XCTAssertTrue(flags.skeletonLoadingEnabled)
        XCTAssertTrue(flags.contextualBadgesEnabled)
        XCTAssertTrue(flags.smartCTAsEnabled)
        XCTAssertTrue(flags.shareCardsEnabled)
        XCTAssertFalse(flags.allPolishDisabled)
    }

    func testKillSwitch() {
        flags.setFlag("polish.killSwitch", enabled: true)
        XCTAssertTrue(flags.allPolishDisabled)
        XCTAssertFalse(flags.skeletonLoadingEnabled)
        XCTAssertFalse(flags.contextualBadgesEnabled)
    }

    func testIndividualFlagControl() {
        flags.setFlag("skeletonLoading", enabled: false)
        XCTAssertFalse(flags.skeletonLoadingEnabled)
        XCTAssertTrue(flags.contextualBadgesEnabled) // Others unchanged
    }

    func testResetToDefaults() {
        flags.setFlag("skeletonLoading", enabled: false)
        flags.setFlag("contextualBadges", enabled: false)
        flags.resetAllToDefaults()

        XCTAssertTrue(flags.skeletonLoadingEnabled)
        XCTAssertTrue(flags.contextualBadgesEnabled)
    }
}
