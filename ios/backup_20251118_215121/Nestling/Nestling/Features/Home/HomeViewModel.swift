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
        loadTodayEvents()
        checkActiveSleep()
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
        isLoading = true
        errorMessage = nil
        
        let signpostID = SignpostLogger.beginInterval("TimelineLoad", log: SignpostLogger.ui)
        
        Task {
            do {
                let todayEvents = try await dataStore.fetchEvents(for: baby, on: Date())
                self.events = todayEvents
                
                // Index events in Spotlight
                if let settings = try? await dataStore.fetchAppSettings() {
                    SpotlightIndexer.shared.indexEvents(todayEvents, for: baby, settings: settings)
                }
                
                // Restore active sleep on launch (persisted across app kills)
                await restoreActiveSleep()
                
                checkActiveSleep()
                self.summary = calculateSummary(from: todayEvents)
                self.isLoading = false
                
                SignpostLogger.endInterval("TimelineLoad", signpostID: signpostID, log: SignpostLogger.ui)
            } catch {
                self.errorMessage = "Failed to load events: \(error.localizedDescription)"
                self.isLoading = false
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
        Task {
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
                try await dataStore.addEvent(event)
                
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
                loadTodayEvents()
            } catch {
                Haptics.error()
                errorMessage = "Failed to log feed: \(error.localizedDescription)"
            }
        }
    }
    
    func quickLogSleep() {
        Task {
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
                Haptics.error()
                errorMessage = "Failed to log sleep: \(error.localizedDescription)"
            }
        }
    }
    
    func quickLogDiaper() {
        Task {
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
                loadTodayEvents()
            } catch {
                Haptics.error()
                errorMessage = "Failed to log diaper: \(error.localizedDescription)"
            }
        }
    }
    
    func quickLogTummyTime() {
        Task {
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
                loadTodayEvents()
            } catch {
                Haptics.error()
                errorMessage = "Failed to log tummy time: \(error.localizedDescription)"
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

