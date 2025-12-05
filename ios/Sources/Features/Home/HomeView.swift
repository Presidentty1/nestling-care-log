import SwiftUI

struct HomeView: View {
    @EnvironmentObject var environment: AppEnvironment
    @State private var viewModel: HomeViewModel?
    @State private var showFeedForm = false
    @State private var showSleepForm = false
    @State private var showDiaperForm = false
    @State private var showTummyForm = false
    @State private var editingEvent: Event?
    @State private var showToast: ToastMessage?
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .topTrailing) {
                Group {
                    if let viewModel = viewModel {
                    ScrollView {
                        VStack(spacing: .spacingLG) {
                            // Baby Selector
                            if let baby = environment.currentBaby {
                                BabySelectorView(baby: baby, babies: environment.babies) { selectedBaby in
                                    environment.currentBaby = selectedBaby
                                    updateViewModel(for: selectedBaby)
                                }
                                .padding(.horizontal, .spacingMD)
                            }

                            // First Log Card (shown after onboarding)
                            if viewModel.shouldShowFirstLogCard {
                                FirstLogCardView {
                                    // Open feed logging form
                                    showFeedForm = true
                                }
                                .padding(.top, .spacingMD)
                            }

                            // Trial Offer Banner
                            if viewModel.shouldShowTrialOffer {
                                TrialOfferBanner(
                                    onTryPro: {
                                        // Navigate to Pro subscription view
                                        // For now, just dismiss and show a message
                                        viewModel.dismissTrialOffer()
                                        // TODO: Navigate to ProSubscriptionView
                                    },
                                    onDismiss: {
                                        viewModel.dismissTrialOffer()
                                    }
                                )
                                .padding(.top, .spacingMD)
                            }

                            // Weekly Tip
                            if let tip = viewModel.currentTip {
                                TipCard(tip: tip, onDismiss: {
                                    viewModel.dismissCurrentTip()
                                })
                                .padding(.top, .spacingMD)
                            }

                            // New Achievements
                            if !viewModel.newAchievements.isEmpty {
                                VStack(alignment: .leading, spacing: .spacingMD) {
                                    HStack {
                                        Image(systemName: "trophy.fill")
                                            .foregroundColor(.yellow)
                                        Text("New Achievements!")
                                            .font(.headline)
                                            .foregroundColor(Color.adaptiveForeground(colorScheme))

                                        Spacer()

                                        Button(action: {
                                            viewModel.dismissNewAchievements()
                                        }) {
                                            Image(systemName: "xmark")
                                                .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                                                .font(.system(size: 16))
                                        }
                                    }

                                    AchievementGrid(achievements: viewModel.newAchievements)
                                }
                                .padding(.spacingMD)
                                .background(Color.adaptiveSurface(colorScheme))
                                .cornerRadius(.radiusMD)
                                .padding(.horizontal, .spacingMD)
                                .padding(.top, .spacingMD)
                            }

                            // Summary Cards (stats tiles - Today tiles)
                            if let summary = viewModel.summary {
                                SummaryCardsView(summary: summary) { filter in
                                    withAnimation {
                                        // Toggle back to .all if tapping the same filter
                                        if viewModel.selectedFilter == filter {
                                            viewModel.selectedFilter = .all
                                        } else {
                                            viewModel.selectedFilter = filter
                                        }
                                    }
                                }
                                .padding(.horizontal, .spacingMD)
                            }

                            // Guidance Strip (Epic 4) - three-segment "Now / Next Nap / Next Feed"
                            if let baby = environment.currentBaby {
                                GuidanceStripView(dataStore: environment.dataStore, baby: baby)
                                    .padding(.horizontal, .spacingMD)
                            }

                            // Quick Actions (Quick Log) - Epic 3: Context-aware
                            if let baby = environment.currentBaby {
                                QuickActionsSection(
                                    activeSleep: viewModel.activeSleep,
                                    baby: baby,
                                    events: viewModel.events,
                                    onFeed: { viewModel.quickLogFeed() },
                                    onSleep: { viewModel.quickLogSleep() },
                                    onDiaper: { viewModel.quickLogDiaper() },
                                    onTummyTime: { viewModel.quickLogTummyTime() },
                                    onOpenFeedForm: { showFeedForm = true },
                                    onOpenSleepForm: { showSleepForm = true },
                                    onOpenDiaperForm: { showDiaperForm = true },
                                    onOpenTummyForm: { showTummyForm = true }
                                )
                                .padding(.horizontal, .spacingMD)
                            }
                            
                            // Timeline filters
                            if !viewModel.filteredEvents.isEmpty {
                                FilterChipsView(
                                    selectedFilter: $viewModel.selectedFilter,
                                    filters: EventTypeFilter.allCases
                                )
                                .padding(.horizontal, .spacingMD)
                                .padding(.vertical, .spacingSM)
                            }
                            
                            // Timeline list
                            if viewModel.isLoading {
                                LoadingStateView(message: "Loading events...")
                                    .frame(height: 200)
                            } else if viewModel.filteredEvents.isEmpty {
                                EmptyStateView(
                                    icon: viewModel.searchText.isEmpty && viewModel.selectedFilter == .all ? "calendar" : "magnifyingglass",
                                    title: viewModel.searchText.isEmpty && viewModel.selectedFilter == .all ? "Ready to start logging?" : "No matching events",
                                    message: viewModel.searchText.isEmpty && viewModel.selectedFilter == .all ? "Log your first feed, diaper, or sleep to unlock nap predictions and insights" : "Try adjusting your search or filter",
                                    actionTitle: viewModel.searchText.isEmpty && viewModel.selectedFilter == .all ? "Log First Event" : nil
                                ) {
                                    // Open quick log or feed form
                                    showFeedForm = true
                                }
                                .frame(height: 200)
                            } else {
                                // Example data banner (Epic 1 AC7)
                                if viewModel.hasExampleData {
                                    ExampleDataBanner()
                                        .padding(.horizontal, .spacingMD)
                                        .padding(.bottom, .spacingSM)
                                }
                                
                                TimelineSection(
                                    events: viewModel.filteredEvents,
                                    onEdit: { event in
                                        editingEvent = event
                                        showFormForEvent(event)
                                    },
                                    onDelete: { event in
                                        viewModel.deleteEvent(event)
                                        // Show undo toast
                                        showToast = ToastMessage(
                                            message: "Event deleted",
                                            type: .success,
                                            undoAction: {
                                                Task {
                                                    do {
                                                        try await viewModel.undoDeletion()
                                                        showToast = ToastMessage(message: "Event restored", type: .success)
                                                    } catch {
                                                        showToast = ToastMessage(message: "Could not undo: \(error.localizedDescription)", type: .error)
                                                    }
                                                }
                                            }
                                        )
                                        // Auto-dismiss after 7 seconds
                                        let toastId = showToast?.id
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
                                            if showToast?.id == toastId {
                                                showToast = nil
                                            }
                                        }
                                    },
                                    onDuplicate: { event in
                                        viewModel.duplicateEvent(event)
                                        showToast = ToastMessage(message: "Event duplicated", type: .success)
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            showToast = nil
                                        }
                                    }
                                )
                                .padding(.horizontal, .spacingMD)
                            }
                        }
                        .padding(.vertical, .spacingMD)
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Today")
                .background(NuzzleTheme.background)
            .searchable(text: $viewModel.searchText, suggestions: {
                ForEach(viewModel.searchSuggestions, id: \.self) { suggestion in
                    Text(suggestion)
                        .searchCompletion(suggestion)
                }
            })
            .onChange(of: viewModel.searchText) { _, newValue in
                if newValue.isEmpty {
                    viewModel.selectedFilter = .all
                }
            }
            .task {
                if let baby = environment.currentBaby, viewModel == nil {
                    updateViewModel(for: baby)
                }

                // Check for review prompt
                if ReviewPromptManager.shared.shouldShowReviewPrompt() {
                    // Trigger review prompt after a brief delay to ensure UI is ready
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let rootVC = windowScene.windows.first?.rootViewController {
                            ReviewPromptManager.shared.requestReviewIfAppropriate(from: rootVC)
                        }
                    }
                }
            }
            .onChange(of: environment.currentBaby?.id) { _, _ in
                if let baby = environment.currentBaby {
                    updateViewModel(for: baby)
                }
            }
            .onChange(of: environment.navigationCoordinator.showFeedForm) { _, newValue in
                if newValue {
                    showFeedForm = true
                }
            }
            .onChange(of: environment.navigationCoordinator.showSleepForm) { _, newValue in
                if newValue {
                    showSleepForm = true
                }
            }
            .onChange(of: environment.navigationCoordinator.showDiaperForm) { _, newValue in
                if newValue {
                    showDiaperForm = true
                }
            }
            .onChange(of: environment.navigationCoordinator.showTummyForm) { _, newValue in
                if newValue {
                    showTummyForm = true
                }
            }
            .sheet(isPresented: $showFeedForm) {
                if let baby = environment.currentBaby {
                    let feedViewModel = FeedFormViewModel(
                        dataStore: environment.dataStore,
                        baby: baby,
                        editingEvent: editingEvent
                    )
                    SheetDetentWrapper(
                        preferMedium: environment.appSettings.preferMediumSheet,
                        isSaving: feedViewModel.isSaving
                    ) {
                        FeedFormView(viewModel: feedViewModel)
                            .onDisappear {
                                editingEvent = nil
                                viewModel?.loadTodayEvents()
                                environment.navigationCoordinator.showFeedForm = false
                                environment.navigationCoordinator.clearPrefillData()
                            }
                    }
                }
            }
            .sheet(isPresented: $showSleepForm) {
                if let baby = environment.currentBaby {
                    let sleepViewModel = SleepFormViewModel(
                        dataStore: environment.dataStore,
                        baby: baby,
                        editingEvent: editingEvent
                    )
                    SheetDetentWrapper(
                        preferMedium: environment.appSettings.preferMediumSheet,
                        isSaving: sleepViewModel.isSaving
                    ) {
                        SleepFormView(viewModel: sleepViewModel)
                            .onDisappear {
                                editingEvent = nil
                                viewModel?.loadTodayEvents()
                                viewModel?.checkActiveSleep()
                                environment.navigationCoordinator.showSleepForm = false
                            }
                    }
                }
            }
            .sheet(isPresented: $showDiaperForm) {
                if let baby = environment.currentBaby {
                    let diaperViewModel = DiaperFormViewModel(
                        dataStore: environment.dataStore,
                        baby: baby,
                        editingEvent: editingEvent
                    )
                    SheetDetentWrapper(
                        preferMedium: environment.appSettings.preferMediumSheet,
                        isSaving: diaperViewModel.isSaving
                    ) {
                        DiaperFormView(viewModel: diaperViewModel)
                            .onDisappear {
                                editingEvent = nil
                                viewModel?.loadTodayEvents()
                                environment.navigationCoordinator.showDiaperForm = false
                                environment.navigationCoordinator.clearPrefillData()
                            }
                    }
                }
            }
            .sheet(isPresented: $showTummyForm) {
                if let baby = environment.currentBaby {
                    let tummyViewModel = TummyTimeFormViewModel(
                        dataStore: environment.dataStore,
                        baby: baby,
                        editingEvent: editingEvent
                    )
                    SheetDetentWrapper(
                        preferMedium: environment.appSettings.preferMediumSheet,
                        isSaving: tummyViewModel.isSaving
                    ) {
                        TummyTimeFormView(viewModel: tummyViewModel)
                            .onDisappear {
                                editingEvent = nil
                                viewModel?.loadTodayEvents()
                                environment.navigationCoordinator.showTummyForm = false
                                environment.navigationCoordinator.clearPrefillData()
                            }
                    }
                }
            }
            .toast($showToast)
        }
    }
    
    private func updateViewModel(for baby: Baby) {
        viewModel = HomeViewModel(dataStore: environment.dataStore, baby: baby)
    }
    
    private func showFormForEvent(_ event: Event) {
        switch event.type {
        case .feed:
            showFeedForm = true
        case .sleep:
            showSleepForm = true
        case .diaper:
            showDiaperForm = true
        case .tummyTime:
            showTummyForm = true
        }
    }
}

