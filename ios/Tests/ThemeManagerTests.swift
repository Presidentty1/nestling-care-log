import XCTest
@testable import Nestling

final class ThemeManagerTests: XCTestCase {

    var themeManager: ThemeManager!

    override func setUp() {
        super.setUp()
        themeManager = ThemeManager()
        // Clear any existing preference
        UserDefaults.standard.removeObject(forKey: "app_theme_preference")
    }

    override func tearDown() {
        // Clean up after each test
        UserDefaults.standard.removeObject(forKey: "app_theme_preference")
        themeManager = nil
        super.tearDown()
    }

    func testInitialStateIsSystem() {
        // When no preference is set, should return nil (system)
        XCTAssertNil(themeManager.effectiveTheme)
        XCTAssertFalse(themeManager.hasExplicitThemePreference)
        XCTAssertNil(themeManager.themePreference)
    }

    func testSetLightMode() {
        themeManager.setLightMode()

        XCTAssertEqual(themeManager.themePreference, "light")
        XCTAssertEqual(themeManager.effectiveTheme, .light)
        XCTAssertTrue(themeManager.hasExplicitThemePreference)
    }

    func testSetDarkMode() {
        themeManager.setDarkMode()

        XCTAssertEqual(themeManager.themePreference, "dark")
        XCTAssertEqual(themeManager.effectiveTheme, .dark)
        XCTAssertTrue(themeManager.hasExplicitThemePreference)
    }

    func testSetSystemMode() {
        // First set to light, then back to system
        themeManager.setLightMode()
        themeManager.setSystemMode()

        XCTAssertNil(themeManager.themePreference)
        XCTAssertNil(themeManager.effectiveTheme)
        XCTAssertFalse(themeManager.hasExplicitThemePreference)
    }

    func testToggleThemeFromLightToDark() {
        themeManager.setLightMode()
        themeManager.toggleTheme()

        XCTAssertEqual(themeManager.themePreference, "dark")
        XCTAssertEqual(themeManager.effectiveTheme, .dark)
    }

    func testToggleThemeFromDarkToLight() {
        themeManager.setDarkMode()
        themeManager.toggleTheme()

        XCTAssertEqual(themeManager.themePreference, "light")
        XCTAssertEqual(themeManager.effectiveTheme, .light)
    }

    func testToggleThemeFromSystemDefaultsToLight() {
        // System mode should toggle to light (first option)
        themeManager.setSystemMode()
        themeManager.toggleTheme()

        XCTAssertEqual(themeManager.themePreference, "light")
        XCTAssertEqual(themeManager.effectiveTheme, .light)
    }

    func testPersistenceAcrossInstances() {
        // Set preference in one instance
        themeManager.setLightMode()

        // Create new instance and verify persistence
        let newThemeManager = ThemeManager()
        XCTAssertEqual(newThemeManager.themePreference, "light")
        XCTAssertEqual(newThemeManager.effectiveTheme, .light)
    }
}

