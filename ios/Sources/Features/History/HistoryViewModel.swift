import Foundation

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var selectedDate: Date = Date()
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText: String = ""
    @Published var selectedFilter: EventTypeFilter = .all
    
    private let dataStore: DataStore
    private let baby: Baby
    
    /// Filtered events based on search text and selected filter
    var filteredEvents: [Event] {
        var filtered = events
        
        // Apply type filter
        if selectedFilter != .all {
            filtered = filtered.filter { event in
                switch selectedFilter {
                case .all: return true
                case .feeds: return event.type == .feed
                case .diapers: return event.type == .diaper
                case .sleep: return event.type == .sleep
                case .tummy: return event.type == .tummyTime
                }
            }
        }
        
        // Apply search text
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            filtered = filtered.filter { event in
                // Search in type name
                if event.type.displayName.lowercased().contains(query) {
                    return true
                }
                
                // Search in note
                if let note = event.note?.lowercased(), note.contains(query) {
                    return true
                }
                
                // Search for type keywords
                if query.contains("feed") && event.type == .feed { return true }
                if query.contains("diaper") && event.type == .diaper { return true }
                if query.contains("nap") && event.type == .sleep { return true }
                if query.contains("sleep") && event.type == .sleep { return true }
                if query.contains("tummy") && event.type == .tummyTime { return true }
                
                // Search for time tokens (e.g., "8:30", "pm")
                let timeFormatter = DateFormatter()
                timeFormatter.timeStyle = .short
                let timeString = timeFormatter.string(from: event.startTime).lowercased()
                if timeString.contains(query) {
                    return true
                }
                
                return false
            }
        }
        
        return filtered
    }
    
    /// Get daily summary for selected date
    var dailySummary: DailySummary? {
        calculateDailySummary(from: events)
    }

    /// Get search suggestions based on recent notes
    var searchSuggestions: [String] {
        var suggestions: [String] = []
        
        // Canned suggestions
        suggestions.append(contentsOf: ["feeds", "diapers", "naps", "tummy"])
        
        // Extract last 5 unique note terms
        let noteTerms = events.compactMap { $0.note?.lowercased() }
            .flatMap { $0.components(separatedBy: .whitespacesAndNewlines) }
            .filter { $0.count > 2 }
            .prefix(5)
        
        suggestions.append(contentsOf: Array(Set(noteTerms)))
        
        return Array(suggestions.prefix(5))
    }
    
    init(dataStore: DataStore, baby: Baby) {
        self.dataStore = dataStore
        self.baby = baby
        loadEvents()
    }
    
    func loadEvents() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let dayEvents = try await dataStore.fetchEvents(for: baby, on: selectedDate)
                self.events = dayEvents
                
                // Index events in Spotlight
                if let settings = try? await dataStore.fetchAppSettings() {
                    SpotlightIndexer.shared.indexEvents(dayEvents, for: baby, settings: settings)
                }
                
                self.isLoading = false
            } catch {
                self.errorMessage = "Failed to load events: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func selectDate(_ date: Date) {
        selectedDate = date
        loadEvents()
    }
    
    func deleteEvent(_ event: Event) {
        Task {
            do {
                // Store event for potential undo
                let eventToDelete = event
                try await dataStore.deleteEvent(event)
                
                // Register for undo
                UndoManager.shared.registerDeletion(event: eventToDelete) { [weak self] in
                    guard let self = self else { return }
                    try await self.dataStore.addEvent(eventToDelete)
                    await MainActor.run {
                        self.loadEvents()
                    }
                }
                
                await MainActor.run {
                    loadEvents()
                }
            } catch {
                errorMessage = "Failed to delete event: \(error.localizedDescription)"
            }
        }
    }
    
    func undoDeletion() async throws {
        try await UndoManager.shared.undo()
        loadEvents()
    }
    
    /// Duplicate an event with current time
    func duplicateEvent(_ event: Event) {
        Task {
            do {
                // Create a new event based on the original, but with current time
                let duplicatedEvent = Event(
                    id: IDGenerator.generate(),
                    babyId: event.babyId,
                    type: event.type,
                    subtype: event.subtype,
                    amount: event.amount,
                    unit: event.unit,
                    side: event.side,
                    startTime: Date(), // Use current time
                    endTime: event.durationMinutes.map { Date().addingTimeInterval(TimeInterval($0 * 60)) },
                    durationMinutes: event.durationMinutes,
                    note: event.note,
                    createdAt: Date(),
                    updatedAt: Date()
                )
                
                try await dataStore.addEvent(duplicatedEvent)
                Haptics.success()
                loadEvents()
            } catch {
                Haptics.error()
                errorMessage = "Failed to duplicate event: \(error.localizedDescription)"
            }
        }
    }

    private func calculateDailySummary(from events: [Event]) -> DailySummary {
        var feedCount = 0
        var diaperCount = 0
        var sleepCount = 0
        var totalSleepMinutes = 0
        var tummyTimeCount = 0

        for event in events {
            switch event.type {
            case .feed:
                feedCount += 1
            case .diaper:
                diaperCount += 1
            case .sleep:
                sleepCount += 1
                if let duration = event.durationMinutes {
                    totalSleepMinutes += duration
                }
            case .tummyTime:
                tummyTimeCount += 1
            }
        }

        return DailySummary(
            feedCount: feedCount,
            diaperCount: diaperCount,
            sleepCount: sleepCount,
            totalSleepMinutes: totalSleepMinutes,
            tummyTimeCount: tummyTimeCount
        )
    }
}

struct DailySummary {
    let feedCount: Int
    let diaperCount: Int
    let sleepCount: Int
    let totalSleepMinutes: Int
    let tummyTimeCount: Int

    var sleepHours: Int {
        totalSleepMinutes / 60
    }

    var sleepMinutes: Int {
        totalSleepMinutes % 60
    }

    var summaryText: String {
        var components: [String] = []

        if feedCount > 0 {
            components.append("\(feedCount) feed\(feedCount == 1 ? "" : "s")")
        }

        if diaperCount > 0 {
            components.append("\(diaperCount) diaper\(diaperCount == 1 ? "" : "s")")
        }

        if totalSleepMinutes > 0 {
            if sleepHours > 0 {
                if sleepMinutes > 0 {
                    components.append("\(sleepHours)h \(sleepMinutes)m sleep")
                } else {
                    components.append("\(sleepHours)h sleep")
                }
            } else {
                components.append("\(sleepMinutes)m sleep")
            }
        }

        if tummyTimeCount > 0 {
            components.append("\(tummyTimeCount) tummy time\(tummyTimeCount == 1 ? "" : "s")")
        }

        return components.joined(separator: " • ")
    }

    var isEmpty: Bool {
        feedCount == 0 && diaperCount == 0 && totalSleepMinutes == 0 && tummyTimeCount == 0
    }
}

