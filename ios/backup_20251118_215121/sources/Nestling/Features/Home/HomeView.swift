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
                            
                            // Summary Cards
                            if let summary = viewModel.summary {
                                SummaryCardsView(summary: summary)
                                    .padding(.horizontal, .spacingMD)
                            }
                            
                            // Quick Actions
                            QuickActionsSection(
                                activeSleep: viewModel.activeSleep,
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
                            
                            // Timeline
                            if viewModel.isLoading {
                                LoadingStateView(message: "Loading events...")
                                    .frame(height: 200)
                            } else if viewModel.filteredEvents.isEmpty {
                                EmptyStateView(
                                    icon: viewModel.searchText.isEmpty && viewModel.selectedFilter == .all ? "calendar" : "magnifyingglass",
                                    title: viewModel.searchText.isEmpty && viewModel.selectedFilter == .all ? "No events logged today" : "No matching events",
                                    message: viewModel.searchText.isEmpty && viewModel.selectedFilter == .all ? "Start logging events to see them here" : "Try adjusting your search or filter"
                                )
                                .frame(height: 200)
                            } else {
                                // Filter chips
                                FilterChipsView(
                                    selectedFilter: $viewModel.selectedFilter,
                                    filters: EventTypeFilter.allCases
                                )
                                .padding(.vertical, .spacingSM)
                                
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
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
                                            if showToast?.id == showToast?.id {
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
            .background(Color.background)
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
            .background(Color.surface)
            .cornerRadius(.radiusMD)
        }
    }
}

// MARK: - Summary Cards

struct SummaryCardsView: View {
    let summary: DaySummary
    
    var body: some View {
        HStack(spacing: .spacingSM) {
            SummaryCard(
                title: "Feeds",
                value: "\(summary.feedCount)",
                icon: "drop.fill",
                color: .eventFeed
            )
            
            SummaryCard(
                title: "Diapers",
                value: "\(summary.diaperCount)",
                icon: "drop.circle.fill",
                color: .eventDiaper
            )
            
            SummaryCard(
                title: "Sleep",
                value: summary.sleepDisplay,
                icon: "moon.fill",
                color: .eventSleep
            )
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
        .background(Color.surface)
        .cornerRadius(.radiusMD)
    }
}

// MARK: - Quick Actions

struct QuickActionsSection: View {
    let activeSleep: Event?
    let onFeed: () -> Void
    let onSleep: () -> Void
    let onDiaper: () -> Void
    let onTummyTime: () -> Void
    let onOpenFeedForm: () -> Void
    let onOpenSleepForm: () -> Void
    let onOpenDiaperForm: () -> Void
    let onOpenTummyForm: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: .spacingSM) {
            Text("Quick Actions")
                .font(.title)
                .foregroundColor(.foreground)
            
            HStack(spacing: .spacingSM) {
                QuickActionButton(
                    title: "Feed",
                    icon: "drop.fill",
                    color: .eventFeed,
                    action: onFeed,
                    longPressAction: onOpenFeedForm
                )
                
                QuickActionButton(
                    title: activeSleep != nil ? "Stop Sleep" : "Sleep",
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

#Preview {
    HomeView()
        .environmentObject(AppEnvironment(dataStore: InMemoryDataStore()))
}