// MARK: - Baby Selector

struct BabySelectorView: View {
    let baby: Baby
    let babies: [Baby]
    let onSelect: (Baby) -> Void
    
    var body: some View {
        Menu {
            ForEach(babies) { b in
                Button(action: { onSelect(b) }) {
                    HStack {
                        Text(b.name)
                        if b.id == baby.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            .overlay(alignment: .top) {
                OfflineIndicator()
                    .padding(.top, .spacingMD)
                    .padding(.trailing, .spacingMD)
            }
        } label: {
            HStack {
                Text(baby.name)
                    .font(.title)
                    .foregroundColor(.foreground)
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(.mutedForeground)
            }
            .padding(.spacingMD)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(NuzzleTheme.surface)
            .cornerRadius(.radiusMD)
        }
    }
}

// MARK: - Summary Cards

struct SummaryCardsView: View {
    let summary: DaySummary
    let onFilterSelected: (EventTypeFilter) -> Void
    
    var body: some View {
        HStack(spacing: .spacingSM) {
            SummaryCard(
                title: "Feeds",
                value: "\(summary.feedCount)",
                icon: "drop.fill",
                color: .eventFeed
            )
            .onTapGesture {
                onFilterSelected(.feeds)
            }
            
            SummaryCard(
                title: "Diapers",
                value: "\(summary.diaperCount)",
                icon: "drop.circle.fill",
                color: .eventDiaper
            )
            .onTapGesture {
                onFilterSelected(.diapers)
            }
            
            SummaryCard(
                title: "Sleep",
                value: summary.sleepDisplay,
                icon: "moon.fill",
                color: .eventSleep
            )
            .onTapGesture {
                onFilterSelected(.sleep)
            }
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: .spacingSM) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.foreground)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.mutedForeground)
        }
        .frame(maxWidth: .infinity)
        .padding(.spacingMD)
        .background(NuzzleTheme.surface)
        .cornerRadius(.radiusMD)
    }
}

