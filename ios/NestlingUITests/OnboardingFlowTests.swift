import XCTest

final class OnboardingFlowTests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--reset-onboarding"]
        app.launch()
    }
    
    func testOnboardingFlow() throws {
        // Welcome screen
        XCTAssertTrue(app.staticTexts["Welcome to Nestling"].exists)
        app.buttons["Get Started"].tap()
        
        // Baby setup
        let nameField = app.textFields["Baby's name"]
        XCTAssertTrue(nameField.exists)
        nameField.tap()
        nameField.typeText("Test Baby")
        
        app.buttons["Continue"].tap()
        
        // Preferences
        XCTAssertTrue(app.staticTexts["Your Preferences"].exists)
        app.buttons["Continue"].tap()
        
        // AI Consent
        XCTAssertTrue(app.staticTexts["AI-Powered Features"].exists)
        app.buttons["Continue"].tap()
        
        // Notifications intro
        XCTAssertTrue(app.staticTexts["Stay on Track"].exists)
        app.buttons["Get Started"].tap()
        
        // Should land on home screen
        XCTAssertTrue(app.tabBars.buttons["Home"].exists)
    }
}


