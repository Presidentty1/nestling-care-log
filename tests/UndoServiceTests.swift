import XCTest
@testable import Nuzzle

final class UndoServiceTests: XCTestCase {
    var undoService: UndoService!

    override func setUp() {
        super.setUp()
        undoService = UndoService.shared
    }

    func testOfferUndo() async {
        let expectation = XCTestExpectation(description: "Undo action executed")

        undoService.offerUndo(message: "Test undo", duration: 1) {
            expectation.fulfill()
        }

        XCTAssertTrue(undoService.hasUndo)
        XCTAssertNotNil(undoService.currentUndo)

        // Wait for undo to execute
        await fulfillment(of: [expectation], timeout: 2)

        // Should be cleared after execution
        XCTAssertFalse(undoService.hasUndo)
    }

    func testUndoExpiration() async {
        undoService.offerUndo(message: "Test undo", duration: 0.1) {
            XCTFail("Should not execute expired undo")
        }

        XCTAssertTrue(undoService.hasUndo)

        // Wait for expiration
        try? await Task.sleep(for: .seconds(0.2))

        XCTAssertFalse(undoService.hasUndo)
    }

    func testDismissUndo() {
        undoService.offerUndo(message: "Test undo", duration: 5) {
            XCTFail("Should not execute dismissed undo")
        }

        XCTAssertTrue(undoService.hasUndo)

        undoService.dismiss()

        XCTAssertFalse(undoService.hasUndo)
    }

    func testTimeRemaining() {
        undoService.offerUndo(message: "Test undo", duration: 2) {}

        XCTAssertTrue(undoService.timeRemaining! <= 2)
        XCTAssertTrue(undoService.timeRemaining! > 0)
    }
}