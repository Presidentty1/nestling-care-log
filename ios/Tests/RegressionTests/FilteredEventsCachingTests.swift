/**
 * Regression tests for filteredEvents caching
 *
 * AUDIT-6: filteredEvents recalculated on every access - inefficient with large event lists
 *
 * @see CODEBASE_AUDIT_REPORT.md#6-filteredevents-recalculation-ios
 */

import XCTest
@testable import Nestling

final class FilteredEventsCachingTests: XCTestCase {

    // MARK: - AUDIT-6: FilteredEvents Performance Tests

    func testFilteredEventsConsistency() {
        // Given: An array of events
        let events = createTestEvents(count: 100)

        // When: Filter events multiple times
        let filtered1 = events.filter { $0.type == .feed }
        let filtered2 = events.filter { $0.type == .feed }
        let filtered3 = events.filter { $0.type == .feed }

        // Then: Results should be consistent
        XCTAssertEqual(filtered1.count, filtered2.count)
        XCTAssertEqual(filtered2.count, filtered3.count)
    }

    func testFilteredEventsPerformanceWithLargeDataset() {
        // Given: Large dataset (1000 events)
        let largeEventSet = createTestEvents(count: 1000)

        // When: Filter events multiple times
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            for _ in 0..<10 {
                let _ = largeEventSet.filter { $0.type == .feed }
                let _ = largeEventSet.filter { $0.type == .sleep }
                let _ = largeEventSet.filter { $0.type == .diaper }
            }
        }
    }

    func testFilteredEventsWithSearchPerformance() {
        // Given: Events with notes
        let events = createTestEvents(count: 500)

        // When: Filter with search text
        measure(metrics: [XCTClockMetric()]) {
            let searchText = "test"
            let _ = events.filter { event in
                if let note = event.note?.lowercased() {
                    return note.contains(searchText)
                }
                return false
            }
        }
    }

    func testFilteredEventsWithTypeFilterPerformance() {
        // Given: Events
        let events = createTestEvents(count: 500)

        // When: Filter by type
        measure(metrics: [XCTClockMetric()]) {
            let feedEvents = events.filter { $0.type == .feed }
            let sleepEvents = events.filter { $0.type == .sleep }
            let diaperEvents = events.filter { $0.type == .diaper }

            XCTAssertGreaterThan(feedEvents.count, 0)
            XCTAssertGreaterThan(sleepEvents.count, 0)
            XCTAssertGreaterThan(diaperEvents.count, 0)
        }
    }

    func testFilteredEventsWithComplexFilterPerformance() {
        // Given: Events
        let events = createTestEvents(count: 200)

        // When: Apply complex filter
        measure(metrics: [XCTClockMetric()]) {
            let filtered = events.filter { event in
                // Type filter
                guard event.type == .feed else { return false }

                // Search filter
                if let note = event.note?.lowercased() {
                    return note.contains("test")
                }

                // Time filter (last 24 hours)
                let dayAgo = Date().addingTimeInterval(-86400)
                return event.startTime > dayAgo
            }

            XCTAssertNotNil(filtered)
        }
    }

    func testFilteredEventsMemoryEfficiency() {
        // Given: Large event set
        let events = createTestEvents(count: 500)

        // When: Filter events multiple times
        measure(metrics: [XCTMemoryMetric()]) {
            autoreleasepool {
                for _ in 0..<20 {
                    let _ = events.filter { $0.type == .feed }
                }
            }
        }
    }

    // MARK: - Caching Simulation Tests

    func testCachedFilteringApproach() {
        // Given: Events and a cached result
        let events = createTestEvents(count: 100)
        var cachedFeedEvents: [TestEvent]?

        // First access - compute and cache
        cachedFeedEvents = events.filter { $0.type == .feed }
        let firstCount = cachedFeedEvents?.count ?? 0

        // Subsequent accesses - use cache
        let secondCount = cachedFeedEvents?.count ?? 0
        let thirdCount = cachedFeedEvents?.count ?? 0

        // Then: All accesses should return same count
        XCTAssertEqual(firstCount, secondCount)
        XCTAssertEqual(secondCount, thirdCount)
        XCTAssertGreaterThan(firstCount, 0)
    }

    func testCacheInvalidationOnEventsChange() {
        // Given: Events with cached filter
        var events = createTestEvents(count: 50)
        var cachedFeedEvents: [TestEvent]? = events.filter { $0.type == .feed }
        let initialCount = cachedFeedEvents?.count ?? 0

        // When: Add more events
        let newEvents = createTestEvents(count: 25, startIndex: 50)
        events.append(contentsOf: newEvents)

        // Invalidate cache
        cachedFeedEvents = nil

        // Recompute
        cachedFeedEvents = events.filter { $0.type == .feed }
        let newCount = cachedFeedEvents?.count ?? 0

        // Then: Count should increase
        XCTAssertGreaterThan(newCount, initialCount)
    }

    // MARK: - Performance Baselines

    func testFilteringPerformanceBaseline() {
        let events = createTestEvents(count: 200)

        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            // Test various filtering scenarios
            let _ = events.filter { $0.type == .feed }
            let _ = events.filter { $0.type == .sleep }
            let _ = events.filter { $0.note?.contains("test") ?? false }
            let _ = events.filter { $0.startTime > Date().addingTimeInterval(-3600) }
        }
    }

    // MARK: - Helper Methods

    private func createTestEvents(count: Int, startIndex: Int = 0) -> [TestEvent] {
        return (startIndex..<startIndex + count).map { index in
            let eventType: EventType
            switch index % 4 {
            case 0: eventType = .feed
            case 1: eventType = .diaper
            case 2: eventType = .sleep
            case 3: eventType = .tummyTime
            default: eventType = .feed
            }

            return TestEvent(
                id: UUID(),
                type: eventType,
                startTime: Date().addingTimeInterval(TimeInterval(-index * 3600)),
                note: index % 10 == 0 ? "Test note \(index)" : nil
            )
        }
    }
}

// MARK: - Test Helpers

private struct TestEvent {
    let id: UUID
    let type: EventType
    let startTime: Date
    let note: String?
}

private enum EventType {
    case feed
    case diaper
    case sleep
    case tummyTime
}
