import XCTest
@testable import Nestling

final class DataStoreTests: XCTestCase {
    var dataStore: InMemoryDataStore!
    
    override func setUp() {
        super.setUp()
        dataStore = InMemoryDataStore()
    }
    
    func testAddEvent() async throws {
        let baby = Baby.mock()
        let event = Event.mockFeed(babyId: baby.id)
        
        try await dataStore.addEvent(event)
        let events = try await dataStore.fetchEvents(for: baby, on: Date())
        
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.id, event.id)
    }
    
    func testUpdateEvent() async throws {
        let baby = Baby.mock()
        var event = Event.mockFeed(babyId: baby.id, amount: 100)
        
        try await dataStore.addEvent(event)
        event = Event(id: event.id, babyId: event.babyId, type: event.type, amount: 150)
        
        try await dataStore.updateEvent(event)
        let events = try await dataStore.fetchEvents(for: baby, on: Date())
        
        XCTAssertEqual(events.first?.amount, 150)
    }
    
    func testDeleteEvent() async throws {
        let baby = Baby.mock()
        let event = Event.mockFeed(babyId: baby.id)
        
        try await dataStore.addEvent(event)
        try await dataStore.deleteEvent(event)
        let events = try await dataStore.fetchEvents(for: baby, on: Date())
        
        XCTAssertEqual(events.count, 0)
    }
    
    func testActiveSleepFlow() async throws {
        let baby = Baby.mock()
        
        // Start sleep
        let activeSleep = try await dataStore.startActiveSleep(for: baby)
        XCTAssertNotNil(activeSleep.endTime == nil)
        
        // Get active sleep
        let retrieved = try await dataStore.getActiveSleep(for: baby)
        XCTAssertEqual(retrieved?.id, activeSleep.id)
        
        // Stop sleep
        let completed = try await dataStore.stopActiveSleep(for: baby)
        XCTAssertNotNil(completed.endTime)
        
        // Verify no active sleep
        let afterStop = try await dataStore.getActiveSleep(for: baby)
        XCTAssertNil(afterStop)
    }
}


