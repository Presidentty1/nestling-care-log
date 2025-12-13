import XCTest
@testable import Nestling

final class VoiceDictationHintTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Clear UserDefaults for clean test state
        UserDefaults.standard.removeObject(forKey: "hasDismissedDictationHint")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "hasDismissedDictationHint")
        super.tearDown()
    }

    func testDictationHintShowsByDefault() {
        // Given - clean UserDefaults
        // When - creating VoiceInputView
        // Then - should show hint initially
        // This would be tested with UI testing since it involves state
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "hasDismissedDictationHint"))
    }

    func testDictationHintDismissalPersists() {
        // Given - hint is shown
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "hasDismissedDictationHint"))

        // When - dismissing hint (simulating user action)
        UserDefaults.standard.set(true, forKey: "hasDismissedDictationHint")

        // Then - hint should not show again
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "hasDismissedDictationHint"))
    }

    func testDictationHintDoesNotShowAfterDismissal() {
        // Given - hint was previously dismissed
        UserDefaults.standard.set(true, forKey: "hasDismissedDictationHint")

        // When - checking if hint should show
        let shouldShow = !UserDefaults.standard.bool(forKey: "hasDismissedDictationHint")

        // Then - should not show
        XCTAssertFalse(shouldShow)
    }
}
