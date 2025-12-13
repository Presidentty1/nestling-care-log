import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var environment: AppEnvironment
    @State private var viewModel: HistoryViewModel?
    @State private var showFeedForm = false
    @State private var showSleepForm = false
    @State private var showDiaperForm = false
    @State private var showTummyForm = false
    @State private var editingEvent: Event?
    @State private var showToast: ToastMessage?
    @State private var selectedEvent: Event?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    ObservedViewModel(viewModel) { vm in
                        VStack(spacing: .spacingMD) {
                            header(vm)
                            content(vm)
                        }
                        .padding(.top, .spacingSM)
                    }
                } else if environment.babies.isEmpty {
                    emptyBabiesView
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("History")
            .background(Color.background)
            .searchable(
                text: Binding(
                    get: { viewModel?.searchText ?? "" },
                    set: { viewModel?.searchText = $0 }
                ),
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: "Search notes, times, amounts..."
            ) {
                ForEach(viewModel?.searchSuggestions ?? [], id: \.self) { suggestion in
                    Text(suggestion).searchCompletion(suggestion)
                }
            }
            .onChange(of: viewModel?.searchText ?? "") { _, newValue in
                if newValue.isEmpty {
                    viewModel?.selectedFilter = .all
                }
            }
            .task {
                await setupViewModelIfNeeded()
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
            .sheet(isPresented: $showFeedForm) { feedSheet }
            .sheet(isPresented: $showSleepForm) { sleepSheet }
            .sheet(isPresented: $showDiaperForm) { diaperSheet }
            .sheet(isPresented: $showTummyForm) { tummySheet }
            .sheet(item: $selectedEvent) { event in
                if let baby = environment.currentBaby {
                    EventDetailView(
                        event: event,
                        baby: baby,
                        onEdit: {
                            editingEvent = event
                            showFormForEvent(event)
                        },
                        onDelete: {
                            Task { await viewModel?.deleteEvent(event) }
                        },
                        onClose: { selectedEvent = nil }
                    )
                }
            }
            .toast($showToast)
        }
    }

    // MARK: - Sections

    private func header(_ vm: HistoryViewModel) -> some View {
        VStack(spacing: .spacingSM) {
            HistoryRangeSelector(
                selectedRange: Binding(
                    get: { vm.selectedRange },
                    set: { newValue in
                        Task { await vm.onRangeChanged(newValue) }
                    }
                )
            )
            .padding(.horizontal, .spacingMD)

            FilterChipsView(
                selectedFilter: Binding(
                    get: { vm.selectedFilter },
                    set: { vm.selectedFilter = $0 }
                ),
                filters: EventTypeFilter.allCases
            )

            if let summary = vm.rangeSummary {
                HistoryRangeSummaryCard(summary: summary)
                    .padding(.horizontal, .spacingMD)
            }

            // Phase 3: Weekly trends card (shown for last 7 days)
            if vm.selectedRange == .last7Days, let weeklySummary = vm.weeklySummary {
                WeeklyTrendsCard(
                    thisWeekData: weeklySummary,
                    lastWeekData: nil, // TODO: Compare with last week
                    isPro: ProSubscriptionService.shared.isProUser,
                    onUpgradeTap: {
                        // TODO: Show upgrade modal
                    }
                )
                .padding(.horizontal, .spacingMD)
            }

            // Phase 3: Doctor report teaser
            DoctorReportTeaser(
                isPro: ProSubscriptionService.shared.isProUser,
                onUpgradeTap: {
                    // TODO: Show upgrade modal
                },
                onGenerateTap: {
                    // TODO: Navigate to report generation
                }
            )
        }
    }

    @ViewBuilder
    private func content(_ vm: HistoryViewModel) -> some View {
        switch vm.state {
        case .loading:
            LoadingStateView(
                message: "Loading history...",
                useSkeleton: PolishFeatureFlags.shared.skeletonLoadingEnabled
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .error(let message):
            VStack(spacing: .spacingMD) {
                Text(message)
                    .font(.body)
                    .foregroundColor(.foreground)
                PrimaryButton("Retry") {
                    Task { await vm.loadEvents() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded:
            loadedContentView(vm)
        }
    }

    @ViewBuilder
    private func loadedContentView(_ vm: HistoryViewModel) -> some View {
        if vm.filteredDays.isEmpty {
            HistoryEmptyState(action: {
                environment.navigationCoordinator.selectedTab = 0
            })
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: .spacingSM) {
                    ForEach(vm.filteredDays) { day in
                        HistoryDayHeader(date: day.date, summary: day.summary)
                            .accessibilityAddTraits(.isHeader)

                        ForEach(day.events) { event in
                            TimelineRow(
                                event: event,
                                onEdit: {
                                    editingEvent = event
                                    showFormForEvent(event)
                                },
                                onDelete: {
                                    Task { await vm.deleteEvent(event) }
                                    showUndoToast(for: event, viewModel: vm)
                                },
                                onDuplicate: {
                                    vm.duplicateEvent(event)
                                    showToast = ToastMessage(message: "Event duplicated", type: .success)
                                }
                            )
                            .padding(.horizontal, .spacingMD)
                            .onTapGesture {
                                selectedEvent = event
                                // TODO: Analytics.track(.historyEventDetailOpened(type: event.type))
                            }
                        }
                    }

                    if vm.canLoadMore {
                        Button {
                            Task { await vm.loadMore() }
                        } label: {
                            HStack {
                                if vm.isLoadingMore { ProgressView() }
                                Text("Load older days")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding()
                    }
                }
            }
            .refreshable { await vm.loadEvents() }
        }
    }

    // MARK: - Sheets

    @ViewBuilder
    private var feedSheet: some View {
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
                        Task { await viewModel?.loadEvents() }
                    }
            }
        }
    }

    @ViewBuilder
    private var sleepSheet: some View {
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
                        Task { await viewModel?.loadEvents() }
                    }
            }
        }
    }

    @ViewBuilder
    private var diaperSheet: some View {
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
                        Task { await viewModel?.loadEvents() }
                    }
            }
        }
    }

    @ViewBuilder
    private var tummySheet: some View {
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
                        Task { await viewModel?.loadEvents() }
                    }
            }
        }
    }

    // MARK: - Helpers

    private func updateViewModel(for baby: Baby) {
        if let existing = viewModel, existing.baby.id == baby.id { return }
        viewModel = HistoryViewModel(
            dataStore: environment.dataStore,
            baby: baby,
            dataProvider: DefaultHistoryDataProvider(dataStore: environment.dataStore)
        )
        // TODO: Analytics.track(.historyViewed(range: viewModel?.selectedRange ?? .last24Hours))
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
        case .cry:
            // No dedicated form for cry yet
            break
        }
    }

    private func showUndoToast(for event: Event, viewModel: HistoryViewModel) {
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if showToast?.id == toastId {
                showToast = nil
            }
        }
    }

    @ViewBuilder
    private var emptyBabiesView: some View {
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

    private func setupViewModelIfNeeded() async {
        guard viewModel == nil else { return }
        if let baby = environment.currentBaby {
            updateViewModel(for: baby)
        } else {
            try? await Task.sleep(nanoseconds: 100_000_000)
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

#Preview {
    HistoryView()
        .environmentObject(AppEnvironment(dataStore: InMemoryDataStore()))
}


