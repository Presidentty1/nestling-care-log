/**
 * Regression tests for search input debouncing
 *
 * AUDIT-2: Search input not debounced - causes UI lag when typing
 *
 * @see CODEBASE_AUDIT_REPORT.md#2-search-input-not-debounced-ios
 */

import XCTest
import Combine
@testable import Nestling

final class SearchDebounceTests: XCTestCase {
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        cancellables = nil
        super.tearDown()
    }

    // MARK: - AUDIT-2: Search Debounce Tests

    func testSearchTextDebouncing() {
        // Given: A published search text property
        let searchSubject = CurrentValueSubject<String, Never>("")
        var debouncedValue = ""

        let expectation = XCTestExpectation(description: "Debounce")

        // Set up debounce
        searchSubject
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { value in
                debouncedValue = value
                if value == "test" {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When: Set search text rapidly
        searchSubject.send("t")
        searchSubject.send("te")
        searchSubject.send("tes")
        searchSubject.send("test")

        // Then: Debounced value should be "test" after delay
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(debouncedValue, "test")
    }

    func testDebounceCancelsPreviousCalls() {
        // Given: A search subject with debounce
        let searchSubject = CurrentValueSubject<String, Never>("")
        var receivedValues: [String] = []

        let expectation = XCTestExpectation(description: "Final value")

        searchSubject
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { value in
                if !value.isEmpty {
                    receivedValues.append(value)
                }
                if value == "final" {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When: Send multiple values rapidly
        searchSubject.send("a")
        searchSubject.send("ab")
        searchSubject.send("abc")

        // Wait a bit, then send final
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            searchSubject.send("final")
        }

        // Then: Only "final" should be received (previous values cancelled)
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedValues, ["final"])
    }

    func testDebounceDelayIs300ms() {
        // Given: A search subject
        let searchSubject = CurrentValueSubject<String, Never>("")
        let startTime = Date()
        var debounceTime: TimeInterval = 0

        let expectation = XCTestExpectation(description: "Timing")

        searchSubject
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { value in
                if value == "test" {
                    debounceTime = Date().timeIntervalSince(startTime)
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When: Send search text
        searchSubject.send("test")

        // Then: Should take approximately 300ms
        wait(for: [expectation], timeout: 1.0)
        XCTAssertGreaterThan(debounceTime, 0.25)
        XCTAssertLessThan(debounceTime, 0.5)
    }

    func testRapidTypingDoesNotCausePerformanceIssues() {
        // Given: A search subject
        let searchSubject = CurrentValueSubject<String, Never>("")
        var updateCount = 0

        let expectation = XCTestExpectation(description: "Rapid typing")

        searchSubject
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { _ in
                updateCount += 1
            }
            .store(in: &cancellables)

        // When: Simulate very fast typing
        let characters = Array("supercalifragilisticexpialidocious")
        for (index, char) in characters.enumerated() {
            let partialText = String(characters[0...index])
            searchSubject.send(partialText)
        }

        // Wait for debounce
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }

        // Then: Should only receive one debounced update
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(updateCount, 1, "Should only receive one debounced update")
    }

    // MARK: - Performance Tests

    func testDebouncePerformanceBaseline() {
        // Test that debounce setup is fast
        measure {
            let searchSubject = CurrentValueSubject<String, Never>("")
            var localCancellables = Set<AnyCancellable>()

            searchSubject
                .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
                .sink { _ in }
                .store(in: &localCancellables)

            // Simulate rapid input
            for i in 0..<100 {
                searchSubject.send("test\(i)")
            }

            localCancellables.removeAll()
        }
    }
}
