import SwiftUI

/// Primary screen showing "what's happening now" and "what to do next".
/// Replaces HomeView with focused, fast logging experience.
struct NowView: View {
    @EnvironmentObject var environment: AppEnvironment
    @State private var viewModel: NowViewModel?
    @State private var showFeedForm = false
    @State private var showSleepForm = false
    @State private var showDiaperForm = false
    @State private var showTummyForm = false
    @State private var showLabs = false
    @State private var showAsk = false
    @State private var editingEvent: Event?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    ScrollView {
                        VStack(spacing: .spacingLG) {
                            // 1. Baby Selector (top, compact)
                            if let baby = environment.currentBaby {
                                BabySelectorCard(baby: baby, babies: environment.babies) { selectedBaby in
                                    environment.currentBaby = selectedBaby
                                    updateViewModel(for: selectedBaby)
                                }
                            }

                            // 2. Last Events Summary
                            if !viewModel.lastEvents.isEmpty {
                                LastEventsSummaryCard(lastEvents: viewModel.lastEvents)
                            }

                            // 3. Active Sleep Timer
                            if let activeSleep = viewModel.activeSleep {
                                ActiveSleepTimerCard(activeSleep: activeSleep) {
                                    viewModel.stopNapTimer()
                                }
                                .transition(.scale.combined(with: .opacity))
                            }

                            // 4. Next Nap Suggestion
                            if let napSuggestion = viewModel.napSuggestion {
                                NapSuggestionCard(suggestion: napSuggestion) {
                                    // Handle "View Details" - could show sheet with more info
                                }
                            }

                            // 5. Quick Log Buttons
                            QuickLogSection(
                                activeSleep: viewModel.activeSleep,
                                onFeed: { viewModel.quickLogFeed() },
                                onDiaper: { viewModel.quickLogDiaper() },
                                onSleep: { viewModel.startNapTimer() },
                                onTummyTime: { viewModel.quickLogTummyTime() }
                            )

                            // 6. 24h Visual Summary Strip
                            TodaySummaryStrip(
                                feedCount: viewModel.todayFeedCount,
                                diaperCount: viewModel.todayDiaperCount,
                                sleepTotalMinutes: viewModel.todaySleepTotalMinutes
                            )

                            // 7. Timeline (last 12-24h)
                            if !viewModel.recentTimeline.isEmpty {
                                RecentTimelineSection(
                                    events: viewModel.recentTimeline,
                                    onEdit: { event in
                                        editingEvent = event
                                        showFormForEvent(event)
                                    },
                                    onDelete: { event in
                                        viewModel.deleteEvent(event)
                                    }
                                )
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            } else {
                                EmptyStateView(
                                    icon: "timeline",
                                    title: "No recent activity",
                                    message: "Recent events will appear here"
                                )
                                .frame(height: 200)
                            }

                            // Secondary entry points (small, unobtrusive)
                            VStack(spacing: .spacingSM) {
                                Button(action: { showLabs = true }) {
                                    HStack {
                                        Image(systemName: "flask")
                                        Text("Labs & Beta Features")
                                        Image(systemName: "chevron.right")
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.spacingMD)
                                    .background(NuzzleTheme.surface)
                                    .cornerRadius(.radiusMD)
                                }

                                Button(action: { showAsk = true }) {
                                    HStack {
                                        Image(systemName: "bubble.left.and.bubble.right")
                                        Text("Ask Nuzzle")
                                        Image(systemName: "chevron.right")
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.spacingMD)
                                    .background(NuzzleTheme.surface)
                                    .cornerRadius(.radiusMD)
                                }
                            }
                            .padding(.horizontal, .spacingMD)
                            .padding(.top, .spacingMD)
                        }
                        .padding(.vertical, .spacingMD)
                    }
                    .background(NuzzleTheme.background)
                    .navigationTitle("Now")
                    .navigationBarTitleDisplayMode(.large)
                } else {
                    LoadingStateView(message: "Loading...")
                }
            }
        }
        .task {
            if viewModel == nil {
                updateViewModel(for: environment.currentBaby)
            }
        }
        .sheet(isPresented: $showFeedForm) {
            QuickLogFeedView(onComplete: { event in
                viewModel?.handleNewEvent(event)
                showFeedForm = false
            })
        }
        .sheet(isPresented: $showDiaperForm) {
            QuickLogDiaperView(onComplete: { event in
                viewModel?.handleNewEvent(event)
                showDiaperForm = false
            })
        }
        .sheet(isPresented: $showSleepForm) {
            if let activeSleep = viewModel?.activeSleep {
                SleepFormView(event: activeSleep, onComplete: { updatedEvent in
                    viewModel?.handleNewEvent(updatedEvent)
                    showSleepForm = false
                })
            }
        }
        .sheet(isPresented: $showTummyForm) {
            QuickLogTummyTimeView(onComplete: { event in
                viewModel?.handleNewEvent(event)
                showTummyForm = false
            })
        }
        .sheet(isPresented: $showLabs) {
            LabsView()
        }
        .sheet(isPresented: $showAsk) {
            GuidedAssistantView()
        }
        .sheet(item: $editingEvent) { event in
            // Show appropriate edit form based on event type
            switch event.type {
            case .feed:
                FeedFormView(event: event, onComplete: { updatedEvent in
                    viewModel?.handleNewEvent(updatedEvent)
                    editingEvent = nil
                })
            case .diaper:
                DiaperFormView(event: event, onComplete: { updatedEvent in
                    viewModel?.handleNewEvent(updatedEvent)
                    editingEvent = nil
                })
            case .sleep:
                SleepFormView(event: event, onComplete: { updatedEvent in
                    viewModel?.handleNewEvent(updatedEvent)
                    editingEvent = nil
                })
            case .tummyTime:
                TummyTimeFormView(event: event, onComplete: { updatedEvent in
                    viewModel?.handleNewEvent(updatedEvent)
                    editingEvent = nil
                })
            }
        }
    }

    private func updateViewModel(for baby: Baby?) {
        guard let baby = baby else { return }
        viewModel = NowViewModel(dataStore: environment.dataStore, baby: baby)
    }

    private func showFormForEvent(_ event: Event) {
        switch event.type {
        case .feed: showFeedForm = true
        case .diaper: showDiaperForm = true
        case .sleep: showSleepForm = true
        case .tummyTime: showTummyForm = true
        }
    }
}

