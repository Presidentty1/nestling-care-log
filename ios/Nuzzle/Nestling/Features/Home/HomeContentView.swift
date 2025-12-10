import SwiftUI

struct FeatureTooltip {
    let title: String
    let message: String
    let icon: String
    let preferenceKey: String
}

struct HomeContentView: View {
    @ObservedObject var viewModel: HomeViewModel
    @EnvironmentObject var environment: AppEnvironment
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
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
    
    @State private var showFeatureTooltip = false
    @State private var activeTooltip: FeatureTooltip?
    
    private var isWideLayout: Bool {
        horizontalSizeClass == .regular
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: .spacingXL) {
                babySelectorSection
                trialBannerSection
                firstLogSection
                
                // Above-the-fold essentials
                statusTilesSection
                quickActionsSection
                dailySummarySection
                guidanceStripSection
                
                // Goal-based insights
                if viewModel.shouldSimplifyUI {
                    streaksSection
                } else if viewModel.shouldPrioritizeSleep || viewModel.shouldPrioritizeFeeding || viewModel.timeOfDay == .morning || viewModel.timeOfDay == .day {
                    insightSection
                    streaksSection
                } else {
                    insightSection
                    streaksSection
                }
                
                timelineContent(for: viewModel)
            }
            .padding(.bottom, .spacingXL)
            .frame(maxWidth: .infinity)
        }
        .overlay(alignment: .bottom) {
            if showFeatureTooltip, let activeTooltip {
                HomeFeatureTooltipView(config: activeTooltip) {
                    showFeatureTooltip = false
                }
                .padding(.horizontal, .spacingMD)
                .padding(.bottom, .spacingLG)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity)
        .onChange(of: viewModel.events.count) { _, newCount in
            // Show progressive tooltip after first few logs
            if newCount >= 3 && !UserDefaults.standard.bool(forKey: "hasSeenFeatureTooltip_ai") {
                activeTooltip = FeatureTooltip(
                    title: "Try nap predictions",
                    message: "See suggested windows after a few logs.",
                    icon: "sparkles",
                    preferenceKey: "hasSeenFeatureTooltip_ai"
                )
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showFeatureTooltip = true
                }
            }
        }
    }
    
    @ViewBuilder
    private var babySelectorSection: some View {
        if environment.babies.count > 1, let baby = environment.currentBaby {
            BabySelectorView(baby: baby, babies: environment.babies) { selectedBaby in
                onBabySelected(selectedBaby)
            }
            .padding(.horizontal, .spacingMD)
        }
    }
    
    @ViewBuilder
    private var trialBannerSection: some View {
        // Show trial banner if user is in trial and not Pro
        if let daysRemaining = ProSubscriptionService.shared.trialDaysRemaining,
           daysRemaining > 0,
           !ProSubscriptionService.shared.isProUser {
            // Note: TrialBannerView must be included in the Nuzzle target in Xcode
            // If you see a "cannot find 'TrialBannerView' in scope" error,
            // ensure ios/Nuzzle/Nestling/Design/Components/TrialBannerView.swift
            // is checked in the Target Membership for the Nuzzle target
            TrialBannerView(daysRemaining: daysRemaining) {
                Task {
                    await Analytics.shared.logPaywallViewed(source: "trial_banner_home")
                }
                showProSubscription = true
            }
            .padding(.horizontal, .spacingMD)
        }
    }
    
    @ViewBuilder
    private var firstLogSection: some View {
        if !viewModel.hasAnyEvents {
            FirstLogCard(
                onLog: {
                    print("🔵 HomeContentView: First log card tapped")
                    showFeedForm = true
                },
                userGoal: viewModel.userGoal
            )
            .padding(.horizontal, .spacingMD)
        } else if shouldShowTasksChecklist {
            // Phase 3: Show tasks checklist after first log
            FirstTasksChecklistCard(
                hasLoggedFeed: hasLoggedFeedEvent,
                hasLoggedSleep: hasLoggedSleepEvent,
                onExploreAI: {
                    Task {
                        await Analytics.shared.logPaywallViewed(source: "first_tasks_checklist")
                    }
                    showProSubscription = true
                },
                onDismiss: {
                    UserDefaults.standard.set(true, forKey: "hasDissmissedTasksChecklist")
                }
            )
            .padding(.horizontal, .spacingMD)
        }
    }
    
    private var hasLoggedFeedEvent: Bool {
        viewModel.events.contains { $0.type == .feed }
    }
    
    private var hasLoggedSleepEvent: Bool {
        viewModel.events.contains { $0.type == .sleep }
    }
    
    private var shouldShowTasksChecklist: Bool {
        let hasDismissed = UserDefaults.standard.bool(forKey: "hasDissmissedTasksChecklist")
        let hasCompletedAll = hasLoggedFeedEvent && hasLoggedSleepEvent
        return !hasDismissed && !hasCompletedAll && viewModel.hasAnyEvents
    }
    
    @ViewBuilder
    private var statusTilesSection: some View {
        if let baby = environment.currentBaby {
            StatusTilesView(
                lastFeed: viewModel.lastFeed,
                lastDiaper: viewModel.lastDiaper,
                activeSleep: viewModel.activeSleep,
                nextNapWindow: viewModel.nextNapWindow,
                baby: baby
            )
            .padding(.top, CGFloat.spacingMD)
            .accessibilityHint("Current status cards. Double tap to view details.")
        }
    }
    
    @ViewBuilder
    private var guidanceStripSection: some View {
        if let baby = environment.currentBaby {
            GuidanceStripView(dataStore: environment.dataStore, baby: baby)
                .padding(.horizontal, .spacingMD)
        }
    }
    
    @ViewBuilder
    private var insightSection: some View {
        if let topRecommendation = viewModel.recommendations.first {
            FeatureGate.check(.todaysInsight, accessible: {
                TodaysInsightCard(recommendation: topRecommendation)
                    .padding(.horizontal, .spacingMD)
                    .onTapGesture {
                        Haptics.light()
                    }
            }, paywall: {
                TodaysInsightCard(recommendation: topRecommendation)
                    .padding(.horizontal, .spacingMD)
                    .blur(radius: 4)
                    .overlay(
                        Color.background.opacity(0.3)
                            .overlay(
                                VStack {
                                    Spacer()
                                    PrimaryButton("Upgrade to Pro", icon: "star.fill") {
                                        Task {
                                            await Analytics.shared.logPaywallViewed(source: "todays_insight_card")
                                        }
                                        showProSubscription = true
                                    }
                                    .padding(.horizontal, .spacingMD)
                                    Spacer()
                                }
                            )
                    )
                    .onTapGesture {
                        Task {
                            await Analytics.shared.logPaywallViewed(source: "todays_insight_card_tap")
                        }
                        showProSubscription = true
                    }
            })
        }
    }
    
    @ViewBuilder
    private var streaksSection: some View {
        if viewModel.currentStreak > 0 || viewModel.longestStreak > 0 {
            StreaksView(currentStreak: viewModel.currentStreak, longestStreak: viewModel.longestStreak)
                .padding(.horizontal, .spacingMD)
        }
    }
    
    @ViewBuilder
    private var quickActionsSection: some View {
        QuickActionsSection(
            activeSleep: viewModel.activeSleep,
            onFeed: {
                viewModel.quickLogFeed()
            },
            onSleep: {
                viewModel.quickLogSleep()
            },
            onDiaper: {
                viewModel.quickLogDiaper()
            },
            onTummyTime: {
                viewModel.quickLogTummyTime()
            },
            onOpenFeedForm: {
                showFeedForm = true
            },
            onOpenSleepForm: {
                showSleepForm = true
            },
            onOpenDiaperForm: {
                showDiaperForm = true
            },
            onOpenTummyForm: {
                showTummyForm = true
            },
            onCryAnalysis: {
                showCryRecorder = true
            }
        )
        .padding(.horizontal, CGFloat.spacingMD)
        .accessibilityLabel("Quick log actions")
        .accessibilityHint("Double tap to start logging. Long press for details.")
    }
    
    @ViewBuilder
    private var dailySummarySection: some View {
        if let summary = viewModel.summary {
            HomeDailySummaryCard(summary: summary, isCollapsedByDefault: true)
                .padding(.horizontal, .spacingMD)
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
                VStack(spacing: .spacingMD) {
                    EmptyStateView(
                        icon: noSearch && allFilter ? "calendar.badge.plus" : "magnifyingglass",
                        title: noSearch && allFilter ? "Let’s log your first feed" : "No matching events",
                        message: noSearch && allFilter ? "Quick actions can save a new feed, sleep, or diaper in two taps." : "Try a different filter or clear your search.",
                        variant: noSearch && allFilter ? .welcome : .search,
                        actionTitle: noSearch && allFilter ? "Open Quick Log" : "Clear Filters",
                        action: {
                            if noSearch && allFilter {
                                showFeedForm = true
                            } else {
                                viewModel.selectedFilter = .all
                                viewModel.searchText = ""
                            }
                        },
                        secondaryActionTitle: noSearch && allFilter ? "Start Sleep Timer" : nil,
                        secondaryAction: noSearch && allFilter ? {
                            viewModel.quickLogSleep()
                        } : nil
                    )
                    .frame(height: 220)
                    
                    if viewModel.events.isEmpty {
                        HomeFeatureTooltipView(
                            config: FeatureTooltip(
                                title: greetingTitle,
                                message: "Use Quick Actions to get to the aha moment faster.",
                                icon: "hand.tap",
                                preferenceKey: "hasSeenFeatureTooltip_quickLog"
                            )
                        ) {
                            UserDefaults.standard.set(true, forKey: "hasSeenFeatureTooltip_quickLog")
                        }
                        .padding(.horizontal, .spacingMD)
                    }
                }
            } else {
                // Progress indicator banner - shows until user has 6+ events
                ExampleDataBanner(eventCount: viewModel.events.count)
                    .padding(.horizontal, .spacingMD)
                
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
    
    private var greetingTitle: String {
        switch viewModel.timeOfDay {
        case .morning: return "Good morning! Ready to start?"
        case .day: return "Let’s keep the day on track"
        case .evening: return "Evening check-in"
        case .night: return "Late night logging made easy"
        }
    }
}

// MARK: - Supporting Views (scoped here to ensure target membership)

struct HomeFeatureTooltipView: View {
    let config: FeatureTooltip
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: .spacingMD) {
            ZStack {
                Circle()
                    .fill(Color.primary.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: config.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: .spacingXS) {
                Text(config.title)
                    .font(.headline)
                    .foregroundColor(.foreground)
                Text(config.message)
                    .font(.subheadline)
                    .foregroundColor(.mutedForeground)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: .spacingSM) {
                    Button {
                        Haptics.light()
                        UserDefaults.standard.set(true, forKey: config.preferenceKey)
                        onDismiss()
                    } label: {
                        Text("Got it")
                            .font(.callout.weight(.semibold))
                            .foregroundColor(.primary)
                            .padding(.horizontal, .spacingSM)
                            .padding(.vertical, .spacingXS)
                            .background(Color.surface)
                            .cornerRadius(.radiusSM)
                            .overlay(
                                RoundedRectangle(cornerRadius: .radiusSM)
                                    .stroke(Color.cardBorder, lineWidth: 1)
                            )
                    }
                    
                    Button {
                        Haptics.selection()
                        UserDefaults.standard.set(true, forKey: config.preferenceKey)
                        onDismiss()
                    } label: {
                        Text("Remind later")
                            .font(.callout)
                            .foregroundColor(.mutedForeground)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.spacingMD)
        .background(Color.elevated)
        .cornerRadius(.radiusMD)
        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(config.title). \(config.message)")
        .accessibilityHint("Dismiss or learn later")
    }
}

struct HomeDailySummaryCard: View {
    let summary: DaySummary
    let isCollapsedByDefault: Bool
    @State private var isCollapsed: Bool
    
    init(summary: DaySummary, isCollapsedByDefault: Bool = false) {
        self.summary = summary
        self.isCollapsedByDefault = isCollapsedByDefault
        _isCollapsed = State(initialValue: isCollapsedByDefault)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: .spacingSM) {
            HStack {
                Label("Today", systemImage: "chart.bar.fill")
                    .font(.headline)
                    .foregroundColor(.foreground)
                Spacer()
                Button(action: toggle) {
                    Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                        .background(Color.surface.opacity(0.9))
                        .cornerRadius(.radiusSM)
                        .overlay(
                            RoundedRectangle(cornerRadius: .radiusSM)
                                .stroke(Color.cardBorder, lineWidth: 1)
                        )
                }
                .accessibilityLabel(isCollapsed ? "Expand daily summary" : "Collapse daily summary")
            }
            
            if !isCollapsed {
                HStack(spacing: .spacingMD) {
                    summaryTile(title: "Feeds", value: "\(summary.feedCount)", icon: "drop.fill", color: .eventFeed)
                    summaryTile(title: "Diapers", value: "\(summary.diaperCount)", icon: "drop.circle.fill", color: .eventDiaper)
                    summaryTile(title: "Sleep", value: summary.sleepDisplay, icon: "moon.fill", color: .eventSleep)
                    summaryTile(title: "Tummy", value: "\(summary.tummyTimeCount)", icon: "figure.child", color: .eventTummy)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.spacingMD)
        .background(Color.surface)
        .cornerRadius(.radiusLG)
        .overlay(
            RoundedRectangle(cornerRadius: .radiusLG)
                .stroke(Color.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Daily summary of logged events")
    }
    
    private func summaryTile(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: .spacingXS) {
            HStack(spacing: .spacingXS) {
                Image(systemName: icon)
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.mutedForeground)
            }
            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundColor(.foreground)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.spacingSM)
        .background(Color.elevated)
        .cornerRadius(.radiusMD)
        .overlay(
            RoundedRectangle(cornerRadius: .radiusMD)
                .stroke(Color.cardBorder, lineWidth: 1)
        )
    }
    
    private func toggle() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
            isCollapsed.toggle()
        }
        Haptics.selection()
    }
}
