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
    @State private var showProSubscription = false
    
    var body: some View {
        navigationContent
    }
    
    private var navigationContent: some View {
        viewWithChangeHandlers
            .sheet(isPresented: $showFeedForm) {
                feedFormSheet
            }
            .sheet(isPresented: $showSleepForm) {
                sleepFormSheet
            }
            .sheet(isPresented: $showDiaperForm) {
                diaperFormSheet
            }
            .sheet(isPresented: $showTummyForm) {
                tummyFormSheet
            }
            .sheet(isPresented: $showProSubscription) {
                ProSubscriptionView()
            }
            .toast($showToast)
    }
    
    private var baseNavigationView: some View {
        NavigationStack {
            mainContent
        }
        .navigationTitle("Home")
        .background(Color.background)
        .searchable(text: searchTextBinding, suggestions: {
            searchSuggestions
        })
    }
    
    private var viewWithChangeHandlers: some View {
        baseNavigationView
            .onChange(of: viewModel?.searchText ?? "") { _, newValue in
                if newValue.isEmpty {
                    viewModel?.selectedFilter = .all
                }
            }
            .task {
                await initializeViewModel()
            }
            .onChange(of: environment.currentBaby?.id) { _, _ in
                if let baby = environment.currentBaby {
                    updateViewModel(for: baby)
                }
            }
            .onChange(of: environment.babies.count) { _, _ in
                if environment.currentBaby == nil, let firstBaby = environment.babies.first {
                    environment.currentBaby = firstBaby
                    updateViewModel(for: firstBaby)
                }
            }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if let viewModel = viewModel {
            HomeContentView(
                viewModel: viewModel,
                showFeedForm: $showFeedForm,
                showSleepForm: $showSleepForm,
                showDiaperForm: $showDiaperForm,
                showTummyForm: $showTummyForm,
                editingEvent: $editingEvent,
                showToast: $showToast,
                showProSubscription: $showProSubscription,
                onBabySelected: { selectedBaby in
                    environment.currentBaby = selectedBaby
                    updateViewModel(for: selectedBaby)
                },
                onEventEdited: { event in
                    editingEvent = event
                    showFormForEvent(event)
                }
            )
        } else if environment.babies.isEmpty {
            emptyStateView
        } else {
            ProgressView()
        }
    }
    
    private var emptyStateView: some View {
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
    }
    
    private var searchTextBinding: Binding<String> {
        Binding(
            get: { viewModel?.searchText ?? "" },
            set: { viewModel?.searchText = $0 }
        )
    }
    
    @ViewBuilder
    private var searchSuggestions: some View {
        ForEach(viewModel?.searchSuggestions ?? [], id: \.self) { suggestion in
            Text(suggestion)
                .searchCompletion(suggestion)
        }
    }
    
    private func initializeViewModel() async {
        if viewModel == nil {
            if let baby = environment.currentBaby {
                updateViewModel(for: baby)
            } else {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                if let baby = environment.currentBaby {
                    updateViewModel(for: baby)
                } else if !environment.babies.isEmpty {
                    environment.currentBaby = environment.babies.first
                    if let baby = environment.currentBaby {
                        updateViewModel(for: baby)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var feedFormSheet: some View {
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
                        Task {
                            await viewModel?.loadTodayEvents()
                        }
                        environment.navigationCoordinator.showFeedForm = false
                        environment.navigationCoordinator.clearPrefillData()
                    }
            }
        }
    }
    
    @ViewBuilder
    private var sleepFormSheet: some View {
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
                        Task {
                            await viewModel?.loadTodayEvents()
                        }
                        viewModel?.checkActiveSleep()
                        environment.navigationCoordinator.showSleepForm = false
                    }
            }
        }
    }
    
    @ViewBuilder
    private var diaperFormSheet: some View {
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
                        Task {
                            await viewModel?.loadTodayEvents()
                        }
                        environment.navigationCoordinator.showDiaperForm = false
                        environment.navigationCoordinator.clearPrefillData()
                    }
            }
        }
    }
    
    @ViewBuilder
    private var tummyFormSheet: some View {
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
                        Task {
                            await viewModel?.loadTodayEvents()
                        }
                        environment.navigationCoordinator.showTummyForm = false
                        environment.navigationCoordinator.clearPrefillData()
                    }
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
        viewModel = HomeViewModel(
            dataStore: environment.dataStore,
            baby: baby,
            showToast: { title, message in
                let combinedMessage = title.isEmpty ? message : "\(title): \(message)"
                showToast = ToastMessage(message: combinedMessage, type: .info)
            }
        )
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

