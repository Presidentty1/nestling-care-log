import XCTest

final class ExportTests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func testCSVExport() throws {
        app.tabBars.buttons["Settings"].tap()
        app.buttons["Export & Delete Data"].tap()
        
        // Tap export CSV button
        app.buttons["Export CSV"].tap()
        
        // Verify share sheet appears
        let shareSheet = app.otherElements["ActivityListView"]
        XCTAssertTrue(shareSheet.waitForExistence(timeout: 2))
        
        // Take screenshot
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "CSV Export Share Sheet"
        add(attachment)
    }
}


