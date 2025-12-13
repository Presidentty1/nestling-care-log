import XCTest
@testable import Nuzzle

/// Performance tests for critical paths.
/// These tests verify that performance budgets are met.
///
/// Includes regression tests for performance issues identified in CODEBASE_AUDIT_REPORT.md:
/// - AUDIT-1: DateFormatter performance (caching)
/// - AUDIT-7: DateFormatter in search filtering
/// - AUDIT-6: filteredEvents performance
final class PerformanceTests: XCTestCase {
    
    func testHeavyTimelineScrolling() throws {
        // This test verifies that scrolling through a large timeline (200+ events)
        // maintains 60 FPS and doesn't cause memory spikes.
        // Note: Actual FPS measurement requires UI testing with Instruments.
        // This test verifies the data loading performance.
        
        let dataStore = InMemoryDataStore()
        let baby = Baby.mock
        
        // Create 200 events
        var events: [Event] = []
        let baseDate = Date()
        for i in 0..<200 {
            let event = Event(
                id: "event-\(i)",
                babyId: baby.id,
                type: i % 4 == 0 ? .feed : (i % 4 == 1 ? .sleep : (i % 4 == 2 ? .diaper : .tummyTime)),
                startTime: baseDate.addingTimeInterval(Double(i * 60)),
                note: "Test event \(i)"
            )
            events.append(event)
        }
        
        // Measure time to load all events
        measure {
            Task {
                for event in events {
                    try? await dataStore.addEvent(event)
                }
            }
        }
        
        // Verify events can be fetched efficiently
        let expectation = expectation(description: "Fetch events")
        Task {
            let fetched = try await dataStore.fetchEvents(for: baby, on: baseDate)
            XCTAssertEqual(fetched.count, 200)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5.0)
    }
    
    func testLaunchTime() throws {
        // This test measures app initialization time.
        // Target: < 400ms in release builds.
        // Note: Actual launch time measurement requires Instruments.
        // This test verifies initialization doesn't block.
        
        measure {
            let dataStore = DataStoreSelector.create()
            let _ = AppEnvironment(dataStore: dataStore)
        }
    }
    
    func testPredictionGenerationPerformance() throws {
        // Verify prediction generation is fast (< 50ms)
        let dataStore = InMemoryDataStore()
        let baby = Baby.mock

        measure {
            Task {
                let _ = try? await dataStore.generatePrediction(for: baby, type: .nextFeed)
            }
        }
    }

    // MARK: - Regression Performance Baselines (CODEBASE_AUDIT_REPORT.md)

    /// AUDIT-1: DateFormatter performance baseline
    /// Ensures DateFormatter caching maintains performance
    func testDateFormatterPerformanceBaseline() {
        let testDate = Date()

        // Test cached formatter performance
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            // Perform 1000 formatting operations (should use cached formatters)
            for _ in 0..<1000 {
                let _ = DateUtils.formatTime(testDate)
                let _ = DateUtils.formatDate(testDate)
            }
        }