// MARK: - Home Content View (Properly Observes ViewModel)

struct HomeContentView: View {
    @ObservedObject var viewModel: HomeViewModel
    @EnvironmentObject var environment: AppEnvironment
    @Binding var showFeedForm: Bool
    @Binding var showSleepForm: Bool
    @Binding var showDiaperForm: Bool
    @Binding var showTummyForm: Bool
    @Binding var editingEvent: Event?
    @Binding var showToast: ToastMessage?
    @Binding var showProSubscription: Bool
    let onBabySelected: (Baby) -> Void
    let onEventEdited: (Event) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: .spacingLG) {
                // Baby Selector
                if let baby = environment.currentBaby {
                    BabySelectorView(baby: baby, babies: environment.babies) { selectedBaby in
                        onBabySelected(selectedBaby)
                    }
                    .padding(.horizontal, .spacingMD)
                }
                
                // Summary Cards
                if let summary = viewModel.summary {
                    SummaryCardsView(summary: summary)
                        .padding(.horizontal, .spacingMD)
                }

                // Today's Insight (Personalized Recommendations) - Pro Feature
                if let topRecommendation = viewModel.recommendations.first {
                    FeatureGate.check(.todaysInsight, accessible: {
                        TodaysInsightCard(recommendation: topRecommendation)
                            .padding(.horizontal, .spacingMD)
                            .onTapGesture {
                                // Handle recommendation tap - could show detail or dismiss
                                Haptics.light()
                            }
                    }, paywall: {
                        // Show upgrade prompt for non-Pro users
                        TodaysInsightCard(recommendation: topRecommendation)
                            .padding(.horizontal, .spacingMD)
                            .blur(radius: 4)
                            .overlay(
                                // Semi-transparent overlay to make button stand out
                                Color.background.opacity(0.3)
                                    .overlay(
                                        VStack {
                                            Spacer()
                                            PrimaryButton("Upgrade to Pro", icon: "star.fill") {
                                                showProSubscription = true
                                            }
                                            .padding(.horizontal, .spacingMD)
                                            Spacer()
                                        }
                                    )
                            )
                            .onTapGesture {
                                showProSubscription = true
                            }
                    })
                }

                // Streaks & Milestones
                if viewModel.currentStreak > 0 || viewModel.longestStreak > 0 {
                    StreaksView(currentStreak: viewModel.currentStreak, longestStreak: viewModel.longestStreak)
                        .padding(.horizontal, .spacingMD)
                }

                // Quick Actions - Always show, even during loading
                QuickActionsSection(
                    activeSleep: viewModel.activeSleep,
                    onFeed: { 
                        print("🔵 HomeContentView: Quick action Feed tapped")
                        print("🔵 HomeContentView: Calling viewModel.quickLogFeed()")
                        viewModel.quickLogFeed()
                        print("🔵 HomeContentView: viewModel.quickLogFeed() called")
                    },
                    onSleep: { 
                        print("🔵 HomeContentView: Quick action Sleep tapped")
                        viewModel.quickLogSleep() 
                    },
                    onDiaper: { 
                        print("🔵 HomeContentView: Quick action Diaper tapped")
                        viewModel.quickLogDiaper() 
                    },
                    onTummyTime: { 
                        print("🔵 HomeContentView: Quick action TummyTime tapped")
                        viewModel.quickLogTummyTime() 
                    },
                    onOpenFeedForm: { 
                        print("🔵 HomeContentView: Opening feed form")
                        showFeedForm = true 
                    },
                    onOpenSleepForm: { 
                        print("🔵 HomeContentView: Opening sleep form")
                        showSleepForm = true 
                    },
                    onOpenDiaperForm: { 
                        print("🔵 HomeContentView: Opening diaper form")
                        showDiaperForm = true 
                    },
                    onOpenTummyForm: { 
                        print("🔵 HomeContentView: Opening tummy form")
                        showTummyForm = true 
                    }
                )
                .padding(.horizontal, .spacingMD)
                
                // Timeline
                timelineContent(for: viewModel)
            }
            .padding(.bottom, .spacingLG)
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
                    onEdit: onEventEdited,
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
}

#Preview {
    HomeView()
        .environmentObject(AppEnvironment(dataStore: InMemoryDataStore()))
}

