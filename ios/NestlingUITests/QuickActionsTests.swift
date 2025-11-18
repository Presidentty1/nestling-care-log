import XCTest

final class QuickActionsTests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func testQuickLogFeed() throws {
        app.tabBars.buttons["Home"].tap()
        
        // Find and tap feed quick action
        let feedButton = app.buttons.matching(identifier: "quick_action_feed").firstMatch
        if feedButton.exists {
            feedButton.tap()
            
            // Verify feed was logged (check timeline)
            XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Feed'")).firstMatch.exists)
        }
    }
    
    func testQuickLogSleep() throws {
        app.tabBars.buttons["Home"].tap()
        
        // Start sleep
        let sleepButton = app.buttons.matching(identifier: "quick_action_sleep").firstMatch
        if sleepButton.exists {
            sleepButton.tap()
            
            // Verify sleep started
            XCTAssertTrue(app.buttons["Stop Sleep"].exists || app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Sleep'")).firstMatch.exists)
        }
    }
}


