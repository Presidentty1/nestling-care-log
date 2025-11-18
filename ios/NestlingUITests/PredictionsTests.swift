import XCTest

final class PredictionsTests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func testPredictionsGating() throws {
        app.tabBars.buttons["Labs"].tap()
        
        // Navigate to predictions
        app.buttons["Smart Predictions"].tap()
        
        // Check if AI is enabled or disabled message appears
        let aiDisabledBanner = app.staticTexts["AI Features Disabled"]
        let predictionsButtons = app.buttons["Predict Next Feed"]
        
        XCTAssertTrue(aiDisabledBanner.exists || predictionsButtons.exists)
    }
    
    func testGeneratePrediction() throws {
        // Enable AI first (would need to navigate to settings)
        app.tabBars.buttons["Labs"].tap()
        app.buttons["Smart Predictions"].tap()
        
        if app.buttons["Predict Next Feed"].exists {
            app.buttons["Predict Next Feed"].tap()
            
            // Wait for prediction to appear
            let predictionCard = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'confidence'")).firstMatch
            XCTAssertTrue(predictionCard.waitForExistence(timeout: 5))
        }
    }
}


