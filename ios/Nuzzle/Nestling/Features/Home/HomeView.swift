import SwiftUI

struct HomeView: View {
    @EnvironmentObject var environment: AppEnvironment
    @State private var viewModel: HomeViewModel?
    @State private var showFeedForm = false
    @State private var showSleepForm = false
    @State private var showDiaperForm = false
    @State private var showTummyForm = false
    @State private var showCryRecorder = false
    @State private var editingEvent: Event?
    @State private var showToast: ToastMessage?
    @State private var showProSubscription = false
    @State private var showFabMenu = false
    @State private var showTutorial = false
    @State private var hasCheckedTrialExpiration = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            navigationContent
            
            // Spotlight Tutorial Overlay (Phase 3)
            if showTutorial {
                SpotlightTutorialOverlay(isPresented: $showTutorial) {
                    // Mark tutorial as seen
                    UserDefaults.standard.set(true, forKey: "hasSeenHomeTutorial")
                }
                .zIndex(1000)
            }
            
            // Floating Action Button (North Star)
            VStack(alignment: .trailing, spacing: .spacingSM) {
                if showFabMenu {
                    fabActionButton(title: "Diaper", icon: "drop.circle.fill", color: .eventDiaper) {
                        showFabMenu = false
                        showDiaperForm = true
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    
                    fabActionButton(title: "Sleep", icon: "moon.fill", color: .eventSleep) {
                        showFabMenu = false
                        showSleepForm = true
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    
                    fabActionButton(title: "Feed", icon: "drop.fill", color: .eventFeed) {
                        showFabMenu = false
                        showFeedForm = true
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        showFabMenu.toggle()
                    }
                    Haptics.light()
                }) {
                    Image(systemName: "plus")
                        .font(.title.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.primary.opacity(1.1),
                                    Color.primary
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: Color.primary.opacity(0.4), radius: 12, x: 0, y: 6)
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        .rotationEffect(.degrees(showFabMenu ? 45 : 0))
                        .scaleEffect(showFabMenu ? 1.05 : 1.0)
                }
            }
            .padding(.spacingLG)
            
            // Offline Indicator (Epic 4)
            VStack {
                OfflineIndicatorView()
                Spacer()
            }
            .padding(.top, 40) // Safe area padding
        }
    }
    
    private func fabActionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: {
            Haptics.selection()
            action()
        }) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.foreground)
                    .padding(.horizontal, .spacingSM)
                    .padding(.vertical, .spacingXS)
                    .background(Color.surface)
                    .cornerRadius(.radiusSM)
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
                
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(color)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
            }
        }
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
            .sheet(isPresented: $showCryRecorder) {
                if let baby = environment.currentBaby {
                    CryRecorderView(dataStore: environment.dataStore, baby: baby)
                }
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
                await checkAndShowTrialExpiredPaywall()
            }
            .onAppear {
                // Check trial status whenever Home appears
                Task {
                    await checkAndShowTrialExpiredPaywall()
                }
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
                showCryRecorder: $showCryRecorder,
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
            
            // Show tutorial on first visit (Phase 3)
            await MainActor.run {
                let hasSeenTutorial = UserDefaults.standard.bool(forKey: "hasSeenHomeTutorial")
                if !hasSeenTutorial {
                    // Delay tutorial slightly so user sees the home screen first
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        showTutorial = true
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
            logger.debug("updateViewModel: Keeping existing viewModel for baby \(baby.id)")
            return
        }
        logger.debug("updateViewModel: Creating new viewModel for baby \(baby.id)")
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
    
    /// Check if trial has expired and show paywall
    private func checkAndShowTrialExpiredPaywall() async {
        // Only check once per app launch
        guard !hasCheckedTrialExpiration else { return }
        hasCheckedTrialExpiration = true
        
        let proService = ProSubscriptionService.shared
        
        // If trial has ended (0 days remaining) and user is not Pro, show paywall
        if let daysRemaining = proService.trialDaysRemaining,
           daysRemaining <= 0,
           !proService.isProUser {
            
            // Delay slightly to let Home render first
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            await MainActor.run {
                showProSubscription = true
            }
            
            // Analytics: Trial ended paywall shown
            await Analytics.shared.logPaywallViewed(source: "trial_ended")
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
    let onCryAnalysis: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: .spacingSM) {
            Text("Quick Actions")
                .font(.title)
                .foregroundColor(.foreground)
            
            // Balanced 2x2 Grid - Most-used actions
            VStack(spacing: .spacingMD) {
                HStack(spacing: .spacingMD) {
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
                }
                
                HStack(spacing: .spacingMD) {
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

// MARK: - Home Content View (Moved to HomeContentView.swift)
// The implementation has been moved to its own file for better maintainability and dynamic layout support.


#Preview {
    HomeView()
        .environmentObject(AppEnvironment(dataStore: InMemoryDataStore()))
}

