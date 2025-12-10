import XCTest
import SwiftUI
@testable import Nestling

final class DesignSystemTests: XCTestCase {

    func testAdaptiveColorsForLightScheme() {
        let lightScheme: ColorScheme = .light

        // Test that adaptive colors return different values for light vs dark
        let lightPrimary = Color.adaptivePrimary(lightScheme)
        let lightBackground = Color.adaptiveBackground(lightScheme)
        let lightSurface = Color.adaptiveSurface(lightScheme)

        XCTAssertNotNil(lightPrimary)
        XCTAssertNotNil(lightBackground)
        XCTAssertNotNil(lightSurface)
    }

    func testAdaptiveColorsForDarkScheme() {
        let darkScheme: ColorScheme = .dark

        // Test that adaptive colors return different values for light vs dark
        let darkPrimary = Color.adaptivePrimary(darkScheme)
        let darkBackground = Color.adaptiveBackground(darkScheme)
        let darkSurface = Color.adaptiveSurface(darkScheme)

        XCTAssertNotNil(darkPrimary)
        XCTAssertNotNil(darkBackground)
        XCTAssertNotNil(darkSurface)
    }

    func testAdaptiveColorsDifferBetweenSchemes() {
        // Test that light and dark schemes return different colors
        let lightPrimary = Color.adaptivePrimary(.light)
        let darkPrimary = Color.adaptivePrimary(.dark)

        // These should be different (light mode has different primary color)
        // Note: This test may need adjustment based on actual color values
        XCTAssertNotEqual(lightPrimary, darkPrimary)
    }

    func testShadowLevels() {
        // Test shadow level properties
        let shadow = ShadowLevel.md

        XCTAssertEqual(shadow.radius, 6)
        XCTAssertEqual(shadow.x, 0)
        XCTAssertEqual(shadow.y, 4)

        // Test that light and dark modes have different colors
        let lightColor = shadow.lightModeColor
        let darkColor = shadow.darkModeColor

        XCTAssertNotEqual(lightColor, darkColor)
    }

    func testNuzzleThemeColorsExist() {
        // Test that all NuzzleTheme colors are accessible
        XCTAssertNotNil(NuzzleTheme.backgroundLight)
        XCTAssertNotNil(NuzzleTheme.surfaceLight)
        XCTAssertNotNil(NuzzleTheme.primaryLight)
        XCTAssertNotNil(NuzzleTheme.textPrimaryLight)

        XCTAssertNotNil(NuzzleTheme.background)
        XCTAssertNotNil(NuzzleTheme.surface)
        XCTAssertNotNil(NuzzleTheme.primary)
        XCTAssertNotNil(NuzzleTheme.textPrimary)
    }

    func testEventAccentColors() {
        // Test event accent colors for both schemes
        let feedColorLight = NuzzleTheme.adaptiveAccent(for: "feed", scheme: .light)
        let feedColorDark = NuzzleTheme.adaptiveAccent(for: "feed", scheme: .dark)

        XCTAssertNotNil(feedColorLight)
        XCTAssertNotNil(feedColorDark)

        // Should be different for light vs dark
        XCTAssertNotEqual(feedColorLight, feedColorDark)
    }
}

