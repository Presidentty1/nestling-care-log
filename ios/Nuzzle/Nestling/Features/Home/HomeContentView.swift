import SwiftUI
import Combine

/// HomeContentView - Today-Focused Layout
///
/// Implements the "What's happening right now, and what should I do next?" experience:
/// - Header: Baby info and date selector
/// - Nap Card: Hero card with next nap window
/// - Quick Actions: 2-tap logging for Sleep/Feed/Diaper/Cry
/// - Today Timeline: Simple chronological list of today's events
/// - AI Card: Secondary tease for Q&A and cry analysis
///
/// Design goal: Get exhausted parents to their first "aha moment" in under 60 seconds.

struct HomeContentView: View {
    @ObservedObject var viewModel: HomeViewModel
    @EnvironmentObject var environment: AppEnvironment
    @Binding var showFeedForm: Bool
    @Binding var showSleepForm: Bool
    @Binding var showDiaperForm: Bool
    @Binding var showTummyForm: Bool
    @Binding var showCryRecorder: Bool
    @Binding var editingEvent: Event?
    @Binding var showToast: ToastMessage?
    @Binding var showProSubscription: Bool
    let onBabySelected: (Baby) -> Void
    let onEventEdited: (Event) -> Void
    
    @State private var showBabySwitcher = false
    @State private var showDatePicker = false
    @State private var showWidgetPrompt = false
    @State private var showWidgetOnboarding = false
    
    private var currentBaby: Baby? {
        environment.currentBaby
    }
    
    private var focusArea: FocusArea? {
        // Try to parse focus area from user goal
        guard let goal = viewModel.userGoal else { return nil }
        if goal.contains("Naps") || goal.contains("sleep") {
            return .napsAndNights
        } else if goal.contains("feeds") || goal.contains("diapers") {
            return .feedsAndDiapers
        } else if goal.contains("cries") || goal.contains("Cries") {
            return .cries
        } else if goal.contains("All") || goal.contains("all") {
            return .all
        }
        return nil
    }

    private var shouldShowWidgetPrompt: Bool {
        // Only show if feature flag is enabled
        guard PolishFeatureFlags.shared.widgetOnboardingEnabled else { return false }

        // Don't show if user has already seen it
        if UserDefaults.standard.bool(forKey: "hasSeenWidgetPrompt") {
            return false
        }

        // Show after first accurate nap prediction (within first 3 days of onboarding)
        guard let onboardingDate = UserDefaults.standard.object(forKey: "onboardingCompleteDate") as? Date else {
            return false
        }

        let daysSinceOnboarding = Calendar.current.dateComponents([.day], from: onboardingDate, to: Date()).day ?? 0

        // Only show in first 3 days
        guard daysSinceOnboarding <= 3 else { return false }

        // Check if we have an accurate prediction
        // This is a simple heuristic - if we have any prediction, assume it's accurate enough
        return viewModel.prediction != nil
    }

