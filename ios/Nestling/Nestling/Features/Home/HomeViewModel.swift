import Foundation
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var summary: DaySummary?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var activeSleep: Event?
    @Published var searchText: String = ""
    @Published var selectedFilter: EventTypeFilter = .all
    
    private let dataStore: DataStore
    let baby: Baby // Made internal so HomeView can check if baby changed
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
        print("HomeViewModel.init: Created for baby \(baby.id)")
        loadTodayEvents()
        checkActiveSleep()
    }
    
    deinit {
        print("HomeViewModel.deinit: Cleaning up for baby \(baby.id)")
        isLoadingTask?.cancel()
        Task { @MainActor in
            self.isLoading = false
        }
    }
    
    func checkActiveSleep() {
        Task {
            if let active = try? await dataStore.getActiveSleep(for: baby) {
                await MainActor.run {
                    self.activeSleep = active
                }
            }
        }
    }
    
    func loadTodayEvents() {
        // Cancel any existing load task first
        isLoadingTask?.cancel()
        isLoadingTask = nil
        
        print("loadTodayEvents called for baby: \(baby.id)")
        isLoading = true
        errorMessage = nil
        
        let signpostID = SignpostLogger.beginInterval("TimelineLoad", log: SignpostLogger.ui)
        
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
                        print("ERROR [\(taskID)]: loadTodayEvents timed out after \(elapsed) seconds")
                        self.isLoading = false
                        self.errorMessage = "Loading took too long. Please try again."
                    }
                }
            }
            
            do {
                print("[\(taskID)] Calling dataStore.fetchEvents for date: \(Date())")
                let todayEvents = try await dataStore.fetchEvents(for: baby, on: Date())
                
                // Check if task was cancelled
                if Task.isCancelled {
                    print("[\(taskID)] loadTodayEvents was cancelled after fetch")
                    timeoutTask.cancel()
                    // Ensure isLoading is reset even if cancelled
                    self.isLoading = false
                    return
                }
                
                timeoutTask.cancel()
                
                let elapsed = Date().timeIntervalSince(startTime)
                print("[\(taskID)] fetchEvents completed in \(elapsed) seconds, got \(todayEvents.count) events")
                
                // Update UI on MainActor (we're already on MainActor, but be explicit)
                self.events = todayEvents
                self.summary = calculateSummary(from: todayEvents)
                self.isLoading = false
                print("[\(taskID)] UI updated with \(todayEvents.count) events, isLoading = false")
                
                // Index events in Spotlight (non-blocking)
                Task {
                    if let settings = try? await dataStore.fetchAppSettings() {
                        SpotlightIndexer.shared.indexEvents(todayEvents, for: baby, settings: settings)
                    }
                }
                
                // Restore active sleep on launch (non-blocking, don't wait for it)
                Task {
                    await restoreActiveSleep()
                    await MainActor.run {
                        checkActiveSleep()
                    }
                }
                
                SignpostLogger.endInterval("TimelineLoad", signpostID: signpostID, log: SignpostLogger.ui)
            } catch {
                if Task.isCancelled {
                    print("[\(taskID)] loadTodayEvents was cancelled during error handling")
                    timeoutTask.cancel()
                    // Ensure isLoading is reset even if cancelled
                    self.isLoading = false
                    return
                }
                
                timeoutTask.cancel()
                let elapsed = Date().timeIntervalSince(startTime)
                print("[\(taskID)] ERROR: fetchEvents failed after \(elapsed) seconds: \(error)")
                self.errorMessage = "Failed to load events: \(error.localizedDescription)"
                self.isLoading = false
                print("[\(taskID)] Error set, isLoading = false")
                SignpostLogger.endInterval("TimelineLoad", signpostID: signpostID, log: SignpostLogger.ui)
            }
        }
    }
    
    /// Restore active sleep state on app launch
    private func restoreActiveSleep() async {
        do {
            if let activeSleep = try await dataStore.getActiveSleep(for: baby) {
                // Active sleep exists, update UI state
                await MainActor.run {
                    self.activeSleep = activeSleep
                }
            }
        } catch {
            // Log error but don't block UI
            print("Failed to restore active sleep: \(error.localizedDescription)")
        }
    }
    
    func quickLogFeed() {
        print("quickLogFeed called")
        // Reload events after adding
        Task { @MainActor in
            do {
                // Get last used values or use defaults
                var amount = AppConstants.defaultFeedAmountML
                var unit = "ml"
                
                if let lastUsed = try? await dataStore.getLastUsedValues(for: .feed) {
                    if let lastAmount = lastUsed.amount {
                        amount = lastAmount
                        unit = lastUsed.unit ?? "ml"
                    }
                }
                
                // Ensure minimum
                let amountML = unit == "ml" ? amount : amount * AppConstants.mlPerOz
                let finalAmount = max(amountML, AppConstants.minimumFeedAmountML)
                let finalUnit = unit == "ml" ? "ml" : "oz"
                let finalAmountDisplay = unit == "ml" ? finalAmount : finalAmount / AppConstants.mlPerOz
                
                let event = Event(
                    babyId: baby.id,
                    type: .feed,
                    subtype: "bottle",
                    amount: finalAmount,
                    unit: finalUnit,
                    note: nil
                )
                print("Adding feed event: \(finalAmount) \(finalUnit)")
                try await dataStore.addEvent(event)
                print("Feed event added successfully")
                
                // Save last used
                let lastUsed = LastUsedValues(amount: finalAmount, unit: finalUnit, subtype: "bottle")
                try? await dataStore.saveLastUsedValues(for: .feed, values: lastUsed)
                
                // Analytics
                Task {
                    await Analytics.shared.log("event_added", parameters: [
                        "event_type": "feed",
                        "subtype": "bottle",
                        "has_amount": true,
                        "has_note": false
                    ])
                }
                
                Haptics.success()
                
                // Small delay to ensure CoreData save is complete, then reload
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                print("Reloading events after feed...")
                loadTodayEvents()
            } catch {
                print("Error logging feed: \(error)")
                Haptics.error()
                await MainActor.run {
                    errorMessage = "Failed to log feed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func quickLogSleep() {
        print("quickLogSleep called")
        Task { @MainActor in
            do {
                if let active = activeSleep {
                    // Stop active sleep
                    let completedEvent = try await dataStore.stopActiveSleep(for: baby)
                    await MainActor.run {
                        self.activeSleep = nil
                    }
                    
                    // Stop Live Activity
                    if #available(iOS 16.1, *) {
                        LiveActivityManager.shared.stopSleepActivity()
                    }
                    
                    Haptics.success()
                    
                    // Small delay to ensure CoreData save is complete, then reload
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                    print("Reloading events after sleep stop...")
                    loadTodayEvents()
                } else {
                    // Start new sleep
                    let newSleep = try await dataStore.startActiveSleep(for: baby)
                    await MainActor.run {
                        self.activeSleep = newSleep
                    }
                    
                    // Start Live Activity
                    if #available(iOS 16.1, *) {
                        LiveActivityManager.shared.startSleepActivity(for: baby, startTime: newSleep.startTime)
                    }
                    
                    Haptics.light()
                }
            } catch {
                print("Error logging sleep: \(error)")
                Haptics.error()
                await MainActor.run {
                    errorMessage = "Failed to log sleep: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func quickLogDiaper() {
        print("quickLogDiaper called")
        Task { @MainActor in
            do {
                // Get last used subtype or default to wet
                var subtype = "wet"
                if let lastUsed = try? await dataStore.getLastUsedValues(for: .diaper),
                   let lastSubtype = lastUsed.subtype {
                    subtype = lastSubtype
                }
                
                let event = Event(
                    babyId: baby.id,
                    type: .diaper,
                    subtype: subtype,
                    startTime: Date(),
                    note: nil
                )
                try await dataStore.addEvent(event)
                
                // Save last used
                let lastUsed = LastUsedValues(subtype: subtype)
                try? await dataStore.saveLastUsedValues(for: .diaper, values: lastUsed)
                
                Haptics.success()
                
                // Small delay to ensure CoreData save is complete, then reload
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                print("Reloading events after diaper...")
                loadTodayEvents()
            } catch {
                print("Error logging diaper: \(error)")
                Haptics.error()
                await MainActor.run {
                    errorMessage = "Failed to log diaper: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func quickLogTummyTime() {
        print("quickLogTummyTime called")
        Task { @MainActor in
            do {
                // Get last used duration or default
                var duration = AppConstants.defaultTummyTimeDurationMinutes
                if let lastUsed = try? await dataStore.getLastUsedValues(for: .tummyTime),
                   let lastDuration = lastUsed.durationMinutes {
                    duration = lastDuration
                }
                
                let startTime = Date().addingTimeInterval(-Double(duration * 60))
                let event = Event(
                    babyId: baby.id,
                    type: .tummyTime,
                    startTime: startTime,
                    endTime: Date(),
                    note: nil
                )
                try await dataStore.addEvent(event)
                
                // Save last used
                let lastUsed = LastUsedValues(durationMinutes: duration)
                try? await dataStore.saveLastUsedValues(for: .tummyTime, values: lastUsed)
                
                Haptics.success()
                
                // Small delay to ensure CoreData save is complete, then reload
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                print("Reloading events after tummy time...")
                loadTodayEvents()
            } catch {
                print("Error logging tummy time: \(error)")
                Haptics.error()
                await MainActor.run {
                    errorMessage = "Failed to log tummy time: \(error.localizedDescription)"
                }
            }
        }
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
                        self.loadTodayEvents()
                    }
                }
                
                // Analytics
                Task {
                    await Analytics.shared.log("event_deleted", parameters: [
                        "event_type": eventToDelete.type.rawValue,
                        "undo_available": true
                    ])
                }
                
                await MainActor.run {
                    loadTodayEvents()
                }
            } catch {
                errorMessage = "Failed to delete event: \(error.localizedDescription)"
            }
        }
    }
    
    func undoDeletion() async throws {
        try await UndoManager.shared.undo()
        
        // Analytics
        await Analytics.shared.log("event_undo", parameters: [:])
        
        loadTodayEvents()
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
                loadTodayEvents()
                
                // Analytics
                await Analytics.shared.log("event_duplicated", parameters: ["type": event.type.rawValue])
            } catch {
                Haptics.error()
                errorMessage = "Failed to duplicate event: \(error.localizedDescription)"
            }
        }
    }
    
    private func calculateSummary(from events: [Event]) -> DaySummary {
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
        
        return DaySummary(
            feedCount: feedCount,
            diaperCount: diaperCount,
            sleepCount: sleepCount,
            totalSleepMinutes: totalSleepMinutes,
            tummyTimeCount: tummyTimeCount
        )
    }
}

struct DaySummary {
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
    
    /// Formatted sleep display: shows count if > 0, otherwise shows duration or "0"
    var sleepDisplay: String {
        if sleepCount > 0 {
            // Show count of sleep sessions (consistent with Feeds/Diapers)
            return "\(sleepCount)"
        } else if totalSleepMinutes > 0 {
            // Fallback: show duration if we have minutes but no count
            if sleepHours > 0 {
                return sleepMinutes > 0 ? "\(sleepHours)h \(sleepMinutes)m" : "\(sleepHours)h"
            } else {
                return "\(sleepMinutes)m"
            }
        } else {
            // No sleep logged
            return "0"
        }
    }
}

