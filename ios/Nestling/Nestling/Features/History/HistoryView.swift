import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var environment: AppEnvironment
    @State private var viewModel: HistoryViewModel?
    @State private var showFeedForm = false
    @State private var showSleepForm = false
    @State private var showDiaperForm = false
    @State private var showTummyForm = false
    @State private var editingEvent: Event?
    
    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
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
                        if viewModel.isLoading {
                            LoadingStateView(message: "Loading events...")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if viewModel?.filteredEvents.isEmpty ?? true {
                            EmptyStateView(
                                icon: "magnifyingglass",
                                title: (viewModel?.searchText.isEmpty ?? true) && (viewModel?.selectedFilter == .all ?? true) ? "No events logged" : "No matching events",
                                message: (viewModel?.searchText.isEmpty ?? true) && (viewModel?.selectedFilter == .all ?? true) ? "Nothing logged on this day" : "Try adjusting your search or filter"
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            ScrollView {
                                VStack(spacing: .spacingSM) {
                                    // Filter chips
                                    FilterChipsView(
                                        selectedFilter: Binding(
                                            get: { viewModel?.selectedFilter ?? .all },
                                            set: { viewModel?.selectedFilter = $0 }
                                        ),
                                        filters: EventTypeFilter.allCases
                                    )
                                    .padding(.top, .spacingSM)
                                    
                                    ForEach(viewModel?.filteredEvents ?? []) { event in
                                        TimelineRow(
                                            event: event,
                                            onEdit: { editingEvent = event; showFormForEvent(event) },
                                            onDelete: {
                                                viewModel?.deleteEvent(event)
                                                // Show undo toast
                                                showToast = ToastMessage(
                                                    message: "Event deleted",
                                                    type: .success,
                                                    undoAction: {
                                                        Task {
                                                            do {
                                                                try await viewModel?.undoDeletion()
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
                                                viewModel?.duplicateEvent(event)
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
                                viewModel?.loadEvents()
                            }
                        }
                    }
                } else {
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
                if let baby = environment.currentBaby, viewModel == nil {
                    updateViewModel(for: baby)
                }
            }
            .onChange(of: environment.currentBaby?.id) { _, _ in
                if let baby = environment.currentBaby {
                    updateViewModel(for: baby)
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
                                viewModel?.loadEvents()
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
                                viewModel?.loadEvents()
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
                                viewModel?.loadEvents()
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
                                viewModel?.loadEvents()
                            }
                    }
                }
            }
        }
    }
    
    private func updateViewModel(for baby: Baby) {
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

