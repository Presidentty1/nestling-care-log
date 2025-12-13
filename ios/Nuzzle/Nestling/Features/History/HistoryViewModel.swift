import Foundation
import Combine

enum HistoryViewState: Equatable {
    case loading
    case loaded
    case error(message: String)
}

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var state: HistoryViewState = .loading
    @Published var days: [HistoryDay] = []
    @Published var selectedRange: HistoryRange = .last24Hours
    @Published var selectedFilter: EventTypeFilter = .all
    @Published var searchText: String = ""
    @Published var rangeSummary: HistoryRangeSummary?
    @Published var canLoadMore: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var errorMessage: String?
    @Published var weeklySummary: InsightGenerationService.WeekSummary? // Phase 3: Weekly trends

    // Month caching for performance (Phase 3)
    private var monthCache: [Date: [HistoryDay]] = [:]
    private var preloadTask: Task<Void, Never>?

    var filteredDays: [HistoryDay] {
        let filtered = days.compactMap { day -> HistoryDay? in
            let filteredEvents = day.events.filter { matchesFilter($0) && matchesSearch($0) }
            guard !filteredEvents.isEmpty else { return nil }
            return HistoryDay(date: day.date, events: filteredEvents, summary: day.summary)
        }
        return filtered.sorted { $0.date > $1.date }
    }

    private let dataStore: DataStore
    private let dataProvider: HistoryDataProvider
    let baby: Baby
    private let calendar = Calendar.current
    private var earliestLoadedDate: Date?
    private let pageSizeDays = 7

    init(dataStore: DataStore, baby: Baby, dataProvider: HistoryDataProvider? = nil) {
        self.dataStore = dataStore
        self.baby = baby
        self.dataProvider = dataProvider ?? DefaultHistoryDataProvider(dataStore: dataStore)
        Task { await loadEvents() }
    }

    func loadEvents() async {
        state = .loading
        errorMessage = nil
        earliestLoadedDate = nil
        await fetchRange(
            startDate: startDate(for: selectedRange, endingAt: Date()),
            endDate: Date(),
            append: false
        )
    }

    func onRangeChanged(_ range: HistoryRange) async {
        selectedRange = range
        await loadEvents()
    }

    func loadMore() async {
        guard !isLoadingMore else { return }
        let endDate = earliestLoadedDate ?? Date()
        guard let startDate = calendar.date(byAdding: .day, value: -pageSizeDays, to: endDate) else { return }
        await fetchRange(startDate: startDate, endDate: endDate, append: true)
    }

    func deleteEvent(_ event: Event) async {
        do {
            let eventToDelete = event
            SpotlightIndexer.shared.removeEvent(event)
            try await dataStore.deleteEvent(event)

            UndoManager.shared.registerDeletion(event: eventToDelete) { [weak self] in
                guard let self else { return }
                try await self.dataStore.addEvent(eventToDelete)
                await self.loadEvents()
            }

            await loadEvents()
        } catch {
            errorMessage = "Failed to delete event: \(error.localizedDescription)"
            state = .error(message: errorMessage ?? "Failed to delete event.")
        }
    }

    func undoDeletion() async throws {
        try await UndoManager.shared.undo()
        await loadEvents()
    }

    func duplicateEvent(_ event: Event) {
        Task {
            do {
                let duplicatedEvent = Event(
                    id: IDGenerator.generate(),
                    babyId: event.babyId,
                    type: event.type,
                    subtype: event.subtype,
                    startTime: Date(),
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
                state = .error(message: errorMessage ?? "Failed to duplicate event.")
            }
        }
    }

    var searchSuggestions: [String] {
        var suggestions: [String] = ["feeds", "diapers", "naps", "tummy", "cry"]
        let noteTerms = days
            .flatMap { $0.events }
            .compactMap { $0.note?.lowercased() }
            .flatMap { $0.components(separatedBy: .whitespacesAndNewlines) }
            .filter { $0.count > 2 }
        suggestions.append(contentsOf: Array(Set(noteTerms)).prefix(5))
        return Array(suggestions.prefix(5))
    }

    // MARK: - Phase 3: Weekly Trends

    func generateWeeklySummary() async {
        // Get all events from the last 7 days
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekStart = calendar.date(byAdding: .day, value: -6, to: today)!

        do {
            let weekEvents = try await dataStore.fetchEvents(for: baby, from: weekStart, to: today)
            weeklySummary = InsightGenerationService.shared.generateWeeklySummary(
                events: weekEvents,
                baby: baby
            )
        } catch {
            logger.debug("Error generating weekly summary: \(error)")
            weeklySummary = nil
        }
    }

    // MARK: - Private

    private func fetchRange(startDate: Date, endDate: Date, append: Bool) async {
        if append { isLoadingMore = true }
        do {
            let events = try await dataProvider.fetchEvents(for: baby, from: startDate, to: endDate)
            let grouped = Self.groupEvents(events, calendar: calendar)
            if append {
                days.append(contentsOf: grouped)
            } else {
                days = grouped
            }
            days.sort { $0.date > $1.date }
            earliestLoadedDate = min(earliestLoadedDate ?? endDate, startDate)
            rangeSummary = makeRangeSummary()

            // Phase 3: Generate weekly summary if viewing last 7 days
            if selectedRange == .last7Days {
                await generateWeeklySummary()
            }

            canLoadMore = true
            state = .loaded

            // Preload adjacent months for better performance
            preloadAdjacentMonths()
        } catch {
            errorMessage = "Failed to load events: \(error.localizedDescription)"
            state = .error(message: errorMessage ?? "Failed to load events.")
        }
        isLoadingMore = false
    }

    private func startDate(for range: HistoryRange, endingAt endDate: Date) -> Date {
        switch range {
        case .last24Hours:
            return endDate.addingTimeInterval(-24 * 60 * 60)
        case .last7Days, .last30Days:
            let startOfToday = calendar.startOfDay(for: endDate)
            let daysBack = (range.daysToFetch - 1) * -1
            return calendar.date(byAdding: .day, value: daysBack, to: startOfToday) ?? startOfToday
        }
    }

    private func makeRangeSummary() -> HistoryRangeSummary? {
        let start = startDate(for: selectedRange, endingAt: Date())
        let daysInRange = days.filter { calendar.startOfDay(for: $0.date) >= calendar.startOfDay(for: start) }
        let events = daysInRange.flatMap { $0.events }
        guard !events.isEmpty else {
            return HistoryRangeSummary(range: selectedRange, totalDays: selectedRange.daysToFetch, totalFeeds: 0, totalDiapers: 0, totalSleepMinutes: 0, totalCries: 0)
        }

        var totalSleepMinutes = 0
        var totalFeeds = 0
        var totalDiapers = 0
        var totalCries = 0

        events.forEach { event in
            switch event.type {
            case .feed:
                totalFeeds += 1
            case .diaper:
                totalDiapers += 1
            case .sleep:
                totalSleepMinutes += event.durationMinutes ?? 0
            case .tummyTime:
                break
            case .cry:
                totalCries += 1
            }
        }

        let daysCount = max(1, min(selectedRange.daysToFetch, daysInRange.count))
        return HistoryRangeSummary(
            range: selectedRange,
            totalDays: daysCount,
            totalFeeds: totalFeeds,
            totalDiapers: totalDiapers,
            totalSleepMinutes: totalSleepMinutes,
            totalCries: totalCries
        )
    }

    private func matchesFilter(_ event: Event) -> Bool {
        switch selectedFilter {
        case .all: return true
        case .feeds: return event.type == .feed
        case .diapers: return event.type == .diaper
        case .sleep: return event.type == .sleep
        case .tummy: return event.type == .tummyTime
        case .cry: return event.type == .cry
        case .other: return false
        }
    }

    private func matchesSearch(_ event: Event) -> Bool {
        guard !searchText.isEmpty else { return true }
        let query = searchText.lowercased()

        if event.type.displayName.lowercased().contains(query) { return true }
        if let note = event.note?.lowercased(), note.contains(query) { return true }
        if let subtype = event.subtype?.lowercased(), subtype.contains(query) { return true }

        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        if timeFormatter.string(from: event.startTime).lowercased().contains(query) { return true }

        if query.contains("last") {
            let sorted = days.flatMap { $0.events }.sorted { $0.startTime > $1.startTime }
            if let match = sorted.first(where: { $0.type == event.type }) {
                return match.id == event.id
            }
        }
        return false
    }

    private static func groupEvents(_ events: [Event], calendar: Calendar) -> [HistoryDay] {
        let grouped = Dictionary(grouping: events) { calendar.startOfDay(for: $0.startTime) }
        return grouped
            .map { date, events in
                let sortedEvents = events.sorted { $0.startTime > $1.startTime }
                let summary = Self.computeDaySummary(for: sortedEvents)
                return HistoryDay(date: date, events: sortedEvents, summary: summary)
            }
            .sorted { $0.date > $1.date }
    }

    private static func computeDaySummary(for events: [Event]) -> HistoryDaySummary {
        var totalSleepMinutes = 0
        var napCount = 0
        var feedCount = 0
        var diaperCount = 0
        var wetDiaperCount = 0
        var dirtyDiaperCount = 0
        var tummyTimeCount = 0
        var cryCount = 0

        for event in events {
            switch event.type {
            case .sleep:
                napCount += 1
                totalSleepMinutes += event.durationMinutes ?? 0
            case .feed:
                feedCount += 1
            case .diaper:
                diaperCount += 1
                let subtype = event.subtype?.lowercased() ?? ""
                if subtype.contains("wet") { wetDiaperCount += 1 }
                if subtype.contains("dirty") || subtype.contains("poop") { dirtyDiaperCount += 1 }
            case .tummyTime:
                tummyTimeCount += 1
            case .cry:
                cryCount += 1
            }
        }

        return HistoryDaySummary(
            totalSleepMinutes: totalSleepMinutes,
            napCount: napCount,
            feedCount: feedCount,
            diaperCount: diaperCount,
            wetDiaperCount: wetDiaperCount,
            dirtyDiaperCount: dirtyDiaperCount,
            tummyTimeCount: tummyTimeCount,
            cryCount: cryCount
        )
    }

    // MARK: - Month Caching and Preloading

    /// Preload adjacent months for smooth navigation
    func preloadAdjacentMonths() {
        guard PolishFeatureFlags.shared.timelineGroupingEnabled else { return }

        preloadTask?.cancel()
        preloadTask = Task {
            // Get current month
            let currentMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date()))!

            // Preload previous and next month
            let previousMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth)!
            let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth)!

            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    await self.loadMonthIntoCache(previousMonth)
                }
                group.addTask {
                    await self.loadMonthIntoCache(nextMonth)
                }
            }
        }
    }

    private func loadMonthIntoCache(_ monthStart: Date) async {
        // Check if already cached
        if monthCache[monthStart] != nil { return }

        do {
            let monthEnd = Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!

            // Load events for this month
            let events = try await dataStore.fetchEvents(
                from: monthStart,
                to: monthEnd,
                babyId: babyId
            )

            // Group by day
            let groupedEvents = Dictionary(grouping: events) { event in
                Calendar.current.startOfDay(for: event.startTime)
            }

            // Create HistoryDay objects
            var historyDays: [HistoryDay] = []
            for (date, dayEvents) in groupedEvents {
                let sortedEvents = dayEvents.sorted { $0.startTime > $1.startTime }
                let summary = calculateDaySummary(sortedEvents)
                historyDays.append(HistoryDay(date: date, events: sortedEvents, summary: summary))
            }

            // Cache the result
            monthCache[monthStart] = historyDays.sorted { $0.date > $1.date }

        } catch {
            logger.debug("Failed to preload month \(monthStart): \(error)")
        }
    }

    /// Get cached month data if available
    func getCachedMonth(_ monthStart: Date) -> [HistoryDay]? {
        return monthCache[monthStart]
    }

    deinit {
        logger.debug("HistoryViewModel.deinit: Cleaning up")
        // Cancel any active Tasks and clear cache
        monthCache.removeAll()
    }
}