// MARK: - Component Views

/// Compact baby selector for NowView
struct BabySelectorCard: View {
    let baby: Baby
    let babies: [Baby]
    let onSelect: (Baby) -> Void

    var body: some View {
        Menu {
            ForEach(babies) { baby in
                Button(action: { onSelect(baby) }) {
                    HStack {
                        Text(baby.name)
                        if baby.id == self.baby.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                Text(baby.name)
                    .font(.headline)
                    .foregroundColor(NuzzleTheme.textPrimary)
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.spacingMD)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(NuzzleTheme.surface)
            .cornerRadius(.radiusMD)
        }
        .padding(.horizontal, .spacingMD)
    }
}

/// Shows last feed/diaper/sleep with time since
struct LastEventsSummaryCard: View {
    let lastEvents: [Event]

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingSM) {
            Text("Recent Activity")
                .font(.headline)
                .foregroundColor(NuzzleTheme.textPrimary)

            VStack(spacing: .spacingXS) {
                ForEach(lastEvents.prefix(3)) { event in
                    HStack {
                        Circle()
                            .fill(Color(event.type.accentColor))
                            .frame(width: 8, height: 8)

                        Text(event.displayText)
                            .font(.body)
                            .foregroundColor(NuzzleTheme.textPrimary)

                        Spacer()

                        Text(timeSince(event.startTime))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, .spacingXS)
                }
            }
        }
        .padding(.spacingMD)
        .background(NuzzleTheme.surface)
        .cornerRadius(.radiusMD)
        .padding(.horizontal, .spacingMD)
    }

    private func timeSince(_ date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)

        if interval < 60 { return "Just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }
}

/// Shows active sleep timer with stop button
struct ActiveSleepTimerCard: View {
    let activeSleep: Event
    let onStop: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingSM) {
            Text("Nap in Progress")
                .font(.headline)
                .foregroundColor(NuzzleTheme.primary)

            HStack {
                Text("Started \(timeSince(activeSleep.startTime))")
                    .font(.body)
                    .foregroundColor(NuzzleTheme.textSecondary)

                Spacer()

                Button(action: onStop) {
                    Text("Stop Nap")
                        .font(.body.bold())
                        .foregroundColor(NuzzleTheme.primary)
                        .padding(.horizontal, .spacingMD)
                        .padding(.vertical, .spacingXS)
                        .background(NuzzleTheme.primary.opacity(0.1))
                        .cornerRadius(.radiusMD)
                }
            }
        }
        .padding(.spacingMD)
        .background(NuzzleTheme.surface)
        .cornerRadius(.radiusMD)
        .padding(.horizontal, .spacingMD)
    }

    private func timeSince(_ date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)

        if interval < 60 { return "just now" }
        if interval < 3600 { return "\(Int(interval / 60)) minutes ago" }
        return "\(Int(interval / 3600)) hours ago"
    }
}

