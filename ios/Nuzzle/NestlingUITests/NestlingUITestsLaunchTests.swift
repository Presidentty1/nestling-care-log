//
//  NestlingUITestsLaunchTests.swift
//  NestlingUITests
//
//  Stub to satisfy legacy references.
//

import XCTest

final class LegacyNestlingUITestsLaunchTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.state == .runningForeground || app.state == .runningBackground)
    }
}
