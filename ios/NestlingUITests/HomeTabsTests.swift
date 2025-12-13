import XCTest

final class HomeTabsTests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    func testTabSwitching() throws {
        // Wait for home screen to load
        let dashboardTab = app.buttons["Dashboard"]
        let timelineTab = app.buttons["Activity"]

        // Verify tabs exist and are accessible
        XCTAssertTrue(dashboardTab.exists, "Dashboard tab should exist")
        XCTAssertTrue(timelineTab.exists, "Timeline tab should exist")

        // Test switching to timeline
        timelineTab.tap()
        // Could add assertions for timeline content if needed
    }

    func testSummaryTileTapping() throws {
        // Given: On dashboard tab
        let feedsTile = app.buttons["Filter by feeds: 1 events"]

        // When: Tap feeds tile
        if feedsTile.exists {
            feedsTile.tap()

            // Then: Should switch to timeline tab
            // This would require more complex setup to verify the tab switch
            // and filtered content
        }
    }
}
