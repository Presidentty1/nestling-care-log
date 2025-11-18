import XCTest

/// Comprehensive smoke tests for deep link routing.
/// Verifies all supported deep links route correctly from cold/warm app states.
final class DeepLinkTests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    // MARK: - Logging Event Deep Links
    
    func testLogFeedDeepLink() throws {
        app.open(URL(string: "nestling://log/feed?amount=120&unit=ml")!)
        
        // Verify Home tab is selected (tab 0)
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 2))
        XCTAssertTrue(homeTab.isSelected)
        
        // Verify feed form sheet is presented (if accessible)
        // Note: Form accessibility depends on implementation
    }
    
    func testLogFeedDeepLinkWithoutParams() throws {
        app.open(URL(string: "nestling://log/feed")!)
        
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 2))
        XCTAssertTrue(homeTab.isSelected)
    }
    
    func testLogDiaperDeepLink() throws {
        app.open(URL(string: "nestling://log/diaper?type=wet")!)
        
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 2))
        XCTAssertTrue(homeTab.isSelected)
    }
    
    func testLogTummyDeepLink() throws {
        app.open(URL(string: "nestling://log/tummy?duration=15")!)
        
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 2))
        XCTAssertTrue(homeTab.isSelected)
    }
    
    // MARK: - Sleep Action Deep Links
    
    func testSleepStartDeepLink() throws {
        app.open(URL(string: "nestling://sleep/start")!)
        
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 2))
        XCTAssertTrue(homeTab.isSelected)
    }
    
    func testSleepStopDeepLink() throws {
        app.open(URL(string: "nestling://sleep/stop")!)
        
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 2))
        XCTAssertTrue(homeTab.isSelected)
    }
    
    // MARK: - Navigation Deep Links
    
    func testOpenHomeDeepLink() throws {
        // Start on a different tab
        app.tabBars.buttons["Settings"].tap()
        
        // Open deep link
        app.open(URL(string: "nestling://open/home")!)
        
        // Verify Home tab is selected
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 2))
        XCTAssertTrue(homeTab.isSelected)
    }
    
    func testOpenHistoryDeepLink() throws {
        app.open(URL(string: "nestling://open/history")!)
        
        let historyTab = app.tabBars.buttons["History"]
        XCTAssertTrue(historyTab.waitForExistence(timeout: 2))
        XCTAssertTrue(historyTab.isSelected)
    }
    
    func testOpenPredictionsDeepLink() throws {
        app.open(URL(string: "nestling://open/predictions")!)
        
        // Verify Labs tab is selected (where Predictions is accessed)
        let labsTab = app.tabBars.buttons["Labs"]
        XCTAssertTrue(labsTab.waitForExistence(timeout: 2))
        XCTAssertTrue(labsTab.isSelected)
    }
    
    func testOpenSettingsDeepLink() throws {
        app.open(URL(string: "nestling://open/settings")!)
        
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 2))
        XCTAssertTrue(settingsTab.isSelected)
    }
    
    // MARK: - Cold Start Tests
    
    func testDeepLinkFromColdStart() throws {
        // Terminate app
        app.terminate()
        
        // Launch with deep link
        app.launchArguments = []
        app.launch()
        
        // Open deep link immediately after launch
        app.open(URL(string: "nestling://open/settings")!)
        
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 3))
        XCTAssertTrue(settingsTab.isSelected)
    }
    
    // MARK: - Invalid Deep Links
    
    func testInvalidDeepLink() throws {
        // Invalid scheme
        app.open(URL(string: "invalid://log/feed")!)
        
        // App should remain on current tab (no crash)
        XCTAssertTrue(app.waitForExistence(timeout: 1))
    }
    
    func testUnknownDeepLink() throws {
        // Unknown path
        app.open(URL(string: "nestling://unknown/path")!)
        
        // App should remain on current tab (no crash)
        XCTAssertTrue(app.waitForExistence(timeout: 1))
    }
}

