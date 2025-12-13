import Foundation
import Combine
import os.signpost
import UserNotifications

// Import for OMG moment detection
private let omgDetection = OMGMomentDetectionService.shared

// Import for educational tooltips
private let educationalTooltips = EducationalTooltipService.shared

// Import for reassurance system
private let reassuranceService = ReassuranceCopyService.shared

// Import for proactive feature discovery
private let proactiveDiscovery = ProactiveFeatureDiscoveryService.shared

// Import for predictive logging
private let predictiveLogging = PredictiveLoggingService.shared

@MainActor
class HomeViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var summary: DaySummary?
    @Published var recommendations: [PersonalizedRecommendationsService.Recommendation] = []
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var isLoading = false {
        didSet {
            logger.debug("HomeViewModel.isLoading changed: \(oldValue) -> \(isLoading) [Thread: \(Thread.isMainThread ? "Main" : "Background")]")
        }
    }
    @Published var errorMessage: String?
    @Published var activeSleep: Event?
    @Published var activeTummyTime: Event?
    @Published var searchText: String = ""
    @Published var debouncedSearchText: String = ""
    @Published var selectedFilter: EventTypeFilter = .all
    @Published var hasAnyEvents: Bool = true // Epic 2 AC2.1
    @Published var userGoal: String? // User's selected goal from onboarding
    @Published var isProcessingQuickLog: Bool = false // Prevent duplicate quick log calls
    @Published var predictiveSuggestions: [PredictiveLoggingService.Prediction] = [] // Smart logging suggestions
    @Published var proactiveSuggestion: ProactiveFeatureDiscoveryService.FeatureSuggestion? // Feature discovery
    
    var babyAgeDescription: String {
        DateUtils.formatBabyAge(dateOfBirth: baby.dateOfBirth)
    }
    
    enum TimeOfDay {
        case morning, day, evening, night
    }
    
    var timeOfDay: TimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return .morning
        case 12..<17: return .day
        case 17..<22: return .evening
        default: return .night
        }
    }
    
    /// Determines whether to show nap prediction prominently based on user goal
    var shouldPrioritizeSleep: Bool {
        userGoal == "sleep" || userGoal == "Track Sleep" || userGoal == "All of the Above"
    }
    
    /// Determines whether to show feeding insights prominently based on user goal
    var shouldPrioritizeFeeding: Bool {
        userGoal == "feeding" || userGoal == "Monitor Feeding" || userGoal == "All of the Above"
    }
    
    /// Returns true if user selected "Just Survive" - simplify UI
    var shouldSimplifyUI: Bool {
        userGoal == "survive" || userGoal == "Just Survive"
    }
    
    private let dataStore: DataStore
    let baby: Baby // Made internal so HomeView can check if baby changed
    private var isLoadingTask: Task<Void, Never>?
    private let showToast: (String, String) -> Void // (message, type)
    private var cancellables = Set<AnyCancellable>()
    private var sleepLiveActivityTimer: AnyCancellable?
    
    // Today Status data
    var lastFeed: Event? {
        events.filter { $0.type == .feed }
            .sorted { $0.startTime > $1.startTime }
            .first
    }
    
    var lastDiaper: Event? {
        events.filter { $0.type == .diaper }
            .sorted { $0.startTime > $1.startTime }
            .first
    }
    
    var lastSleep: Event? {
        events.filter { $0.type == .sleep && $0.endTime != nil }
            .sorted { ($0.endTime ?? $0.startTime) > ($1.endTime ?? $1.startTime) }
            .first
    }
    
    var nextNapWindow: NapWindow? {
        // Use NapPredictorService for consistent nap predictions
        // For Pro users, pass historical events for personalized predictions
        let isPro = ProSubscriptionService.shared.isProUser
        let historicalEvents = isPro ? events.filter { $0.type == .sleep } : nil
        return NapPredictorService.predictNextNapWindow(
            for: baby,
            lastSleep: lastSleep,
            historicalSleepEvents: historicalEvents,
            isProUser: isPro
        )
    }
    
    var nextFeedSuggestion: Date? {
        calculateNextFeedSuggestion()
    }
    
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
                case .cry: return event.type == .cry
                case .other: return false // Or handle specific "other" types if you have them
                }
            }
        }
        
        // Apply search text
        if !debouncedSearchText.isEmpty {
            let query = debouncedSearchText.lowercased()
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
    
    init(dataStore: DataStore, baby: Baby, showToast: @escaping (String, String) -> Void) {
        self.dataStore = dataStore
        self.baby = baby
        self.showToast = showToast
        logger.debug("HomeViewModel.init: Created for baby \(baby.id)")
        Task { @MainActor in
            await loadUserGoal()
            await loadTodayEvents()
        }
        checkActiveSleep()
        
        // Debounce search text to improve performance
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .assign(to: &$debouncedSearchText)
    }
    
    func loadUserGoal() async {
        do {
            let settings = try await dataStore.fetchAppSettings()
            await MainActor.run {
                self.userGoal = settings.userGoal
            }
        } catch {
            logger.error("Error loading user goal: \(error)")
        }
    }
    
    deinit {
        logger.info("HomeViewModel.deinit: Cleaning up for baby \(baby.id)")

        // Cancel all active tasks to prevent memory leaks
        isLoadingTask?.cancel()
        isLoadingTask = nil

        // Cancel any active timers
        // Note: Timer cleanup is handled by invalidating them when they're no longer needed
        // The existing timer management should handle this, but we ensure cleanup here

        // Cancel any pending async operations
        // Note: Most Tasks in this view model are short-lived and complete naturally,
        // but we ensure any long-running operations are cancelled

        // Reset state to prevent any lingering references
        Task { @MainActor [weak self] in
            self?.isLoading = false
            self?.errorMessage = nil
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
    
    func loadTodayEvents() async {
        // Cancel any existing load task first
        let wasAlreadyLoading = isLoadingTask != nil
        isLoadingTask?.cancel()
        isLoadingTask = nil
        
        // Check total history for "First Log" card (Epic 2 AC2.1)
        Task {
            if let allEvents = try? await dataStore.fetchEvents(for: baby, from: Date.distantPast, to: Date.distantFuture) {
                await MainActor.run {
                    self.hasAnyEvents = !allEvents.isEmpty
                }
            }
        }
        
        logger.debug("loadTodayEvents called for baby: \(baby.id), wasAlreadyLoading: \(wasAlreadyLoading)")
        
        // Only set isLoading = true if we weren't already loading
        // This prevents rapid calls from keeping isLoading stuck at true
        if !wasAlreadyLoading {
            isLoading = true
        }
        errorMessage = nil
        
        let signpostID = SignpostLogger.beginInterval("TimelineLoad", log: SignpostLogger.ui)
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { @MainActor in
                await self.loadTodayEventsInternal(signpostID: signpostID)
            }
        }
    }
    
    private func loadTodayEventsInternal(signpostID: OSSignpostID) async {
        isLoadingTask = Task { @MainActor in
            var taskCompleted = false

            // Check for cancellation at start
            try Task.checkCancellation()

            // Use defer to ALWAYS reset isLoading and clear task reference
            // This ensures isLoading is reset even if task is cancelled or errors occur
            defer {
                taskCompleted = true
                logger.debug("loadTodayEvents defer block executing, setting isLoading = false")
                // Ensure we're on MainActor
                assert(Thread.isMainThread, "Defer block must run on main thread")
                // Set isLoading to false and clear task reference
                // @Published will automatically trigger SwiftUI updates
                self.isLoading = false
                self.isLoadingTask = nil
            }
            
            logger.debug("Starting fetchEvents task...")
            let startTime = Date()
            let taskID = UUID()
            logger.debug("Task ID: \(taskID)")

            // Add timeout to prevent infinite loading
            let timeoutTask = Task { @MainActor [weak self] in
                guard let self = self else { return }
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                // Only log timeout if task hasn't completed and is still loading
                if !taskCompleted && self.isLoading {
                    let elapsed = Date().timeIntervalSince(startTime)
                    self.logger.error("loadTodayEvents timed out after \(elapsed) seconds")
                    self.isLoading = false
                    self.errorMessage = "Loading took too long. Please try again."
                }
            }
            
            do {
                logger.debug("[\(taskID)] Calling dataStore.fetchEvents for date: \(Date())")
                let todayEvents = try await dataStore.fetchEvents(for: baby, on: Date())

                // Check if task was cancelled
                if Task.isCancelled {
                    logger.debug("[\(taskID)] loadTodayEvents was cancelled after fetch")
                    timeoutTask.cancel()
                    return // defer block will handle isLoading reset
                }
                
                timeoutTask.cancel()
                
                let elapsed = Date().timeIntervalSince(startTime)
                logger.debug("[\(taskID)] fetchEvents completed in \(elapsed) seconds, got \(todayEvents.count) events")
                
                // Update UI on MainActor (we're already on MainActor, but be explicit)
                self.events = todayEvents
                self.summary = calculateSummary(from: todayEvents)

                // Generate predictive logging suggestions
                if PolishFeatureFlags.shared.predictiveLoggingEnabled {
                    self.predictiveSuggestions = predictiveLogging.getPredictions(
                        for: baby,
                        recentEvents: todayEvents
                    )
                }

                // Check for reassurance messages during difficult patterns
                await checkForReassurance(todayEvents)

                // Update proactive feature suggestions
                if PolishFeatureFlags.shared.proactiveDiscoveryEnabled {
                    let context = ProactiveFeatureDiscoveryService.SuggestionContext.current()
                    self.proactiveSuggestion = proactiveDiscovery.getSuggestion(context: context)
                }

                // Generate personalized recommendations
                self.recommendations = await PersonalizedRecommendationsService.shared.generateRecommendations(
                    for: baby,
                    recentEvents: todayEvents
                )

                // Calculate streaks
                let streakService = StreakService(dataStore: dataStore)
                do {
                    self.currentStreak = try await streakService.calculateCurrentStreak(for: baby)
                    self.longestStreak = try await streakService.calculateLongestStreak(for: baby)
                } catch {
                    logger.debug("Error calculating streaks: \(error)")
                    self.currentStreak = 0
                    self.longestStreak = 0
                }

                logger.debug("[\(taskID)] UI updated with \(todayEvents.count) events")

                // Index events in Spotlight (non-blocking)
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    do {
                        if let settings = try await self.dataStore.fetchAppSettings() {
                            SpotlightIndexer.shared.indexEvents(todayEvents, for: self.baby, settings: settings)
                        }
                    } catch {
                        self.logger.error("Failed to index events in Spotlight: \(error)")
                    }
                }

                // Restore active sleep on launch (non-blocking, don't wait for it)
                Task { @MainActor [weak self] in
                    await restoreActiveSleep()
                    await MainActor.run {
                        checkActiveSleep()
                    }
                }
                
                // Schedule reminders based on latest events
                Task {
                    await scheduleReminders()
                }
                
                SignpostLogger.endInterval("TimelineLoad", signpostID: signpostID, log: SignpostLogger.ui)
            } catch {
                if Task.isCancelled {
                    logger.debug("[\(taskID)] loadTodayEvents was cancelled during error handling")
                    timeoutTask.cancel()
                    return // defer block will handle isLoading reset
                }
                
                timeoutTask.cancel()
                let elapsed = Date().timeIntervalSince(startTime)
                logger.debug("[\(taskID)] ERROR: fetchEvents failed after \(elapsed) seconds: \(error)")
                self.errorMessage = "Failed to load events: \(error.localizedDescription)"
                logger.debug("[\(taskID)] Error set")
                SignpostLogger.endInterval("TimelineLoad", signpostID: signpostID, log: SignpostLogger.ui)
            }
            
            self.isLoadingTask = nil
        }
        
        await isLoadingTask?.value
    }
    
    /// Restore active sleep state on app launch
    private func restoreActiveSleep() async {
        do {
            if let activeSleep = try await dataStore.getActiveSleep(for: baby) {
                // Active sleep exists, update UI state
                await MainActor.run {
                    self.activeSleep = activeSleep
                }
                // Restore Live Activity + updates
                if #available(iOS 16.1, *) {
                    LiveActivityManager.shared.startSleepActivity(for: baby, startTime: activeSleep.startTime)
                    startSleepLiveActivityUpdates(startTime: activeSleep.startTime)
                }
            }
        } catch {
            // Log error but don't block UI
            logger.debug("Failed to restore active sleep: \(error.localizedDescription)")
        }
    }
    
    func quickLogFeed() {
        logger.debug("quickLogFeed called")
        
        // Prevent duplicate calls
        guard !isProcessingQuickLog else {
            logger.debug("Already processing quick log, ignoring duplicate call")
            return
        }
        
        isProcessingQuickLog = true
        
        // Reload events after adding
        Task { @MainActor in
            defer {
                isProcessingQuickLog = false
            }
            
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
                _ = unit == "ml" ? finalAmount : finalAmount / AppConstants.mlPerOz
                
                let event = Event(
                    babyId: baby.id,
                    type: .feed,
                    subtype: "bottle",
                    amount: finalAmount,
                    unit: finalUnit,
                    note: nil
                )
                logger.debug("Adding feed event: \(finalAmount) \(finalUnit)")

                if PolishFeatureFlags.shared.optimisticUIEnabled {
                    // OPTIMISTIC UI: Add to UI immediately
                    events.insert(event, at: 0)
                    Haptics.success()

                    // Show success feedback with personalized message
                    let babyName = baby.name.isEmpty ? "your baby" : baby.name
                    let timeString = DateUtils.formatTime(Date())
                    showToast("Got it! \(babyName)'s \(timeString) feed is tracked", "success")

                    // Update summary immediately
                    updateSummaryAfterEvent(event)

                    // Persist in background
                    Task {
                        do {
                            try await dataStore.addEvent(event)
                            logger.debug("Feed event persisted successfully")

                            // Check if this is the first event and show onboarding toast
                            await checkAndShowFirstEventToast(eventType: "feed")

                            // Check for educational tooltips
                            await checkForEducationalTooltip(event: event)

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

                            // Update widget data after successful add
                            syncWidgetData()

                            // Check for upgrade milestones
                            checkUpgradeMilestones()

                            // Trigger proactive insights
                            ProactiveInsightsService.shared.generateDailyInsight()

                            // Check for celebrations
                            CelebrationService.shared.checkForCelebration(
                                events: events,
                                totalLogs: totalLogs ?? 0,
                                streakDays: daysActive ?? 0,
                                baby: baby
                            )
                        } catch {
                            logger.debug("Error persisting feed event: \(error)")
                            // ROLLBACK: Remove from UI on error
                            events.removeAll { $0.id == event.id }
                            updateSummaryAfterEventRemoval(event)
                            Haptics.error()
                            await MainActor.run {
                                errorMessage = "Failed to log feed: \(error.localizedDescription)"
                            }
                        }
                    }
                } else {
                    // FALLBACK: Original synchronous behavior
                    try await dataStore.addEvent(event)
                    logger.debug("Feed event added successfully")

                    // Check if this is the first event and show onboarding toast
                    await checkAndShowFirstEventToast(eventType: "feed")

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
                    logger.debug("Reloading events after feed...")
                    await loadTodayEvents()
                }
            } catch {
                logger.debug("Error logging feed: \(error)")
                Haptics.error()
                await MainActor.run {
                    errorMessage = "Failed to log feed: \(error.localizedDescription)"
                }
            }
        }
    }

    /// Update summary statistics after adding an event (for optimistic UI)
    private func updateSummaryAfterEvent(_ event: Event) {
        if let currentSummary = summary {
            let updatedSummary = DaySummary(
                feedCount: currentSummary.feedCount + (event.type == .feed ? 1 : 0),
                diaperCount: currentSummary.diaperCount + (event.type == .diaper ? 1 : 0),
                sleepCount: currentSummary.sleepCount + (event.type == .sleep ? 1 : 0),
                totalSleepMinutes: currentSummary.totalSleepMinutes + (event.durationMinutes ?? 0),
                tummyTimeCount: currentSummary.tummyTimeCount + (event.type == .tummy ? 1 : 0)
            )
            summary = updatedSummary
        }
    }

    /// Update summary statistics after removing an event (for rollback)
    private func updateSummaryAfterEventRemoval(_ event: Event) {
        if let currentSummary = summary {
            let updatedSummary = DaySummary(
                feedCount: max(0, currentSummary.feedCount - (event.type == .feed ? 1 : 0)),
                diaperCount: max(0, currentSummary.diaperCount - (event.type == .diaper ? 1 : 0)),
                sleepCount: max(0, currentSummary.sleepCount - (event.type == .sleep ? 1 : 0)),
                totalSleepMinutes: max(0, currentSummary.totalSleepMinutes - (event.durationMinutes ?? 0)),
                tummyTimeCount: max(0, currentSummary.tummyTimeCount - (event.type == .tummy ? 1 : 0))
            )
            summary = updatedSummary
        }
    }

    func quickLogSleep() {
        logger.debug("quickLogSleep called")
        
        // Prevent duplicate calls
        guard !isProcessingQuickLog else {
            logger.debug("Already processing quick log, ignoring duplicate call")
            return
        }
        
        isProcessingQuickLog = true
        
        Task { @MainActor in
            defer {
                isProcessingQuickLog = false
            }
            
            do {
                if activeSleep != nil {
                    // Stop active sleep
                    let stoppedEvent = try await dataStore.stopActiveSleep(for: baby)
                    await MainActor.run {
                        self.activeSleep = nil
                    }

                    // Check for OMG moments
                    await checkForOMGMoment(event: stoppedEvent)

                    // Check if this is the first event and show onboarding toast
                    await checkAndShowFirstEventToast(eventType: "sleep")

                    // Check for educational tooltips
                    await checkForEducationalTooltip(event: stoppedEvent)

                    // Stop Live Activity
                    if #available(iOS 16.1, *) {
                        LiveActivityManager.shared.stopSleepActivity()
                    }
                    stopSleepLiveActivityUpdates()

                    // Review prompt: long sleep milestone (4+ hours)
                    if let endTime = stoppedEvent.endTime {
                        let durationSeconds = Int(endTime.timeIntervalSince(stoppedEvent.startTime))
                        if durationSeconds >= 4 * 3600 {
                            ReviewPromptManager.shared.checkForPositiveMoment(longSleepMilestone: true)
                        }
                    }
                    
                    Haptics.success()
                    
                    // Small delay to ensure CoreData save is complete, then reload
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                    logger.debug("Reloading events after sleep stop...")
                    await loadTodayEvents()
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
                    startSleepLiveActivityUpdates(startTime: newSleep.startTime)
                    
                    Haptics.light()
                }
            } catch {
                logger.debug("Error logging sleep: \(error)")
                CrashReportingService.shared.logError(error, context: ["action": "log_sleep"])
                Haptics.error()
                await MainActor.run {
                    errorMessage = "Failed to log sleep: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Live Activity Updates

    private func startSleepLiveActivityUpdates(startTime: Date) {
        stopSleepLiveActivityUpdates()
        guard #available(iOS 16.1, *) else { return }

        // Update every 60 seconds with elapsed time so Dynamic Island stays fresh.
        sleepLiveActivityTimer = Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                let elapsed = Int(Date().timeIntervalSince(startTime))
                LiveActivityManager.shared.updateSleepActivity(elapsedSeconds: max(0, elapsed))
            }

        // Push an immediate update
        let elapsed = Int(Date().timeIntervalSince(startTime))
        LiveActivityManager.shared.updateSleepActivity(elapsedSeconds: max(0, elapsed))
    }

    private func stopSleepLiveActivityUpdates() {
        sleepLiveActivityTimer?.cancel()
        sleepLiveActivityTimer = nil
    }
    
    func quickLogDiaper() {
        logger.debug("quickLogDiaper called")
        
        // Prevent duplicate calls
        guard !isProcessingQuickLog else {
            logger.debug("Already processing quick log, ignoring duplicate call")
            return
        }
        
        isProcessingQuickLog = true
        
        Task { @MainActor in
            defer {
                isProcessingQuickLog = false
            }
            
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

                // Check if this is the first event and show onboarding toast
                await checkAndShowFirstEventToast(eventType: "diaper")

                // Check for educational tooltips
                await checkForEducationalTooltip(event: event)

                // Save last used
                let lastUsed = LastUsedValues(subtype: subtype)
                try? await dataStore.saveLastUsedValues(for: .diaper, values: lastUsed)
                
                Haptics.success()
                
                // Small delay to ensure CoreData save is complete, then reload
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                logger.debug("Reloading events after diaper...")
                await loadTodayEvents()
            } catch {
                logger.debug("Error logging diaper: \(error)")
                CrashReportingService.shared.logError(error, context: ["action": "log_diaper"])
                Haptics.error()
                await MainActor.run {
                    errorMessage = "Failed to log diaper: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func quickLogTummyTime() {
        logger.debug("quickLogTummyTime called")
        Task { @MainActor in
            do {
                // For quick log, use current time (not backdated)
                // User can edit duration later if needed via the form
                let now = Date()
                let event = Event(
                    babyId: baby.id,
                    type: .tummyTime,
                    startTime: now,
                    endTime: nil, // No end time for quick log - user can add duration later
                    note: nil
                )
                logger.debug("Adding tummy time event at: \(now)")
                try await dataStore.addEvent(event)

                // Check if this is the first event and show onboarding toast
                await checkAndShowFirstEventToast(eventType: "tummy_time")

                // Save last used duration for future reference (but don't use it for quick log timestamp)
                if let lastUsed = try? await dataStore.getLastUsedValues(for: .tummyTime),
                   let _ = lastUsed.durationMinutes {
                    // Keep existing last used values
                } else {
                    // Save default duration for future reference
                    let lastUsed = LastUsedValues(durationMinutes: AppConstants.defaultTummyTimeDurationMinutes)
                    try? await dataStore.saveLastUsedValues(for: .tummyTime, values: lastUsed)
                }
                
                Haptics.success()
                
                // Small delay to ensure CoreData save is complete, then reload
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                logger.debug("Reloading events after tummy time...")
                await loadTodayEvents()
            } catch {
                logger.debug("Error logging tummy time: \(error)")
                CrashReportingService.shared.logError(error, context: ["action": "log_tummy_time"])
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
                
                // Remove from Spotlight index
                SpotlightIndexer.shared.removeEvent(event)
                
                try await dataStore.deleteEvent(event)
                
                // Register for undo
                UndoService.shared.offerUndo(
                    message: "\(eventToDelete.type.displayName) deleted",
                    duration: 5
                ) { [weak self] in
                    guard let self = self else { return }
                    try await self.dataStore.addEvent(eventToDelete)
                    await MainActor.run {
                        Task {
                            await self.loadTodayEvents()
                        }
                    }
                }
                
                // Analytics
                Task {
                    await Analytics.shared.log("event_deleted", parameters: [
                        "event_type": eventToDelete.type.rawValue,
                        "undo_available": true
                    ])
                }
                
                await loadTodayEvents()
            } catch {
                errorMessage = "Failed to delete event: \(error.localizedDescription)"
            }
        }
    }
    
    func undoDeletion() async throws {
        try await UndoManager.shared.undo()
        
        // Analytics
        await Analytics.shared.log("event_undo", parameters: [:])
        
        await loadTodayEvents()
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
                await loadTodayEvents()
                
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
            case .cry:
                break
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

// MARK: - Nap Window Calculation

extension HomeViewModel {
    /// Calculate next nap window based on baby age and last wake time
    func calculateNextNapWindow() -> NapWindow? {
        // Get last wake time (end of last sleep or now if no sleep)
        let lastWakeTime: Date
        if let lastSleep = lastSleep, let endTime = lastSleep.endTime {
            lastWakeTime = endTime
        } else {
            // If no sleep logged, use current time minus average wake window
            lastWakeTime = Date()
        }
        
        // Calculate baby age in months
        let calendar = Calendar.current
        let ageMonths = calendar.dateComponents([.month], from: baby.dateOfBirth, to: Date()).month ?? 0
        
        // Get wake window based on age
        let wakeWindow = getWakeWindowForAge(ageMonths)
        
        // Calculate nap window
        let windowStart = calendar.date(byAdding: .minute, value: wakeWindow.min, to: lastWakeTime) ?? lastWakeTime
        let windowEnd = calendar.date(byAdding: .minute, value: wakeWindow.max, to: lastWakeTime) ?? lastWakeTime
        
        let now = Date()
        
        // Only show if window is in the future or currently active
        if windowEnd >= now {
            let reason = "Based on age (\(ageMonths) mo) + last wake"
            return NapWindow(
                start: windowStart,
                end: windowEnd,
                confidence: lastSleep != nil ? 0.7 : 0.5,
                reason: reason
            )
        }
        
        return nil
    }
    
    private func getWakeWindowForAge(_ ageMonths: Int) -> (min: Int, max: Int) {
        if ageMonths < 3 {
            return (min: 45, max: 75)
        } else if ageMonths < 5 {
            return (min: 75, max: 120)
        } else if ageMonths < 8 {
            return (min: 120, max: 150)
        } else if ageMonths < 11 {
            return (min: 150, max: 180)
        } else if ageMonths < 16 {
            return (min: 180, max: 210)
        } else {
            return (min: 210, max: 240)
        }
    }

    /// Calculate next feed suggestion based on last feed and baby age
    func calculateNextFeedSuggestion() -> Date? {
        guard let lastFeed = lastFeed else { return nil }

        let nextFeedTime = FeedSpacingCalculator.nextFeedTime(lastFeed: lastFeed.startTime, baby: baby)
        let now = Date()

        // Only show if suggestion is in the future (not overdue)
        if nextFeedTime > now {
            return nextFeedTime
        }

        // If overdue, still show the time but it's "now"
        return nextFeedTime
    }
    
    // MARK: - Reminders
    
    func scheduleReminders() async {
        guard let settings = try? await dataStore.fetchAppSettings() else { return }
        
        let reminderService = ReminderService.shared
        
        // Check authorization
        reminderService.checkAuthorizationStatus()
        guard reminderService.authorizationStatus == .authorized else { return }
        
        // Feed reminders
        if settings.feedReminderEnabled, let lastFeed = lastFeed {
            let hoursSinceLastFeed = Date().timeIntervalSince(lastFeed.startTime) / 3600
            if hoursSinceLastFeed >= Double(settings.feedReminderHours) {
                await reminderService.scheduleFeedReminder(
                    babyId: baby.id,
                    hoursSinceLastFeed: hoursSinceLastFeed,
                    reminderHours: settings.feedReminderHours
                )
            } else {
                // Cancel if not yet time
                reminderService.cancelFeedReminder(babyId: baby.id)
            }
        } else if settings.feedReminderEnabled {
            // No last feed - cancel reminders (user should log one)
            reminderService.cancelFeedReminder(babyId: baby.id)
        }
        
        // Diaper reminders
        if settings.diaperReminderEnabled, let lastDiaper = lastDiaper {
            let hoursSinceLastDiaper = Date().timeIntervalSince(lastDiaper.startTime) / 3600
            if hoursSinceLastDiaper >= Double(settings.diaperReminderHours) {
                await reminderService.scheduleDiaperReminder(
                    babyId: baby.id,
                    hoursSinceLastDiaper: hoursSinceLastDiaper,
                    reminderHours: settings.diaperReminderHours
                )
            } else {
                // Cancel if not yet time
                reminderService.cancelDiaperReminder(babyId: baby.id)
            }
        } else if settings.diaperReminderEnabled {
            // No last diaper - cancel reminders (user should log one)
            reminderService.cancelDiaperReminder(babyId: baby.id)
        }
        
        // Nap window reminders
        if settings.napWindowAlertEnabled, let napWindow = nextNapWindow {
            // Check if reminder should respect quiet hours
            let reminderAtMidpoint = false // Can be made configurable later
            await reminderService.scheduleNapWindowReminder(
                babyId: baby.id,
                windowStart: napWindow.start,
                windowEnd: napWindow.end,
                reminderAtMidpoint: reminderAtMidpoint
            )
        } else {
            reminderService.cancelNapWindowReminders(babyId: baby.id)
        }
    }

    private func checkAndShowFirstEventToast(eventType: String) async {
        do {
            // Check if this is the first event ever for this baby
            let allEvents = try await dataStore.fetchEvents(for: baby, from: Date.distantPast, to: Date.distantFuture)
            if allEvents.count == 1 { // Just added the first event
                // Analytics: first log created
                await Analytics.shared.logFirstLogCreated(eventType: eventType, babyId: baby.id.uuidString)

                // Check if user has seen this toast before
                let hasSeenFirstEventToast = UserDefaults.standard.bool(forKey: "hasSeenFirstEventToast")
                if !hasSeenFirstEventToast {
                    UserDefaults.standard.set(true, forKey: "hasSeenFirstEventToast")
                    showToast("Got it 👍 We'll use this to suggest naps and feeds", "success")
                }
            }
            
            // Check if we should show upgrade prompts at milestones
            await checkUpgradeMilestones(totalEvents: allEvents.count)
        } catch {
            logger.debug("Error checking for first event toast: \(error)")
        }
    }
    
    /// Check if user has reached milestones that warrant showing upgrade prompts
    private func checkUpgradeMilestones(totalEvents: Int) async {
        // Skip if already Pro
        if ProSubscriptionService.shared.isProUser {
            return
        }
        
        let hasShown50EventsPrompt = UserDefaults.standard.bool(forKey: "hasShown50EventsUpgradePrompt")
        let hasShown7DaysPrompt = UserDefaults.standard.bool(forKey: "hasShown7DaysUpgradePrompt")
        
        // Milestone 1: After 50 events logged
        if totalEvents == 50 && !hasShown50EventsPrompt {
            UserDefaults.standard.set(true, forKey: "hasShown50EventsUpgradePrompt")
            showToast("🎉 50 events logged! Unlock AI insights with Premium", "upgrade")
            
            // Analytics
            await Analytics.shared.log("upgrade_prompt_shown", parameters: [
                "trigger": "50_events_milestone",
                "total_events": totalEvents
            ])
        }
        
        // Milestone 2: After 7 days of usage
        if let onboardingDate = UserDefaults.standard.object(forKey: "onboardingCompletedDate") as? Date {
            let daysSinceOnboarding = Calendar.current.dateComponents([.day], from: onboardingDate, to: Date()).day ?? 0
            
            if daysSinceOnboarding == 7 && !hasShown7DaysPrompt {
                UserDefaults.standard.set(true, forKey: "hasShown7DaysUpgradePrompt")
                showToast("📊 You're an active user! Get weekly insights with Premium", "upgrade")
                
                // Analytics
                await Analytics.shared.log("upgrade_prompt_shown", parameters: [
                    "trigger": "7_days_usage",
                    "days_since_onboarding": daysSinceOnboarding
                ])
            }
        }
    }

    /// Check for OMG moments after logging events
    private func checkForOMGMoment(event: Event) async {
        // Only check if OMG detection is enabled
        guard PolishFeatureFlags.shared.omgMomentsEnabled else { return }

        // Get recent history for context
        do {
            let recentEvents = try await dataStore.fetchEvents(
                for: baby,
                from: Date().addingTimeInterval(-24 * 60 * 60), // Last 24 hours
                to: Date()
            )

            if let omgMoment = omgDetection.detectAfterSleepEvent(
                event: event,
                baby: baby,
                recentHistory: recentEvents
            ), omgDetection.shouldTriggerMoment(omgMoment) {

                // Trigger enhanced celebration
                await triggerOMGCelebration(omgMoment)
            }
        } catch {
            logger.debug("Error checking for OMG moment: \(error)")
        }
    }

    /// Trigger an OMG celebration with enhanced visuals and share prompt
    private func triggerOMGCelebration(_ moment: OMGMomentDetectionService.OMGMoment) async {
        let celebrationCopy = omgDetection.getCelebrationCopy(for: moment)
        let sharePrompt = omgDetection.getSharePrompt(for: moment)

        // Use enhanced toast with celebration styling
        showToast("\(celebrationCopy.title)\n\(celebrationCopy.message)", "celebration")

        // Analytics
        AnalyticsService.shared.track(event: "omg_moment_triggered", properties: [
            "moment_type": String(describing: moment),
            "baby_name": baby.name,
            "celebration_title": celebrationCopy.title
        ])

        // TODO: Add share prompt integration
        // This would show a subtle "Share this win?" prompt after the celebration
        // For now, the share functionality is handled by the existing CelebrationView
        // when milestones are achieved
    }

    /// Check for educational tooltips after logging events
    private func checkForEducationalTooltip(event: Event) async {
        guard PolishFeatureFlags.shared.educationalTooltipsEnabled else { return }

        let context: EducationalTooltipService.Context

        switch event.type {
        case .sleep:
            // Check if this is the first sleep log
            let allEvents = try? await dataStore.fetchEvents(for: baby, from: Date.distantPast, to: Date.distantFuture)
            let sleepEvents = allEvents?.filter { $0.type == .sleep } ?? []
            if sleepEvents.count == 1 {
                context = .firstSleepLog
            } else {
                return // Not first sleep log
            }

        case .feed:
            // Check if this is the first feed log
            let allEvents = try? await dataStore.fetchEvents(for: baby, from: Date.distantPast, to: Date.distantFuture)
            let feedEvents = allEvents?.filter { $0.type == .feed } ?? []
            if feedEvents.count == 1 {
                context = .firstFeedLog
            } else {
                return // Not first feed log
            }

        case .diaper:
            // Check if this is the first diaper log
            let allEvents = try? await dataStore.fetchEvents(for: baby, from: Date.distantPast, to: Date.distantFuture)
            let diaperEvents = allEvents?.filter { $0.type == .diaper } ?? []
            if diaperEvents.count == 1 {
                context = .firstDiaperLog
            } else {
                return // Not first diaper log
            }

        default:
            return // No tooltip for this event type
        }

        let babyAgeInDays = Calendar.current.dateComponents([.day], from: baby.dateOfBirth, to: Date()).day

        if let tooltip = educationalTooltips.tooltip(for: context, babyAgeInDays: babyAgeInDays) {
            // Show educational tooltip
            showToast(tooltip.displayText, "education")

            // Analytics
            educationalTooltips.trackTooltipShown(tooltip, context: context)
        }
    }

    /// Check for reassurance messages during difficult patterns
    private func checkForReassurance(_ events: [Event]) async {
        guard PolishFeatureFlags.shared.reassuranceSystemEnabled else { return }

        // Get broader context (last 7 days) for pattern detection
        do {
            let lastWeek = Date().addingTimeInterval(-7 * 24 * 60 * 60)
            let weekEvents = try await dataStore.fetchEvents(for: baby, from: lastWeek, to: Date())

            let patterns = reassuranceService.detectDifficultyPatterns(events: weekEvents, baby: baby)

            if reassuranceService.shouldShowReassurance(for: patterns), let primaryPattern = patterns.first {
                let message = reassuranceService.message(
                    for: primaryPattern.context,
                    babyName: baby.name,
                    babyAgeWeeks: Calendar.current.dateComponents([.weekOfYear], from: baby.dateOfBirth, to: Date()).weekOfYear
                )

                // Show reassurance toast
                showToast(message.fullMessage, "reassurance")

                // Mark as shown to prevent spam
                reassuranceService.markReassuranceShown()

                // Analytics
                AnalyticsService.shared.track(event: "reassurance_shown", properties: [
                    "pattern": String(describing: primaryPattern.context),
                    "baby_age_weeks": Calendar.current.dateComponents([.weekOfYear], from: baby.dateOfBirth, to: Date()).weekOfYear ?? 0
                ])
            }
        } catch {
            logger.debug("Error checking for reassurance: \(error)")
        }
    }

    // MARK: - Predictive Logging Actions

    func executePredictiveLog(_ prediction: PredictiveLoggingService.Prediction) async {
        guard !isProcessingQuickLog else { return }

        isProcessingQuickLog = true

        do {
            switch prediction.type {
            case .feed(let amount, let unit, let side):
                await quickLogFeedWithPrediction(amount: amount, unit: unit, side: side)

            case .sleep:
                await quickLogSleep()

            case .diaper(let type):
                await quickLogDiaperWithPrediction(type: type)

            case .tummyTime:
                await quickLogTummyTime()
            }

            // Analytics
            AnalyticsService.shared.track(event: "predictive_log_used", properties: [
                "prediction_type": String(describing: prediction.type),
                "confidence": prediction.confidence,
                "reason": prediction.reason
            ])

            // Clear this prediction since it was used
            predictiveSuggestions.removeAll { $0.id == prediction.id }

        } catch {
            logger.debug("Error executing predictive log: \(error)")
            Haptics.error()
        }

        isProcessingQuickLog = false
    }

    private func quickLogFeedWithPrediction(amount: Double?, unit: String?, side: String?) async {
        // Similar to quickLogFeed but with pre-filled values
        let finalAmount = amount ?? 4.0
        let finalUnit = unit ?? "oz"
        let finalSubtype = side.map { "breast_\($0)" }

        let event = Event(
            id: UUID(),
            babyId: baby.id,
            type: .feed,
            startTime: Date(),
            amount: finalAmount,
            unit: finalUnit,
            subtype: finalSubtype,
            notes: nil
        )

        do {
            try await dataStore.addEvent(event)

            await MainActor.run {
                showToast("Feed logged! \(Int(finalAmount))\(finalUnit)", "success")
            }

            // Check if this is the first event and show onboarding toast
            await checkAndShowFirstEventToast(eventType: "feed")

            // Check for educational tooltips
            await checkForEducationalTooltip(event: event)

            // Analytics
            await Analytics.shared.log("event_added", parameters: [
                "event_type": "feed",
                "subtype": "predictive",
                "has_amount": true,
                "has_note": false
            ])

            Haptics.success()

            // Small delay to ensure CoreData save is complete, then reload
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            await loadTodayEvents()
        } catch {
            logger.debug("Error logging predictive feed: \(error)")
            await MainActor.run {
                showToast("Failed to log feed", "error")
            }
            CrashReportingService.shared.logError(error, context: ["action": "predictive_log_feed"])
            Haptics.error()
        }
    }

    private func quickLogDiaperWithPrediction(type: String?) async {
        let finalSubtype = type ?? "wet"

        let event = Event(
            id: UUID(),
            babyId: baby.id,
            type: .diaper,
            startTime: Date(),
            subtype: finalSubtype,
            notes: nil
        )

        do {
            try await dataStore.addEvent(event)

            await MainActor.run {
                showToast("Diaper logged!", "success")
            }

            // Check if this is the first event and show onboarding toast
            await checkAndShowFirstEventToast(eventType: "diaper")

            // Check for educational tooltips
            await checkForEducationalTooltip(event: event)

            // Analytics
            await Analytics.shared.log("event_added", parameters: [
                "event_type": "diaper",
                "subtype": finalSubtype,
                "has_amount": false,
                "has_note": false
            ])

            Haptics.success()

            // Small delay to ensure CoreData save is complete, then reload
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            await loadTodayEvents()
        } catch {
            logger.debug("Error logging predictive diaper: \(error)")
            await MainActor.run {
                showToast("Failed to log diaper", "error")
            }
            CrashReportingService.shared.logError(error, context: ["action": "predictive_log_diaper"])
            Haptics.error()
        }
    }

    private func quickLogTummyTime() async {
        // Start tummy time (similar to starting sleep)
        guard activeTummyTime == nil else {
            await MainActor.run {
                showToast("Tummy time already active", "info")
            }
            return
        }

        do {
            let newTummyTime = try await dataStore.startActiveTummyTime(for: baby)
            await MainActor.run {
                self.activeTummyTime = newTummyTime
                showToast("Tummy time started!", "success")
            }

            Haptics.success()

            // Small delay to ensure CoreData save is complete, then reload
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            await loadTodayEvents()
        } catch {
            logger.debug("Error starting predictive tummy time: \(error)")
            await MainActor.run {
                showToast("Failed to start tummy time", "error")
            }
            CrashReportingService.shared.logError(error, context: ["action": "predictive_start_tummy"])
            Haptics.error()
        }
    }
}

