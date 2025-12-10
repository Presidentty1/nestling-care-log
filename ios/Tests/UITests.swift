import XCTest
@testable import Nestling

final class UITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Onboarding UI Tests

    func testOnboardingFlow() {
        // Test that onboarding starts with baby info step
        XCTAssertTrue(app.staticTexts["What's your main goal with Nuzzle?"].exists)

        // Note: Full UI flow testing would require more complex setup
        // with test-specific app configurations
    }

    func testGoalSelectionUI() {
        // Test that goal options are displayed
        XCTAssertTrue(app.staticTexts["Better naps"].exists)
        XCTAssertTrue(app.staticTexts["Track feeds"].exists)
        XCTAssertTrue(app.staticTexts["Coordinate with partner"].exists)
        XCTAssertTrue(app.staticTexts["Use AI predictions"].exists)
    }

    // MARK: - Home Screen UI Tests

    func testHomeScreenElements() {
        // Test that main home elements exist
        // Note: These tests would need proper setup with test data
        XCTAssertTrue(app.navigationBars.element.exists)
    }

    // MARK: - Settings UI Tests

    func testSettingsNavigation() {
        // Test that settings sections exist
        XCTAssertTrue(app.staticTexts["Display"].exists)
        XCTAssertTrue(app.staticTexts["AI & Smart Features"].exists)
    }

    func testExportDataUI() {
        // Navigate to export data (would need proper navigation setup)
        // This is a placeholder for UI test structure
    }
}

// MARK: - UI Test Helpers

extension XCUIApplication {
    func tapButton(_ label: String) {
        buttons[label].tap()
    }

    func enterText(_ text: String, in field: String) {
        textFields[field].tap()
        typeText(text)
    }

    func selectPickerOption(_ option: String, in picker: String) {
        pickers[picker].tap()
        staticTexts[option].tap()
    }
}


