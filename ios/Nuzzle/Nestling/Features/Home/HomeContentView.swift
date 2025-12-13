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
    @State private var selectedTab: HomeTab = .dashboard
    @State private var editMode: EditMode = .inactive
    @State private var selectedEventIds: Set<UUID> = []
    @State private var showBatchDeleteConfirmation = false

    enum HomeTab: String, CaseIterable {
        case dashboard = "Dashboard"
        case timeline = "Activity"
    }
    
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
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            Picker("View", selection: $selectedTab) {
                ForEach(HomeTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, .spacingLG)
            .padding(.vertical, .spacingSM)
            .onChange(of: selectedTab) { oldValue, newValue in
                Haptics.selection()
                AnalyticsService.shared.trackHomeTabSwitched(from: oldValue.rawValue, to: newValue.rawValue)
            }

            // Tab content
            TabView(selection: $selectedTab) {
                // Dashboard Tab
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

                        // Nap Predictor Card (Hero)
                        napPredictorSection

                        // Quick Actions (2x2 Grid)
                        quickActionsSection

                        // Daily Summary (tappable tiles)
                        if let summary = viewModel.summary {
                            DailySummaryCard(
                                summary: summary,
                                isCollapsedByDefault: false,
                                onTileTapped: { filter in
                                    viewModel.selectedFilter = filter
                                    selectedTab = .timeline
                                    AnalyticsService.shared.track(event: "summary_filter_applied", properties: [
                                        "filter": filter.rawValue
                                    ])
                                }
                            )
                            .padding(.horizontal, .spacingLG)
                        }

                        // AI Tease Card
                        aiTeaseSection
                    }
                    .padding(.bottom, .spacingXL)
                }
                .tag(HomeTab.dashboard)

                // Timeline Tab
                timelineTabContent
                .tag(HomeTab.timeline)
                .environment(\.editMode, $editMode)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(Color.background)
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
        NapPredictionCard(
            napWindow: viewModel.nextNapWindow,
            baby: currentBaby,
            onTap: {
                // TODO: Could show more detailed nap prediction info
            },
            cardVariant: .emphasis
        )
        .padding(.horizontal, .spacingLG)
    }
    
    // MARK: - Quick Actions Section
    
    @ViewBuilder
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: .spacingSM) {
            Text("Quick Log")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.foreground)
                .padding(.horizontal, .spacingLG)

            // Dynamic layout: hero sleep when active, otherwise 2x2 grid
            if viewModel.activeSleep != nil {
                // Hero layout: Sleep button full-width and prominent
                VStack(spacing: .spacingMD) {
                    // Hero sleep button
                    QuickActionButton(
                        title: "End Sleep",
                        icon: "moon.fill",
                        color: .eventSleep,
                        isActive: true,
                        action: {
                            viewModel.quickLogSleep()
                        },
                        longPressAction: {
                            showSleepForm = true
                        }
                    )
                    .frame(height: 120) // Taller for hero treatment

                    // Other buttons in a row
                    HStack(spacing: .spacingMD) {
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
            } else {
                // Standard 2x2 grid
                VStack(spacing: .spacingMD) {
                    HStack(spacing: .spacingMD) {
                        QuickActionButton(
                            title: "Sleep",
                            icon: "moon.fill",
                            color: .eventSleep,
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
    }
    
    // MARK: - Timeline Tab Content

    @ViewBuilder
    private var timelineTabContent: some View {
        VStack(spacing: 0) {
            if viewModel.filteredEvents.isEmpty && viewModel.events.isEmpty {
                ScrollView {
                    todayEmptyState
                        .padding(.horizontal, .spacingLG)
                }
            } else if viewModel.filteredEvents.isEmpty && !viewModel.events.isEmpty {
                // Show filter empty state
                VStack(spacing: .spacingMD) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.mutedForeground)

                    Text("No events match your filter")
                        .font(.headline)
                        .foregroundColor(.foreground)

                    Text("Try adjusting your search or filter settings")
                        .font(.body)
                        .foregroundColor(.mutedForeground)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, .spacingLG)

                    Button(action: {
                        viewModel.selectedFilter = .all
                        viewModel.searchText = ""
                        Haptics.selection()
                    }) {
                        Text("Clear Filter")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.primary)
                            .cornerRadius(.radiusLG)
                    }
                    .padding(.horizontal, .spacingLG)
                    .padding(.top, .spacingMD)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Timeline with events
                VStack(alignment: .leading, spacing: .spacingSM) {
                    // Header with edit button
                    HStack {
                        Text("Today")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.foreground)

                        Spacer()

                        // Filter indicator with clear button
                        if viewModel.selectedFilter != .all {
                            HStack(spacing: 8) {
                                Text("\(viewModel.selectedFilter.displayName) only")
                                    .font(.caption)
                                    .foregroundColor(.primary)

                                Button(action: {
                                    viewModel.selectedFilter = .all
                                    viewModel.searchText = ""
                                    Haptics.selection()
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.primary.opacity(0.7))
                                }
                                .accessibilityLabel("Clear filter")
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.primary.opacity(0.1))
                            .cornerRadius(12)
                        }

                        // Edit button
                        EditButton()
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .padding(.horizontal, .spacingLG)

                    // Batch delete toolbar when editing and items selected
                    if editMode.isEditing && !selectedEventIds.isEmpty {
                        HStack {
                            Text("\(selectedEventIds.count) selected")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Spacer()

                            Button(action: {
                                showBatchDeleteConfirmation = true
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.destructive)
                            }
                        }
                        .padding(.horizontal, .spacingLG)
                        .padding(.vertical, .spacingSM)
                        .background(Color.destructive.opacity(0.1))
                    }

                    List(viewModel.filteredEvents, selection: $selectedEventIds) { event in
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
                        .listRowInsets(EdgeInsets(top: 8, leading: .spacingLG, bottom: 8, trailing: .spacingLG))
                        .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                    .environment(\.editMode, $editMode)
                }
            }
        }
        .alert("Delete \(selectedEventIds.count) events?", isPresented: $showBatchDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                let selectedEvents = viewModel.filteredEvents.filter { selectedEventIds.contains($0.id) }
                Task {
                    await viewModel.batchDelete(events: selectedEvents)
                    selectedEventIds.removeAll()
                    editMode = .inactive
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Legacy Today Timeline Section (for backward compatibility)

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
    
    // MARK: - Helpers
    
    private var babyName: String {
        currentBaby?.name ?? "your baby"
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
