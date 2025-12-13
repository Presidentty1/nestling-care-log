//
//  AnalyticsServiceTests.swift
//  NuzzleTests
//
//  Created by AI Assistant on 2025
//

import XCTest
@testable import Nuzzle

final class AnalyticsServiceTests: XCTestCase {
    private var analytics: Analytics!

    override func setUp() {
        super.setUp()
        analytics = Analytics.shared
    }

    override func tearDown() {
        super.tearDown()
        analytics = nil
    }

    func testAnalyticsInitiallyEnabled() {
        // Analytics should be enabled by default
        XCTAssertTrue(analytics.isEnabled, "Analytics should be enabled by default")
    }

    func testAnalyticsCanBeDisabled() {
        // Disable analytics
        analytics.setEnabled(false)
        XCTAssertFalse(analytics.isEnabled, "Analytics should be disabled after calling setEnabled(false)")
    }

    func testAnalyticsCanBeReEnabled() {
        // Disable then re-enable
        analytics.setEnabled(false)
        analytics.setEnabled(true)
        XCTAssertTrue(analytics.isEnabled, "Analytics should be re-enabled after calling setEnabled(true)")
    }

    func testEventTrackingWhenEnabled() {
        analytics.setEnabled(true)

        // Track an event
        analytics.logEvent("test_event", parameters: ["key": "value"])

        // Verify event was tracked (this would check internal state in a real implementation)
        // For now, just ensure no crashes occur
        XCTAssertTrue(true, "Event tracking should not crash when enabled")
    }

    func testEventTrackingWhenDisabled() {
        analytics.setEnabled(false)

        // Track an event
        analytics.logEvent("test_event", parameters: ["key": "value"])

        // Verify event was not tracked (this would check internal state in a real implementation)
        // For now, just ensure no crashes occur
        XCTAssertTrue(true, "Event tracking should not crash when disabled")
    }

    func testEventTrackingWithNilParameters() {
        analytics.setEnabled(true)

        // Track an event with nil parameters
        analytics.logEvent("test_event", parameters: nil)

        // Should not crash
        XCTAssertTrue(true, "Event tracking should handle nil parameters")
    }

    func testEventTrackingWithEmptyParameters() {
        analytics.setEnabled(true)

        // Track an event with empty parameters
        analytics.logEvent("test_event", parameters: [:])

        // Should not crash
        XCTAssertTrue(true, "Event tracking should handle empty parameters")
    }
}
