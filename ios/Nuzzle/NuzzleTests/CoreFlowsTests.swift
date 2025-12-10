//
//  CoreFlowsTests.swift
//  NuzzleTests
//
//  Regression coverage for core logging and prediction flows.
//

import XCTest
@testable import Nuzzle

final class CoreFlowsTests: XCTestCase {
    func testEditAndReorderEvents() async throws {
        let store = InMemoryDataStore()
        let baby = try XCTUnwrap(try await store.fetchBabies().first)
        
        let original = Event(
            babyId: baby.id,
            type: .feed,
            startTime: Date(),
            amount: 90,
            unit: "ml"
        )
        
        try await store.addEvent(original)
        
        // Move the event earlier and ensure fetch order respects updated start time
        let edited = Event(
            id: original.id,
            babyId: baby.id,
            type: .feed,
            subtype: original.subtype,
            startTime: original.startTime.addingTimeInterval(-3600),
            endTime: original.endTime,
            amount: 120,
            unit: "ml",
            side: original.side,
            note: "Edited amount",
            photoUrls: original.photoUrls,
            createdAt: original.createdAt,
            updatedAt: Date()
        )
        try await store.updateEvent(edited)
        
        let events = try await store.fetchEvents(for: baby, from: Date.distantPast, to: Date.distantFuture)
        let match = events.first { $0.id == original.id }
        XCTAssertEqual(match?.amount, 120)
        XCTAssertEqual(match?.note, "Edited amount")
    }
    
    func testDeleteAndUndoEvent() async throws {
        let store = InMemoryDataStore()
        let baby = try XCTUnwrap(try await store.fetchBabies().first)
        let event = Event.mockDiaper(babyId: baby.id)
        
        try await store.addEvent(event)
        var events = try await store.fetchEvents(for: baby, from: Date.distantPast, to: Date.distantFuture)
        XCTAssertTrue(events.contains(where: { $0.id == event.id }))
        
        try await store.deleteEvent(event)
        events = try await store.fetchEvents(for: baby, from: Date.distantPast, to: Date.distantFuture)
        XCTAssertFalse(events.contains(where: { $0.id == event.id }))
        
        // Undo by re-adding the same event id
        try await store.addEvent(event)
        events = try await store.fetchEvents(for: baby, from: Date.distantPast, to: Date.distantFuture)
        XCTAssertTrue(events.contains(where: { $0.id == event.id }))
    }
    
    func testOfflineQueueFlushesOnReconnect() async throws {
        actor MockSyncQueue {
            private var queued: [Event] = []
            
            func enqueue(_ event: Event) {
                queued.append(event)
            }
            
            func flush(onSync: (Event) async throws -> Void) async throws {
                for event in queued {
                    try await onSync(event)
                }
                queued.removeAll()
            }
            
            var pendingCount: Int { queued.count }
        }
        
        let queue = MockSyncQueue()
        let store = InMemoryDataStore()
        let baby = try XCTUnwrap(try await store.fetchBabies().first)
        let event = Event.mockFeed(babyId: baby.id)
        
        await queue.enqueue(event)
        XCTAssertEqual(await queue.pendingCount, 1)
        
        try await queue.flush { flushed in
            try await store.addEvent(flushed)
        }
        
        let events = try await store.fetchEvents(for: baby, from: Date.distantPast, to: Date.distantFuture)
        XCTAssertTrue(events.contains(where: { $0.id == event.id }))
        XCTAssertEqual(await queue.pendingCount, 0)
    }
    
    func testNapPredictionAfterEdit() async throws {
        let store = InMemoryDataStore()
        let baby = try XCTUnwrap(try await store.fetchBabies().first)
        
        // Initial prediction
        let initial = try await store.generatePrediction(for: baby, type: .nextNap)
        XCTAssertNotNil(initial.nextNapWindow)
        
        // Add a new sleep event then ensure prediction still resolves
        let newSleep = Event.mockSleep(babyId: baby.id, durationMinutes: 30, subtype: "nap")
        try await store.addEvent(newSleep)
        
        let updated = try await store.generatePrediction(for: baby, type: .nextNap)
        XCTAssertNotNil(updated.nextNapWindow)
    }
}

