import Foundation
import Combine

/// ViewModel for NowView - manages "what's happening now" and quick logging
@MainActor
class NowViewModel: ObservableObject {
    // MARK: - Dependencies

    private let dataStore: DataStore
    private let napPredictionService: NapPredictionService
    private let smartDefaultsService: SmartDefaultsService

    // MARK: - Published Properties

    @Published private(set) var baby: Baby
    @Published private(set) var lastEvents: [Event] = []
    @Published private(set) var activeSleep: Event?
    @Published private(set) var napSuggestion: NapSuggestion?
    @Published private(set) var recentTimeline: [Event] = []
    @Published private(set) var todayFeedCount: Int = 0
    @Published private(set) var todayDiaperCount: Int = 0
    @Published private(set) var todaySleepTotalMinutes: Int = 0
    @Published private(set) var isLoading = false

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()
    private var refreshTask: Task<Void, Never>?

    // MARK: - Initialization

    init(dataStore: DataStore, baby: Baby) {
        self.dataStore = dataStore
        self.baby = baby
        self.napPredictionService = NapPredictionService(dataStore: dataStore)
        self.smartDefaultsService = SmartDefaultsService(dataStore: dataStore)

        setupBindings()
        refreshData()
    }

    private func setupBindings() {
        // Refresh data when baby changes
        $baby
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.refreshData()
            }
            .store(in: &cancellables)
    }

    // MARK: - Data Refresh

    func refreshData() {
        refreshTask?.cancel()
        refreshTask = Task {
            await loadData()
        }
    }

    private func loadData() async {
        isLoading = true
        defer { isLoading = false }

        async let lastEventsTask = loadLastEvents()
        async let activeSleepTask = loadActiveSleep()
        async let timelineTask = loadRecentTimeline()
        async let summaryTask = loadTodaySummary()
        async let napSuggestionTask = loadNapSuggestion()

        let (lastEvents, activeSleep, timeline, summary, napSuggestion) = await (
            lastEventsTask,
            activeSleepTask,
            timelineTask,
            summaryTask,
            napSuggestionTask
        )

        self.lastEvents = lastEvents
        self.activeSleep = activeSleep
        self.recentTimeline = timeline
        self.todayFeedCount = summary.feeds
        self.todayDiaperCount = summary.diapers
        self.todaySleepTotalMinutes = summary.sleepMinutes
        self.napSuggestion = napSuggestion
    }

    private func loadLastEvents() async -> [Event] {
        do {
            // Get events from last 24 hours, sorted by recency
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            let events = try await dataStore.fetchEvents(for: baby, from: yesterday, to: Date())

            // Group by type and get most recent of each
            var latestByType: [EventType: Event] = [:]

            for event in events.sorted(by: { $0.startTime > $1.startTime }) {
                if latestByType[event.type] == nil {
                    latestByType[event.type] = event
                }
            }

            // Return in priority order: feed, diaper, sleep, tummy time
            let priorityOrder: [EventType] = [.feed, .diaper, .sleep, .tummyTime]
            return priorityOrder.compactMap { latestByType[$0] }

        } catch {
            Logger.dataError("Failed to load last events: \(error.localizedDescription)")
            return []
        }
    }

    private func loadActiveSleep() async -> Event? {
        do {
            return try await dataStore.getActiveSleep(for: baby)
        } catch {
            Logger.dataError("Failed to load active sleep: \(error.localizedDescription)")
            return nil
        }
    }

    private func loadRecentTimeline() async -> [Event] {
        do {
            // Get last 12 hours of events
            let twelveHoursAgo = Calendar.current.date(byAdding: .hour, value: -12, to: Date()) ?? Date()
            let events = try await dataStore.fetchEvents(for: baby, from: twelveHoursAgo, to: Date())
            return events.sorted(by: { $0.startTime > $1.startTime })
        } catch {
            Logger.dataError("Failed to load recent timeline: \(error.localizedDescription)")
            return []
        }
    }

    private func loadTodaySummary() async -> (feeds: Int, diapers: Int, sleepMinutes: Int) {
        do {
            let today = Calendar.current.startOfDay(for: Date())
            let events = try await dataStore.fetchEvents(for: baby, on: today)

            var feeds = 0
            var diapers = 0
            var sleepMinutes = 0

            for event in events {
                switch event.type {
                case .feed:
                    feeds += 1
                case .diaper:
                    diapers += 1
                case .sleep:
                    sleepMinutes += event.durationMinutes ?? 0
                case .tummyTime:
                    break // Not counted in summary
                }
            }

            return (feeds, diapers, sleepMinutes)
        } catch {
            Logger.dataError("Failed to load today summary: \(error.localizedDescription)")
            return (0, 0, 0)
        }
    }

    private func loadNapSuggestion() async -> NapSuggestion? {
        do {
            return try await napPredictionService.generateSuggestion(for: baby)
        } catch {
            Logger.dataError("Failed to load nap suggestion: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Quick Logging Actions

    func quickLogFeed() {
        Task {
            do {
                // Get smart defaults for feed
                let defaults = try await smartDefaultsService.getDefaults(for: .feed)

                // Create feed event with defaults
                let feedEvent = Event(
                    babyId: baby.id,
                    type: .feed,
                    subtype: defaults.subtype ?? "bottle",
                    amount: defaults.amount ?? 120,
                    unit: defaults.unit ?? "ml"
                )

                try await dataStore.addEvent(feedEvent)
                Haptics.success()

                // Update smart defaults
                await smartDefaultsService.updateDefaults(for: .feed, from: feedEvent)

                // Refresh data
                refreshData()

            } catch {
                Logger.dataError("Failed to quick log feed: \(error.localizedDescription)")
                Haptics.error()
            }
        }
    }

    func quickLogDiaper() {
        Task {
            do {
                // Get smart defaults for diaper
                let defaults = try await smartDefaultsService.getDefaults(for: .diaper)

                // Create diaper event with defaults (prefer "wet" if no preference)
                let diaperEvent = Event(
                    babyId: baby.id,
                    type: .diaper,
                    subtype: defaults.subtype ?? "wet"
                )

                try await dataStore.addEvent(diaperEvent)
                Haptics.success()

                // Update smart defaults
                await smartDefaultsService.updateDefaults(for: .diaper, from: diaperEvent)

                // Refresh data
                refreshData()

            } catch {
                Logger.dataError("Failed to quick log diaper: \(error.localizedDescription)")
                Haptics.error()
            }
        }
    }

    func startNapTimer() {
        Task {
            do {
                let activeSleep = try await dataStore.startActiveSleep(for: baby)
                self.activeSleep = activeSleep

                // Start Live Activity if available
                if #available(iOS 16.1, *) {
                    LiveActivityManager.shared.startSleepActivity(for: baby, startTime: activeSleep.startTime)
                }

                Haptics.success()
                refreshData()

            } catch {
                Logger.dataError("Failed to start nap timer: \(error.localizedDescription)")
                Haptics.error()
            }
        }
    }

    func stopNapTimer() {
        Task {
            do {
                let completedSleep = try await dataStore.stopActiveSleep(for: baby)
                self.activeSleep = nil

                // End Live Activity if available
                if #available(iOS 16.1, *) {
                    LiveActivityManager.shared.endSleepActivity()
                }

                Haptics.success()
                refreshData()

            } catch {
                Logger.dataError("Failed to stop nap timer: \(error.localizedDescription)")
                Haptics.error()
            }
        }
    }

    func quickLogTummyTime() {
        Task {
            do {
                // Get smart defaults for tummy time
                let defaults = try await smartDefaultsService.getDefaults(for: .tummyTime)

                // Create tummy time event with defaults (5 minutes if no preference)
                let duration = defaults.durationMinutes ?? 5
                let startTime = Date().addingTimeInterval(-Double(duration * 60))
                let endTime = Date()

                let tummyEvent = Event(
                    babyId: baby.id,
                    type: .tummyTime,
                    startTime: startTime,
                    endTime: endTime
                )

                try await dataStore.addEvent(tummyEvent)
                Haptics.success()

                // Update smart defaults
                await smartDefaultsService.updateDefaults(for: .tummyTime, from: tummyEvent)

                // Refresh data
                refreshData()

            } catch {
                Logger.dataError("Failed to quick log tummy time: \(error.localizedDescription)")
                Haptics.error()
            }
        }
    }

    // MARK: - Event Management

    func handleNewEvent(_ event: Event) {
        // Event already saved by form, just refresh our data
        refreshData()
    }

    func deleteEvent(_ event: Event) {
        Task {
            do {
                try await dataStore.deleteEvent(event)
                Haptics.success()
                refreshData()
            } catch {
                Logger.dataError("Failed to delete event: \(error.localizedDescription)")
                Haptics.error()
            }
        }
    }

    // MARK: - Baby Management

    func updateBaby(_ newBaby: Baby) {
        self.baby = newBaby
        // refreshData() will be called automatically via binding
    }
}