/// Shows nap suggestion with explanation
struct NapSuggestionCard: View {
    let suggestion: NapSuggestion
    let onViewDetails: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingSM) {
            HStack {
                Image(systemName: "moon.stars")
                    .foregroundColor(NuzzleTheme.primary)
                Text("Nap Suggestion")
                    .font(.headline)
                    .foregroundColor(NuzzleTheme.textPrimary)
            }

            Text(suggestion.displayText)
                .font(.body)
                .foregroundColor(NuzzleTheme.textSecondary)

            Button(action: onViewDetails) {
                Text("View Details")
                    .font(.caption)
                    .foregroundColor(NuzzleTheme.primary)
            }
        }
        .padding(.spacingMD)
        .background(NuzzleTheme.surface)
        .cornerRadius(.radiusMD)
        .padding(.horizontal, .spacingMD)
    }
}

/// Large, prominent quick log buttons
struct QuickLogSection: View {
    let activeSleep: Event?
    let onFeed: () -> Void
    let onDiaper: () -> Void
    let onSleep: () -> Void
    let onTummyTime: () -> Void

    var body: some View {
        VStack(spacing: .spacingMD) {
            Text("Quick Log")
                .font(.headline)
                .foregroundColor(NuzzleTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, .spacingMD)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: .spacingMD) {
                QuickLogButton(
                    title: "Feed",
                    icon: "drop.fill",
                    color: NuzzleTheme.primary,
                    isActive: false,
                    action: onFeed
                )

                QuickLogButton(
                    title: "Diaper",
                    icon: "drop.circle.fill",
                    color: NuzzleTheme.accentDiaper,
                    isActive: false,
                    action: onDiaper
                )

                QuickLogButton(
                    title: activeSleep != nil ? "Stop Nap" : "Start Nap",
                    icon: activeSleep != nil ? "moon.fill" : "moon.stars.fill",
                    color: NuzzleTheme.accentSleep,
                    isActive: activeSleep != nil,
                    action: activeSleep != nil ? {} : onSleep
                )

                QuickLogButton(
                    title: "Tummy Time",
                    icon: "figure.child",
                    color: NuzzleTheme.accentTummy,
                    isActive: false,
                    action: onTummyTime
                )
            }
            .padding(.horizontal, .spacingMD)
        }
    }
}

/// Visual summary strip for today's activity
struct TodaySummaryStrip: View {
    let feedCount: Int
    let diaperCount: Int
    let sleepTotalMinutes: Int

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingSM) {
            Text("Today")
                .font(.headline)
                .foregroundColor(NuzzleTheme.textPrimary)

            HStack(spacing: .spacingLG) {
                SummaryItem(label: "\(feedCount) feeds", color: NuzzleTheme.primary)
                SummaryItem(label: "\(diaperCount) diapers", color: NuzzleTheme.accentDiaper)
                SummaryItem(label: "\(sleepTotalMinutes/60)h \(sleepTotalMinutes%60)m sleep", color: NuzzleTheme.accentSleep)
            }
        }
        .padding(.spacingMD)
        .background(NuzzleTheme.surface)
        .cornerRadius(.radiusMD)
        .padding(.horizontal, .spacingMD)
    }
}

/// Individual summary item
struct SummaryItem: View {
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: .spacingXS) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.caption)
                .foregroundColor(NuzzleTheme.textSecondary)
        }
    }
}

/// Timeline of recent events (last 12-24h)
struct RecentTimelineSection: View {
    let events: [Event]
    let onEdit: (Event) -> Void
    let onDelete: (Event) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingSM) {
            Text("Recent Timeline")
                .font(.headline)
                .foregroundColor(NuzzleTheme.textPrimary)
                .padding(.horizontal, .spacingMD)

            VStack(spacing: .spacingXS) {
                ForEach(events) { event in
                    TimelineRow(
                        event: event,
                        showTime: true,
                        onEdit: { onEdit(event) },
                        onDelete: { onDelete(event) }
                    )
                }
            }
        }
    }
}

// MARK: - Supporting Types

struct NapSuggestion {
    let startTime: Date
    let endTime: Date
    let explanation: String

    var displayText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let start = formatter.string(from: startTime)
        let end = formatter.string(from: endTime)
        return "Suggested nap: \(start) – \(end)\n\(explanation)"
    }
}

#Preview {
    NowView()
        .environmentObject(AppEnvironment(dataStore: InMemoryDataStore()))
}
