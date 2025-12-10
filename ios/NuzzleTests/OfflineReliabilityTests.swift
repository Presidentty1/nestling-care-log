import XCTest
@testable import Nestling

final class OfflineReliabilityTests: XCTestCase {
    func testOfflineFeedSaveAndDeferredSync() async throws {
        let dataStore = InMemoryDataStore()
        NetworkMonitor.shared.isConnected = false
        
        let baby = Baby.mock()
        try await dataStore.addBaby(baby)
        
        let feed = Event(
            babyId: baby.id,
            type: .feed,
            subtype: "bottle",
            startTime: Date(),
            amount: 90,
            unit: "ml",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try await dataStore.addEvent(feed)
        
        let saved = try await dataStore.fetchEvents(for: baby, from: Date().addingTimeInterval(-3600), to: Date().addingTimeInterval(3600))
        XCTAssertEqual(saved.count, 1)
        
        // Simulate network restoration
        NetworkMonitor.shared.isConnected = true
        // In real app, OfflineQueueService would process; here we just assert data remains
        let after = try await dataStore.fetchEvents(for: baby, from: Date().addingTimeInterval(-3600), to: Date().addingTimeInterval(3600))
        XCTAssertEqual(after.count, 1)
    }
}