    private var shouldShowJourneyCard: Bool {
        // Only show during first 3 days of journey
        let journeyService = FirstThreeDaysJourneyService.shared
        return journeyService.currentDay <= 3 && journeyService.journeyProgress < 1.0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: .spacingLG) {
                // Header
                TodayHeaderBar(
                    baby: currentBaby,
                    onDateTap: {
                        // TODO: For MVP, this is a no-op. Can expand to show past days.
                        Haptics.selection()
                        showDatePicker = true
                    }
                )
                
                // Journey Progress Card (first 3 days)
                if PolishFeatureFlags.shared.first72hJourneyEnabled && shouldShowJourneyCard {
                    FirstThreeDaysCard()
                        .padding(.horizontal, .spacingLG)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Nap Predictor Card (Hero)
                napPredictorSection

                // Widget Onboarding Prompt
                if shouldShowWidgetPrompt {
                    AddWidgetPromptCard(
                        onDismiss: {
                            UserDefaults.standard.set(true, forKey: "hasSeenWidgetPrompt")
                            AnalyticsService.shared.logWidgetPromptDismissed()
                            withAnimation { showWidgetPrompt = false }
                        },
                        onAddWidget: {
                            UserDefaults.standard.set(true, forKey: "hasSeenWidgetPrompt")
                            AnalyticsService.shared.logWidgetPromptClicked()
                            showWidgetOnboarding = true
                        }
                    )
                    .padding(.horizontal, .spacingLG)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        AnalyticsService.shared.logWidgetPromptShown()
                    }
                }

                // Predictive Logging Suggestions (if available)
                if PolishFeatureFlags.shared.predictiveLoggingEnabled && !viewModel.predictiveSuggestions.isEmpty {
                    predictiveSuggestionsSection
                }

                // Quick Actions (2x2 Grid)
                quickActionsSection
                
                // Today Timeline
                todayTimelineSection
                
                // AI Tease Card
                aiTeaseSection

                // Proactive Feature Suggestion
                if let suggestion = viewModel.proactiveSuggestion {
                    ProactiveSuggestionCard(suggestion: suggestion) {
                        // Handle suggestion tap
                        proactiveDiscovery.trackSuggestionAction(suggestion, action: "tapped")
                        // TODO: Navigate to relevant feature
                        logger.debug("Navigate to: \(suggestion.rawValue)")
                    } onDismiss: {
                        viewModel.proactiveSuggestion = nil
                        proactiveDiscovery.trackSuggestionAction(suggestion, action: "dismissed")
                    }
                    .padding(.horizontal, .spacingLG)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        proactiveDiscovery.markSuggestionShown(suggestion)
                    }
                }
            }
            .padding(.bottom, .spacingXL)
        }
        .refreshable {
            // Refresh dashboard data
            await viewModel.loadTodayEvents()
        }
        .background(Color.background)
        .withUndoToast()
        .confirmationDialog("Choose baby", isPresented: $showBabySwitcher) {
            if let current = currentBaby {
                ForEach(environment.babies) { baby in
                    Button(baby.name) {
                        onBabySelected(baby)
                    }
                    .disabled(baby.id == current.id)
                }
            }
        }
        .alert("Date Selector", isPresented: $showDatePicker) {
            Button("OK") {
                showDatePicker = false
            }
        } message: {
            Text("Today view currently shows only today. Past days coming soon!")
        }
    }
    
    // MARK: - Nap Predictor Section
    
    @ViewBuilder
    private var napPredictorSection: some View {
        VStack(alignment: .leading, spacing: .spacingMD) {
            NapPredictionCard(
                napWindow: viewModel.nextNapWindow,
                baby: currentBaby,
                onTap: {
                    // TODO: Could show more detailed nap prediction info
                }
            )
            .padding(.horizontal, .spacingLG)
        }
    }
    
    // MARK: - Quick Actions Section
    
    @ViewBuilder
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: .spacingSM) {
            Text("Quick Log")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.foreground)
                .padding(.horizontal, .spacingLG)
            
            // 2x2 grid of quick actions
            VStack(spacing: .spacingMD) {
                HStack(spacing: .spacingMD) {
                    QuickActionButton(
                        title: viewModel.activeSleep != nil ? "End Sleep" : "Sleep",
                        icon: "moon.fill",
                        color: .eventSleep,
                        isActive: viewModel.activeSleep != nil,
                        action: {
                            viewModel.quickLogSleep()
                        },
                        longPressAction: {
                            showSleepForm = true
                        }
                    )
                    
                    QuickActionButton(
                        title: "Feed",
                        icon: "drop.fill",
                        color: .eventFeed,
                        action: {
                            viewModel.quickLogFeed()
                        },
                        longPressAction: {
                            showFeedForm = true
                        }
                    )
                }
                
                HStack(spacing: .spacingMD) {
                    QuickActionButton(
                        title: "Diaper",
                        icon: "drop.circle.fill",
                        color: .eventDiaper,
                        action: {
                            viewModel.quickLogDiaper()
                        },
                        longPressAction: {
                            showDiaperForm = true
                        }
                    )
                    
                    QuickActionButton(
                        title: "Cry",
                        icon: "waveform",
                        color: .eventCry,
                        action: {
                            showCryRecorder = true
                        },
                        longPressAction: {
                            showCryRecorder = true
                        }
                    )
                }
            }
            .padding(.horizontal, .spacingLG)
        }
    }
    
    // MARK: - Today Timeline Section
    
    @ViewBuilder
    private var todayTimelineSection: some View {
        VStack(alignment: .leading, spacing: .spacingSM) {
            Text("Today")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.foreground)
                .padding(.horizontal, .spacingLG)

            if viewModel.events.isEmpty {
                todayEmptyState
            } else {
                if viewModel.events.count >= 8 && PolishFeatureFlags.shared.timelineGroupingEnabled {
                    groupedTodayTimeline
                } else {
                    simpleTodayTimeline
                }
            }
        }
    }

    @ViewBuilder
    private var simpleTodayTimeline: some View {
        ForEach(viewModel.events) { event in
            TimelineRow(
                event: event,
                onEdit: {
                    onEventEdited(event)
                },
                onDelete: {
                    Task {
                        await viewModel.deleteEvent(event)
                    }
                },
                onDuplicate: {
                    Task {
                        await viewModel.duplicateEvent(event)
                    }
                }
            )
            .padding(.horizontal, .spacingLG)
        }
    }

    @ViewBuilder
    private var groupedTodayTimeline: some View {
        let groupedEvents = groupEventsByTimeBlock(viewModel.events)

        ForEach(groupedEvents.keys.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { timeBlock in
            if let events = groupedEvents[timeBlock], !events.isEmpty {
                TimelineGroup(
                    events: events,
                    timeBlock: timeBlock,
                    onEventEdited: onEventEdited,
                    onEventDeleted: { event in
                        Task {
                            await viewModel.deleteEvent(event)
                        }
                    },
                    onEventDuplicated: { event in
                        Task {
                            await viewModel.duplicateEvent(event)
                        }
                    }
                )
                .padding(.horizontal, .spacingLG)
                .padding(.horizontal, .spacingLG)
            }
        }
    }
    
    @ViewBuilder
    private var todayEmptyState: some View {
        VStack(spacing: .spacingMD) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.mutedForeground)
            
            Text("Nothing logged yet")
                .font(.headline)
                .foregroundColor(.foreground)
            
            Text("Try logging the next feed or nap — I'll start learning \(babyName)'s rhythm")
                .font(.body)
                .foregroundColor(.mutedForeground)
                .multilineTextAlignment(.center)
                .padding(.horizontal, .spacingLG)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .spacing2XL)
    }
    
    // MARK: - AI Tease Section
    
    @ViewBuilder
    private var aiTeaseSection: some View {
        AITeaseCard(
            focusArea: focusArea,
            onCryAnalysisTap: {
                showCryRecorder = true
            },
            onQATap: {
                // TODO: Navigate to AI Q&A / Assistant view
                environment.navigationCoordinator.selectedTab = 2 // Labs tab for now
            }
        )
        .padding(.horizontal, .spacingLG)
    }

    @ViewBuilder
    private var predictiveSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: .spacingSM) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.body)
                    .foregroundColor(.primary)
                Text("Quick log")
                    .font(.body.weight(.medium))
                    .foregroundColor(.foreground)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: .spacingMD) {
                    ForEach(viewModel.predictiveSuggestions) { prediction in
                        PredictiveSuggestionButton(prediction: prediction) {
                            Task {
                                await viewModel.executePredictiveLog(prediction)
                            }
                        }
                    }
                }
                .padding(.vertical, .spacingXS)
            }
        }
        .padding(.horizontal, .spacingLG)
    }

    // MARK: - Helpers
    
    private var babyName: String {
        currentBaby?.name ?? "your baby"
    }

    // MARK: - Timeline Tab Content

    @ViewBuilder
    private var timelineTabContent: some View {
        ScrollView {
            VStack(spacing: .spacingSM) {
                // Filter controls
                if !viewModel.events.isEmpty {
                    HStack {
                        Text("Filter")
                            .font(.headline)
                            .foregroundColor(.foreground)

                        Spacer()

                        Menu {
                            Button(action: { viewModel.selectedFilter = .all }) {
                                Label("All Events", systemImage: "line.3.horizontal")
                            }
                            Button(action: { viewModel.selectedFilter = .feeds }) {
                                Label("Feeds", systemImage: "drop.fill")
                            }
                            Button(action: { viewModel.selectedFilter = .sleep }) {
                                Label("Sleep", systemImage: "moon.fill")
                            }
                            Button(action: { viewModel.selectedFilter = .diapers }) {
                                Label("Diapers", systemImage: "drop.circle.fill")
                            }
                            Button(action: { viewModel.selectedFilter = .tummy }) {
                                Label("Tummy Time", systemImage: "figure.child")
                            }
                            Button(action: { viewModel.selectedFilter = .cry }) {
                                Label("Cries", systemImage: "waveform")
                            }
                        } label: {
                            HStack {
                                Text(viewModel.selectedFilter.displayName)
                                    .font(.subheadline)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                            }
                            .foregroundColor(.primary)
                            .padding(.horizontal, .spacingMD)
                            .padding(.vertical, .spacingSM)
                            .background(Color.surface)
                            .cornerRadius(.radiusMD)
                        }
                    }
                    .padding(.horizontal, .spacingLG)
                }

                if viewModel.isLoading && viewModel.filteredEvents.isEmpty && PolishFeatureFlags.shared.skeletonLoadingEnabled {
                    // Show skeleton loading for timeline
                    SkeletonViews.TimelineSkeletonView()
                } else if viewModel.filteredEvents.isEmpty {
                    VStack(spacing: .spacingMD) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.mutedForeground)

                        Text("No events match this filter")
                            .font(.headline)
                            .foregroundColor(.foreground)

                        Text("Try changing your filter or log some events")
                            .font(.body)
                            .foregroundColor(.mutedForeground)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.vertical, .spacing2XL)
                } else {
                    groupedTimelineContent
                }
            }
            .padding(.bottom, .spacingXL)
        }
    }


    private func groupEventsByTimeBlock(_ events: [Event]) -> [TimelineGroupHeader.TimeBlock: [Event]] {
        var grouped: [TimelineGroupHeader.TimeBlock: [Event]] = [:]

        for event in events {
            let hour = Calendar.current.component(.hour, from: event.timestamp)
            let timeBlock = TimelineGroupHeader.TimeBlock.from(hour: hour)
            grouped[timeBlock, default: []].append(event)
        }

        return grouped
    }
}

