import Foundation

protocol HistoryDataProvider {
    func fetchEvents(for baby: Baby, from: Date, to: Date) async throws -> [Event]
}

final class DefaultHistoryDataProvider: HistoryDataProvider {
    private let dataStore: DataStore

    init(dataStore: DataStore) {
        self.dataStore = dataStore
    }

    func fetchEvents(for baby: Baby, from: Date, to: Date) async throws -> [Event] {
        try await dataStore.fetchEvents(for: baby, from: from, to: to)
    }
}

final class MockHistoryDataProvider: HistoryDataProvider {
    func fetchEvents(for baby: Baby, from: Date, to: Date) async throws -> [Event] {
        var events: [Event] = []
        let calendar = Calendar.current
        let now = Date()
        let babyId = baby.id

        // Generate 7 days of sample events: sleeps, feeds, diapers, cry
        for dayOffset in 0..<7 {
            guard let dayStart = calendar.date(byAdding: .day, value: -dayOffset, to: calendar.startOfDay(for: now)) else { continue }
            let morningFeed = Event(babyId: babyId, type: .feed, subtype: "bottle", startTime: dayStart.addingTimeInterval(8 * 3600), amount: 120, unit: "ml", note: "Finished quickly")
            let diaper = Event(babyId: babyId, type: .diaper, subtype: dayOffset % 2 == 0 ? "wet" : "dirty", startTime: dayStart.addingTimeInterval(9 * 3600))
            let napStart = dayStart.addingTimeInterval(10 * 3600)
            let nap = Event(babyId: babyId, type: .sleep, subtype: "nap", startTime: napStart, endTime: napStart.addingTimeInterval(45 * 60))
            let cry = Event(babyId: babyId, type: .cry, startTime: dayStart.addingTimeInterval(12 * 3600), endTime: dayStart.addingTimeInterval(12 * 3600 + 120), note: "Fussy before nap")

            events.append(contentsOf: [morningFeed, diaper, nap, cry])
        }

        return events
    }
}



