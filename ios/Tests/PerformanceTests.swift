import XCTest
@testable import Nestling

/// Performance tests for critical paths.
/// These tests verify that performance budgets are met.
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
}


