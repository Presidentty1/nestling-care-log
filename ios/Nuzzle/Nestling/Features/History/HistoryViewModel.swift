import Foundation
import Combine

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var selectedDate: Date = {
        let calendar = Calendar.current
        return calendar.startOfDay(for: Date())
    }()
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText: String = ""
    @Published var selectedFilter: EventTypeFilter = .all
    @Published var eventCountsByDate: [Date: EventDayCounts] = [:]
    @Published var useCalendarView: Bool = true // Toggle between calendar and 7-day strip
    
    private let dataStore: DataStore
    let baby: Baby // Made internal so HistoryView can check if baby changed
    private var isLoadingTask: Task<Void, Never>?
    
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
                
                // Natural language queries
                let naturalLanguagePatterns: [(pattern: String, type: EventType?)] = [
                    ("feed", .feed),
                    ("bottle", .feed),
                    ("breast", .feed),
                    ("nurse", .feed),
                    ("diaper", .diaper),
                    ("poop", .diaper),
                    ("poo", .diaper),
                    ("wet", .diaper),
                    ("dirty", .diaper),
                    ("nap", .sleep),
                    ("sleep", .sleep),
                    ("bedtime", .sleep),
                    ("tummy", .tummyTime),
                    ("tummy time", .tummyTime)
                ]
                
                for (pattern, eventType) in naturalLanguagePatterns {
                    if query.contains(pattern) {
                        if let eventType = eventType, event.type == eventType {
                            return true
                        }
                    }
                }
                
                // Search for "last" queries (e.g., "last poop", "last feed")
                if query.contains("last") {
                    // Sort by most recent and return first match
                    let sortedEvents = filtered.sorted { $0.startTime > $1.startTime }
                    if let firstMatch = sortedEvents.first(where: { event in
                        for (pattern, eventType) in naturalLanguagePatterns {
                            if query.contains(pattern) {
                                if let eventType = eventType, event.type == eventType {
                                    return true
                                }
                            }
                        }
                        return false
                    }) {
                        return event.id == firstMatch.id
                    }
                }
                
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
        print("HistoryViewModel.init: Created for baby \(baby.id)")
        Task { @MainActor in
            await loadEvents()
        }
    }
    
    deinit {
        print("HistoryViewModel.deinit: Cleaning up for baby \(baby.id)")
        isLoadingTask?.cancel()
        Task { @MainActor in
            self.isLoading = false
        }
    }
    
    func loadEvents() async {
        // Cancel any existing load task first
        isLoadingTask?.cancel()
        isLoadingTask = nil
        
        print("HistoryViewModel.loadEvents called for baby: \(baby.id), date: \(selectedDate)")
        isLoading = true
        errorMessage = nil
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { @MainActor in
                await self.loadEventsInternal()
            }
        }
    }
    
    private func loadEventsInternal() async {
        isLoadingTask = Task { @MainActor in
            print("Starting fetchEvents task...")
            let startTime = Date()
            let taskID = UUID()
            print("Task ID: \(taskID)")
            
            // Add timeout to prevent infinite loading
            let timeoutTask = Task {
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                await MainActor.run {
                    if self.isLoading && !Task.isCancelled {
                        let elapsed = Date().timeIntervalSince(startTime)
                        print("ERROR [\(taskID)]: loadEvents timed out after \(elapsed) seconds")
                        self.isLoading = false
                        self.errorMessage = "Loading took too long. Please try again."
                    }
                }
            }
            
            do {
                print("[\(taskID)] Calling dataStore.fetchEvents for date: \(selectedDate)")
                let dayEvents = try await dataStore.fetchEvents(for: baby, on: selectedDate)
                
                // Check if task was cancelled
                if Task.isCancelled {
                    print("[\(taskID)] loadEvents was cancelled after fetch")
                    timeoutTask.cancel()
                    self.isLoading = false
                    return
                }
                
                timeoutTask.cancel()
                
                let elapsed = Date().timeIntervalSince(startTime)
                print("[\(taskID)] fetchEvents completed in \(elapsed) seconds, got \(dayEvents.count) events")
                
                self.events = dayEvents
                self.isLoading = false
                print("[\(taskID)] UI updated with \(dayEvents.count) events, isLoading = false")
                
                // Index events in Spotlight (non-blocking)
                Task {
                    if let settings = try? await dataStore.fetchAppSettings() {
                        SpotlightIndexer.shared.indexEvents(dayEvents, for: baby, settings: settings)
                    }
                }
            } catch {
                if Task.isCancelled {
                    print("[\(taskID)] loadEvents was cancelled during error handling")
                    timeoutTask.cancel()
                    self.isLoading = false
                    return
                }
                
                timeoutTask.cancel()
                let elapsed = Date().timeIntervalSince(startTime)
                print("[\(taskID)] ERROR: fetchEvents failed after \(elapsed) seconds: \(error)")
                self.errorMessage = "Failed to load events: \(error.localizedDescription)"
                self.isLoading = false
                print("[\(taskID)] Error set, isLoading = false")
            }
            
            self.isLoadingTask = nil
        }
        
        await isLoadingTask?.value
    }
    
    func selectDate(_ date: Date) {
        let calendar = Calendar.current
        selectedDate = calendar.startOfDay(for: date)
        Task {
            await loadEvents()
        }
    }
    
    func deleteEvent(_ event: Event) async {
        Task {
            do {
                // Store event for potential undo
                let eventToDelete = event
                
                // Remove from Spotlight index
                SpotlightIndexer.shared.removeEvent(event)
                
                try await dataStore.deleteEvent(event)
                
                // Register for undo
                UndoManager.shared.registerDeletion(event: eventToDelete) { [weak self] in
                    guard let self = self else { return }
                    try await self.dataStore.addEvent(eventToDelete)
                    await MainActor.run {
                        Task {
                            await self.loadEvents()
                        }
                    }
                }
                
                await MainActor.run {
                    Task {
                        await loadEvents()
                    }
                }
            } catch {
                errorMessage = "Failed to delete event: \(error.localizedDescription)"
            }
        }
    }
    
    func undoDeletion() async throws {
        try await UndoManager.shared.undo()
        await loadEvents()
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
                    startTime: Date(), // Use current time
                    endTime: event.durationMinutes.map { Date().addingTimeInterval(TimeInterval($0 * 60)) },
                    amount: event.amount,
                    unit: event.unit,
                    side: event.side,
                    note: event.note,
                    createdAt: Date(),
                    updatedAt: Date()
                )
                
                try await dataStore.addEvent(duplicatedEvent)
                Haptics.success()
                await loadEvents()
            } catch {
                Haptics.error()
                errorMessage = "Failed to duplicate event: \(error.localizedDescription)"
            }
        }
    }
    
    /// Load event counts for calendar view (entire month)
    func loadEventCountsForMonth(_ month: Date) async {
        let calendar = Calendar.current
        guard let monthStart = calendar.dateComponents([.year, .month], from: month).date,
              let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else {
            return
        }
        
        do {
            let allEventsInMonth = try await dataStore.fetchEvents(
                for: baby,
                from: monthStart,
                to: monthEnd
            )
            
            // Group events by date and count by type
            var countsByDate: [Date: EventDayCounts] = [:]
            for event in allEventsInMonth {
                let eventDate = calendar.startOfDay(for: event.startTime)
                var counts = countsByDate[eventDate] ?? EventDayCounts()
                
                switch event.type {
                case .feed:
                    counts.feeds += 1
                case .sleep:
                    counts.sleep += 1
                case .diaper:
                    counts.diapers += 1
                case .tummyTime:
                    counts.tummyTime += 1
                }
                
                countsByDate[eventDate] = counts
            }
            
            await MainActor.run {
                self.eventCountsByDate = countsByDate
            }
        } catch {
            print("Error loading event counts for month: \(error)")
        }
    }
}

// MARK: - Event Day Counts

struct EventDayCounts {
    var feeds: Int = 0
    var sleep: Int = 0
    var diapers: Int = 0
    var tummyTime: Int = 0
}

