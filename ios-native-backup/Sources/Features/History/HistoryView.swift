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
                                    // Daily Summary
                                    if let summary = viewModel?.dailySummary, !summary.isEmpty {
                                        DailySummaryView(summary: summary, date: viewModel?.selectedDate ?? Date())
                                            .padding(.horizontal, .spacingMD)
                                    }

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
                                                let toastId = showToast?.id
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
                                                    if showToast?.id == toastId {
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
            .background(NuzzleTheme.background)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            exportSummaryForDoctor(range: .last24Hours)
                        }) {
                            Label("Export Last 24 Hours", systemImage: "doc.text")
                        }

                        Button(action: {
                            exportSummaryForDoctor(range: .last7Days)
                        }) {
                            Label("Export Last 7 Days", systemImage: "doc.text.fill")
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Export options")
                    .accessibilityHint("Export summary for doctor or caregiver")
                }
            }
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
        // Use DateUtils helper for consistent date handling
        return DateUtils.lastNDays(7)
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
                    .fontWeight(isSelected ? .bold : .semibold)
                    .foregroundColor(isSelected ? .white : .foreground)
            }
            .frame(width: 60, height: 70)
            .background(isSelected ? NuzzleTheme.primary : NuzzleTheme.surface)
            .cornerRadius(.radiusMD)
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(isSelected ? "Selected date" : "Select this date")
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
    
    private var accessibilityLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        let dateString = formatter.string(from: date)
        return isSelected ? "\(dateString), selected" : dateString
    }
}

// MARK: - Daily Summary View

struct DailySummaryView: View {
    let summary: DailySummary
    let date: Date

    var body: some View {
        CardView(variant: .elevated) {
            HStack(spacing: .spacingMD) {
                Image(systemName: "calendar")
                    .font(.title2)
                    .foregroundColor(.primary)

                VStack(alignment: .leading, spacing: .spacingXS) {
                    Text(dateLabel)
                        .font(.headline)
                        .foregroundColor(.foreground)

                    Text(summary.summaryText)
                        .font(.body)
                        .foregroundColor(.mutedForeground)
                }

                Spacer()
            }
        }
        .accessibilityLabel("\(dateLabel): \(summary.summaryText)")
        .accessibilityHint("Summary of events logged on this day")
    }

    private var dateLabel: String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }

    private func exportSummaryForDoctor(range: DateRange) {
        guard let baby = environment.currentBaby else { return }

        Task {
            do {
                let dateRange = range.dateRange
                let events = try await environment.dataStore.fetchEvents(for: baby, from: dateRange.start, to: dateRange.end)

                // Generate summary and CSV
                let summary = DoctorExportService.shared.generateSummary(for: baby, events: events, dateRange: dateRange)
                let csv = DoctorExportService.shared.generateCSV(for: baby, events: events, dateRange: dateRange)

                // Create temporary files
                guard let summaryURL = DoctorExportService.shared.createSummaryFile(summary: summary, baby: baby),
                      let csvURL = DoctorExportService.shared.createCSVFile(csv: csv, baby: baby) else {
                    return
                }

                // Present share sheet
                await MainActor.run {
                    let activityVC = UIActivityViewController(
                        activityItems: [summaryURL, csvURL],
                        applicationActivities: nil
                    )

                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootVC = windowScene.windows.first?.rootViewController {
                        rootVC.present(activityVC, animated: true)
                    }
                }
            } catch {
                Logger.dataError("Failed to export data: \(error.localizedDescription)")
            }
        }
    }
}

enum DateRange {
    case last24Hours
    case last7Days

    var dateRange: (start: Date, end: Date) {
        let now = Date()
        let calendar = Calendar.current

        switch self {
        case .last24Hours:
            let start = calendar.date(byAdding: .day, value: -1, to: now) ?? now.addingTimeInterval(-86400)
            return (start: start, end: now)
        case .last7Days:
            let start = calendar.date(byAdding: .day, value: -7, to: now) ?? now.addingTimeInterval(-604800)
            return (start: start, end: now)
        }
    }
}

#Preview {
    HistoryView()
        .environmentObject(AppEnvironment(dataStore: InMemoryDataStore()))
}