// MARK: - Quick Actions

struct QuickActionsSection: View {
    let activeSleep: Event?
    let baby: Baby
    let events: [Event]
    let onFeed: () -> Void
    let onSleep: () -> Void
    let onDiaper: () -> Void
    let onTummyTime: () -> Void
    let onOpenFeedForm: () -> Void
    let onOpenSleepForm: () -> Void
    let onOpenDiaperForm: () -> Void
    let onOpenTummyForm: () -> Void
    
    // Epic 3 AC2: Context-aware primary action
    private var timeSinceLastFeed: TimeInterval? {
        let lastFeed = events
            .filter { $0.type == .feed }
            .sorted { $0.startTime > $1.startTime }
            .first
        guard let lastFeed = lastFeed else { return nil }
        return Date().timeIntervalSince(lastFeed.startTime)
    }
    
    private var shouldEmphasizeFeed: Bool {
        guard let timeSince = timeSinceLastFeed else { return false }
        // Emphasize if >= 2.5 hours (Epic 3 AC2)
        return timeSince >= 2.5 * 3600
    }
    
    private var isBabyAwake: Bool {
        activeSleep == nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: .spacingSM) {
            Text("Quick Actions")
                .font(.title)
                .foregroundColor(.foreground)
            
            HStack(spacing: .spacingSM) {
                QuickActionButton(
                    title: "Feed",
                    isEmphasized: shouldEmphasizeFeed, // Epic 3 AC2: Visual emphasis
                    icon: "drop.fill",
                    color: .eventFeed,
                    action: onFeed,
                    longPressAction: onOpenFeedForm
                )
                
                // Epic 3 AC2: Context-aware sleep button
                QuickActionButton(
                    title: activeSleep != nil ? "Stop Sleep" : (isBabyAwake ? "Start Nap" : "Sleep"),
                    icon: "moon.fill",
                    color: .eventSleep,
                    isActive: activeSleep != nil,
                    action: onSleep,
                    longPressAction: onOpenSleepForm
                )
                
                QuickActionButton(
                    title: "Diaper",
                    icon: "drop.circle.fill",
                    color: .eventDiaper,
                    action: onDiaper,
                    longPressAction: onOpenDiaperForm
                )
                
                QuickActionButton(
                    title: "Tummy",
                    icon: "figure.child",
                    color: .eventTummy,
                    action: onTummyTime,
                    longPressAction: onOpenTummyForm
                )
            }
        }
    }
}

