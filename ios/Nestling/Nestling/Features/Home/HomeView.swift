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
                            
                            // Quick Actions - Always show, even during loading
                            QuickActionsSection(
                                activeSleep: viewModel.activeSleep,
                                onFeed: { 
                                    print("Quick action Feed tapped")
                                    viewModel.quickLogFeed() 
                                },
                                onSleep: { 
                                    print("Quick action Sleep tapped")
                                    viewModel.quickLogSleep() 
                                },
                                onDiaper: { 
                                    print("Quick action Diaper tapped")
                                    viewModel.quickLogDiaper() 
                                },
                                onTummyTime: { 
                                    print("Quick action TummyTime tapped")
                                    viewModel.quickLogTummyTime() 
                                },
                                onOpenFeedForm: { showFeedForm = true },
                                onOpenSleepForm: { showSleepForm = true },
                                onOpenDiaperForm: { showDiaperForm = true },
                                onOpenTummyForm: { showTummyForm = true }
                            )
                            .padding(.horizontal, .spacingMD)
                            
                            // Timeline
                            timelineContent(for: viewModel)
                        }
                        .padding(.bottom, .spacingLG)
                    }
                } else if environment.babies.isEmpty {
                    // No babies - show empty state
                    VStack(spacing: .spacingMD) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.mutedForeground)
                        Text("No babies yet")
                            .font(.headline)
                            .foregroundColor(.foreground)
                        Text("Add a baby in Settings to get started")
                            .font(.body)
                            .foregroundColor(.mutedForeground)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Still loading
                    ProgressView()
                }
            }
            .navigationTitle("Home")
            .background(Color.background)
            .searchable(text: Binding(
                get: { viewModel?.searchText ?? "" },
                set: { viewModel?.searchText = $0 }
            ), suggestions: {
                ForEach(viewModel?.searchSuggestions ?? [], id: \.self) { suggestion in
                    Text(suggestion)
                        .searchCompletion(suggestion)
                }
            })
            .onChange(of: viewModel?.searchText ?? "") { _, newValue in
                if newValue.isEmpty {
                    viewModel?.selectedFilter = .all
                }
            }
            .task {
                // Wait a bit for environment to load babies, then create viewModel
                if viewModel == nil {
                    if let baby = environment.currentBaby {
                        updateViewModel(for: baby)
                    } else {
                        // Wait for babies to load
                        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                        if let baby = environment.currentBaby {
                            updateViewModel(for: baby)
                        } else if !environment.babies.isEmpty {
                            // If babies exist but currentBaby isn't set, use first one
                            environment.currentBaby = environment.babies.first
                            if let baby = environment.currentBaby {
                                updateViewModel(for: baby)
                            }
                        }
                    }
                }
            }
            .onChange(of: environment.currentBaby?.id) { _, _ in
                if let baby = environment.currentBaby {
                    updateViewModel(for: baby)
                }
            }
            .onChange(of: environment.babies.count) { _, _ in
                // If babies were loaded but currentBaby is nil, set it
                if environment.currentBaby == nil, let firstBaby = environment.babies.first {
                    environment.currentBaby = firstBaby
                    updateViewModel(for: firstBaby)
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
    
    @ViewBuilder
    private func timelineContent(for viewModel: HomeViewModel) -> some View {
        if viewModel.isLoading {
            LoadingStateView(message: "Loading events...")
                .frame(height: 200)
        } else {
            let isEmpty = viewModel.filteredEvents.isEmpty
            let noSearch = viewModel.searchText.isEmpty
            let allFilter = viewModel.selectedFilter == .all
            
            if isEmpty {
                EmptyStateView(
                    icon: noSearch && allFilter ? "calendar" : "magnifyingglass",
                    title: noSearch && allFilter ? "No events logged today" : "No matching events",
                    message: noSearch && allFilter ? "Start logging events to see them here" : "Try adjusting your search or filter"
                )
                .frame(height: 200)
            } else {
                // Filter chips
                FilterChipsView(
                    selectedFilter: Binding(
                        get: { viewModel.selectedFilter },
                        set: { viewModel.selectedFilter = $0 }
                    ),
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
                        let toastId = UUID()
                        showToast = ToastMessage(
                            id: toastId,
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
    }
    
    private func updateViewModel(for baby: Baby) {
        // Only create a new viewModel if we don't have one, or if the baby changed
        if let existingViewModel = viewModel, existingViewModel.baby.id == baby.id {
            print("updateViewModel: Keeping existing viewModel for baby \(baby.id)")
            return
        }
        print("updateViewModel: Creating new viewModel for baby \(baby.id)")
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

