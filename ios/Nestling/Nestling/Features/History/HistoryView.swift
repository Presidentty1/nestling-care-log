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
    
    @ViewBuilder
    private func timelineContent(for viewModel: HistoryViewModel) -> some View {
        if viewModel.isLoading {
            LoadingStateView(message: "Loading events...", useSkeleton: true)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            let isEmpty = viewModel.filteredEvents.isEmpty
            let noSearch = viewModel.searchText.isEmpty
            let allFilter = viewModel.selectedFilter == .all
            
            if isEmpty {
                VStack(spacing: .spacingMD) {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: noSearch && allFilter ? "No events logged" : "No matching events",
                        message: noSearch && allFilter ? "Logs are created from Home. Tap 'Home' to start logging." : "Try adjusting your search or filter",
                        actionTitle: noSearch && allFilter ? "Go to Home" : nil,
                        action: noSearch && allFilter ? {
                            // Switch to Home tab
                            environment.navigationCoordinator.selectedTab = 0
                        } : nil
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                ScrollView {
                    VStack(spacing: .spacingSM) {
                        // Filter chips
                        FilterChipsView(
                            selectedFilter: Binding(
                                get: { viewModel.selectedFilter },
                                set: { viewModel.selectedFilter = $0 }
                            ),
                            filters: EventTypeFilter.allCases
                        )
                        .padding(.top, .spacingSM)
                        
                        ForEach(viewModel.filteredEvents) { event in
                            TimelineRow(
                                event: event,
                                onEdit: { editingEvent = event; showFormForEvent(event) },
                                onDelete: {
                                    Task {
                                        await viewModel.deleteEvent(event)
                                    }
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
                                    // Auto-dismiss after 3 seconds (reduced from 7)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                        if showToast?.id == toastId {
                                            showToast = nil
                                        }
                                    }
                                },
                                onDuplicate: {
                                    viewModel.duplicateEvent(event)
                                    showToast = ToastMessage(message: "Event duplicated", type: .success)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        showToast = nil
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, .spacingMD)
                }
                .refreshable {
                    await viewModel.loadEvents()
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    ObservedViewModel(viewModel) { viewModel in
                        VStack(spacing: .spacingMD) {
                            // Date Picker
                            DatePickerView(selectedDate: Binding(
                                get: { viewModel.selectedDate },
                                set: { viewModel.selectDate($0) }
                            )) { date in
                                viewModel.selectDate(date)
                            }
                            .padding(.horizontal, .spacingMD)
                            
                            // Timeline
                            timelineContent(for: viewModel)
                        }
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
            .navigationTitle("History")
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
                                Task {
                                    await viewModel?.loadEvents()
                                }
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
                                Task {
                                    await viewModel?.loadEvents()
                                }
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
                                Task {
                                    await viewModel?.loadEvents()
                                }
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
                                Task {
                                    await viewModel?.loadEvents()
                                }
                            }
                    }
                }
            }
            .toast($showToast)
        }
    }
    
    private func updateViewModel(for baby: Baby) {
        // Only create a new viewModel if we don't have one, or if the baby changed
        if let existingViewModel = viewModel, existingViewModel.baby.id == baby.id {
            print("updateViewModel: Keeping existing viewModel for baby \(baby.id)")
            return
        }
        print("updateViewModel: Creating new viewModel for baby \(baby.id)")
        viewModel = HistoryViewModel(dataStore: environment.dataStore, baby: baby)
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

struct DatePickerView: View {
    @Binding var selectedDate: Date
    let onDateSelected: (Date) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .spacingSM) {
                ForEach(last7Days, id: \.self) { date in
                    DateButton(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate)
                    ) {
                        selectedDate = date
                        onDateSelected(date)
                    }
                }
            }
            .padding(.horizontal, .spacingMD) // Add horizontal padding so last chip has breathing room
        }
    }
    
    private var last7Days: [Date] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<7).compactMap { daysAgo in
            calendar.date(byAdding: .day, value: -daysAgo, to: today)
        }
    }
}

struct DateButton: View {
    let date: Date
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(dayName)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .mutedForeground)
                
                Text(dayNumber)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .foreground)
            }
            .frame(width: 60, height: 70)
            .background(isSelected ? Color.primary : Color.surface)
            .cornerRadius(.radiusMD)
        }
    }
    
    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

#Preview {
    HistoryView()
        .environmentObject(AppEnvironment(dataStore: InMemoryDataStore()))
}