// MARK: - Timeline

struct TimelineSection: View {
    let events: [Event]
    let onEdit: (Event) -> Void
    let onDelete: (Event) -> Void
    let onDuplicate: ((Event) -> Void)?
    
    init(events: [Event], onEdit: @escaping (Event) -> Void, onDelete: @escaping (Event) -> Void, onDuplicate: ((Event) -> Void)? = nil) {
        self.events = events
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onDuplicate = onDuplicate
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: .spacingSM) {
            Text("Timeline")
                .font(.title)
                .foregroundColor(.foreground)
            
            ForEach(events) { event in
                TimelineRow(
                    event: event,
                    onEdit: { onEdit(event) },
                    onDelete: { onDelete(event) },
                    onDuplicate: onDuplicate.map { dup in { dup(event) } }
                )
            }
        }
    }
}

/// Next Nap Prediction Card
struct NextNapCard: View {
    let prediction: Prediction
    
    var body: some View {
        let minutesUntil = Calendar.current.dateComponents([.minute], from: Date(), to: prediction.predictedTime).minute ?? 0
        let timeUntil = formatTimeUntil(minutes: minutesUntil)
        
        CardView(variant: .info) {
            HStack(spacing: .spacingMD) {
                Image(systemName: "moon.fill")
                    .font(.title2)
                    .foregroundColor(.eventSleep)
                
                VStack(alignment: .leading, spacing: .spacingXS) {
                    Text("Next nap")
                        .font(.headline)
                        .foregroundColor(.foreground)
                    
                    if minutesUntil > 0 {
                        Text("Around \(formatTime(prediction.predictedTime)) (in \(timeUntil))")
                            .font(.body)
                            .foregroundColor(.foreground)
                    } else {
                        Text("Around \(formatTime(prediction.predictedTime))")
                            .font(.body)
                            .foregroundColor(.foreground)
                    }
                    
                    Text(prediction.explanation)
                        .font(.caption)
                        .foregroundColor(.mutedForeground)
                }
                
                Spacer()
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatTimeUntil(minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) min"
        }
        let hours = minutes / 60
        let mins = minutes % 60
        return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
    }
}

#Preview {
    HomeView()
        .environmentObject(AppEnvironment(dataStore: InMemoryDataStore()))
}