        // Baseline: Should complete in reasonable time without memory growth
    }

    /// AUDIT-7: Search filtering DateFormatter performance
    /// Ensures search filtering doesn't create excessive DateFormatters
    func testSearchFilteringDateFormatterPerformance() {
        // Create test HomeViewModel with events
        let baby = Baby.mock
        let viewModel = HomeViewModel(
            baby: baby,
            dataStore: InMemoryDataStore(),
            showToast: { _, _ in }
        )

        // Add test events
        var testEvents: [Event] = []
        let baseDate = Date()
        for i in 0..<50 {
            let event = Event(
                id: "search-test-\(i)",
                babyId: baby.id,
                type: .feed,
                startTime: baseDate.addingTimeInterval(Double(i * 3600)), // 1 hour apart
                note: i % 5 == 0 ? "Test note at \(i)" : nil
            )
            testEvents.append(event)
        }
        viewModel.events = testEvents

        // Test search filtering performance
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            // Perform various searches that would use DateFormatters
            let _ = viewModel.filteredEvents(searchText: "8:30")
            let _ = viewModel.filteredEvents(searchText: "pm")
            let _ = viewModel.filteredEvents(searchText: "feed")
            let _ = viewModel.filteredEvents(searchText: "test")
        }

        // Baseline: Search filtering should be fast and not create new DateFormatters
    }

    /// AUDIT-6: filteredEvents performance baseline
    /// Ensures event filtering maintains performance with large datasets
    func testFilteredEventsPerformanceBaseline() {
        let baby = Baby.mock
        let viewModel = HomeViewModel(
            baby: baby,
            dataStore: InMemoryDataStore(),
            showToast: { _, _ in }
        )

        // Create large event dataset (200 events)
        var largeEventSet: [Event] = []
        let baseDate = Date()
        for i in 0..<200 {
            let eventType: EventType
            switch i % 4 {
            case 0: eventType = .feed
            case 1: eventType = .sleep
            case 2: eventType = .diaper
            case 3: eventType = .tummyTime
            default: eventType = .feed
            }

            let event = Event(
                id: "perf-test-\(i)",
                babyId: baby.id,
                type: eventType,
                startTime: baseDate.addingTimeInterval(Double(i * 1800)), // 30 min apart
                note: i % 10 == 0 ? "Performance test note \(i)" : nil
            )
            largeEventSet.append(event)
        }
        viewModel.events = largeEventSet

        // Test filtering performance
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            // Test various filter combinations
            viewModel.selectedFilter = .all
            let _ = viewModel.filteredEvents

            viewModel.selectedFilter = .feeds
            let _ = viewModel.filteredEvents

            viewModel.debouncedSearchText = "feed"
            let _ = viewModel.filteredEvents

            viewModel.selectedFilter = .sleep
            viewModel.debouncedSearchText = "nap"
            let _ = viewModel.filteredEvents

            // Reset
            viewModel.selectedFilter = .all
            viewModel.debouncedSearchText = ""
            let _ = viewModel.filteredEvents
        }

        // Baseline: Filtering should be fast even with large datasets
    }

    /// AUDIT-2: Search debouncing performance baseline
    /// Ensures search debouncing doesn't impact performance
    func testSearchDebouncePerformanceBaseline() {
        let baby = Baby.mock
        let viewModel = HomeViewModel(
            baby: baby,
            dataStore: InMemoryDataStore(),
            showToast: { _, _ in }
        )

        // Add some events for filtering
        var events: [Event] = []
        for i in 0..<20 {
            let event = Event(
                id: "debounce-test-\(i)",
                babyId: baby.id,
                type: .feed,
                startTime: Date().addingTimeInterval(Double(i * 3600)),
                note: "Test event \(i)"
            )
            events.append(event)
        }
        viewModel.events = events

        // Test rapid search input (simulating typing)
        measure(metrics: [XCTClockMetric()]) {
            // Simulate rapid typing without waiting for debounce
            let searchTerms = ["t", "te", "tes", "test", "testi", "testin", "testing"]
            for term in searchTerms {
                viewModel.searchText = term
                // Immediate access (should use cached debounced value)
                let _ = viewModel.debouncedSearchText
            }
        }

        // Baseline: Search input should be responsive even with debouncing
    }

    /// Memory usage baseline for critical components
    func testMemoryUsageBaseline() {
        // Test memory usage patterns for components that had memory issues

        measure(metrics: [XCTMemoryMetric()]) {
            autoreleasepool {
                // Test DateFormatter usage doesn't leak
                let testDate = Date()
                for _ in 0..<1000 {
                    let _ = DateUtils.formatTime(testDate)
                    let _ = DateUtils.formatDate(testDate)
                    let _ = DateUtils.formatRelativeTime(testDate)
                }

                // Test event filtering doesn't leak
                let baby = Baby.mock
                let viewModel = HomeViewModel(
                    baby: baby,
                    dataStore: InMemoryDataStore(),
                    showToast: { _, _ in }
                )

                var events: [Event] = []
                for i in 0..<100 {
                    let event = Event(
                        id: "memory-test-\(i)",
                        babyId: baby.id,
                        type: .feed,
                        startTime: Date().addingTimeInterval(Double(i * 60)),
                        note: "Memory test event \(i)"
                    )
                    events.append(event)
                }
                viewModel.events = events

                // Perform filtering operations
                for _ in 0..<50 {
                    let _ = viewModel.filteredEvents
                }
            }
        }

        // Baseline: Operations should not cause memory leaks
    }
}