// MARK: - Timeline Group Component

struct TimelineGroup: View {
    let events: [Event]
    let timeBlock: TimelineGroupHeader.TimeBlock
    let onEventEdited: (Event) -> Void
    let onEventDeleted: (Event) async -> Void
    let onEventDuplicated: (Event) async -> Void
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: .spacingXS) {
            TimelineGroupHeader(
                timeBlock: timeBlock,
                events: events,
                isExpanded: $isExpanded
            )

            if isExpanded {
                ForEach(events) { event in
                    TimelineRow(
                        event: event,
                        onEdit: {
                            onEventEdited(event)
                        },
                        onDelete: {
                            Task {
                                await onEventDeleted(event)
                            }
                        },
                        onDuplicate: {
                            Task {
                                await onEventDuplicated(event)
                            }
                        }
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .sheet(isPresented: $showWidgetOnboarding) {
            WidgetOnboardingView()
        }
    }
}

// QuickActionButton is defined in Design/Components/QuickActionButton.swift

#Preview {
    HomeContentView(
        viewModel: HomeViewModel(
            dataStore: InMemoryDataStore(),
            baby: Baby.mock(),
            showToast: { _, _ in }
        ),
        showFeedForm: .constant(false),
        showSleepForm: .constant(false),
        showDiaperForm: .constant(false),
        showTummyForm: .constant(false),
        showCryRecorder: .constant(false),
        editingEvent: .constant(nil),
        showToast: .constant(nil),
        showProSubscription: .constant(false),
        onBabySelected: { _ in },
        onEventEdited: { _ in }
    )
    .environmentObject(AppEnvironment(dataStore: InMemoryDataStore()))
}
