import SwiftUI
import Combine

/// HomeContentView - Smart Summary + Timeline Layout
///
/// Implements a glanceable home experience:
/// - Greeting: Contextual, supportive message
/// - Summary Cards: Horizontal scroll of last feed, diaper, sleep, next nap
/// - Quick Actions: ≤2-tap logging for feed, sleep, diaper, tummy, cry analysis, Q&A
/// - Timeline: Simple chronological list of today's events
///
/// Design goals: answer "What's happening now?" and "What should I do next?" with minimal cognitive load.
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
    @Binding var showAssistant: Bool
    @Binding var editingEvent: Event?
    @Binding var showToast: ToastMessage?
    @Binding var showProSubscription: Bool
    let onBabySelected: (Baby) -> Void
    let onEventEdited: (Event) -> Void
    
    @State private var showBabySwitcher = false
    @State private var showFeatureTooltip = false
    @State private var activeTooltip: FeatureTooltip?
    
    private var isWideLayout: Bool {
        horizontalSizeClass == .regular
    }
    
    private var currentBaby: Baby? {
        environment.currentBaby
    }
    
    private var ageDescription: String {
        guard let baby = currentBaby else { return "" }
        return DateUtils.formatBabyAge(dateOfBirth: baby.dateOfBirth)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: .spacingXL) {
                if let baby = currentBaby {
                    HomeTopBar(
                        baby: baby,
                        ageDescription: ageDescription,
                        onSettingsTapped: {
                            // TODO: Navigate to settings tab/screen when available
                            print("Settings tapped")
                        },
                        onBabyTapped: environment.babies.count > 1 ? { showBabySwitcher = true } : nil
                    )
                    .padding(.top, .spacingSM)
                }
                
                HomeGreeting(timeOfDay: viewModel.timeOfDay)
                
                if let active = viewModel.activeSleep {
                    OngoingTimerBanner(
                        event: active,
                        onStop: { viewModel.quickLogSleep() },
                        onEdit: {
                            editingEvent = active
                            showSleepForm = true
                        }
                    )
                    .padding(.horizontal, .spacingMD)
                }
                
                if let baby = currentBaby {
                    HomeSummaryCarousel(
                        lastFeed: viewModel.lastFeed,
                        lastDiaper: viewModel.lastDiaper,
                        activeSleep: viewModel.activeSleep,
                        lastSleep: viewModel.lastSleep,
                        nextNapWindow: viewModel.nextNapWindow,
                        baby: baby,
                        onFeedTapped: { showFeedForm = true },
                        onDiaperTapped: { showDiaperForm = true },
                        onSleepTapped: {
                            if viewModel.activeSleep != nil {
                                viewModel.quickLogSleep()
                            } else {
                                showSleepForm = true
                            }
                        },
                        onNapTapped: {
                            // TODO: Show nap prediction detail sheet
                        }
                    )
                }
                
                quickActionsSection
                
                todayHeader
                timelineContent(for: viewModel)
            }
            .padding(.bottom, .spacingXL)
            .frame(maxWidth: .infinity)
        }
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
            },
            onAskQuestion: {
                showAssistant = true
            }
        )
        .padding(.horizontal, CGFloat.spacingMD)
        .accessibilityLabel("Quick log actions")
        .accessibilityHint("Double tap to start logging. Long press for details.")
    }
    
    private var todayHeader: some View {
        HStack {
            Text("Today")
                .font(.title2.weight(.semibold))
                .foregroundColor(.foreground)
            Spacer()
        }
        .padding(.horizontal, .spacingMD)
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

// MARK: - Inline Components (kept here to ensure target membership)

/// Top bar for the Home tab showing baby name/age, brand mark, and settings.
/// Supports tapping the baby area to switch babies when applicable.
struct HomeTopBar: View {
    let baby: Baby
    let ageDescription: String
    let onSettingsTapped: () -> Void
    let onBabyTapped: (() -> Void)?
    
    var body: some View {
        HStack(alignment: .center, spacing: .spacingMD) {
            Button(action: {
                onBabyTapped?()
            }) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(baby.name)
                        .font(.headline)
                        .foregroundColor(.foreground)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text(ageDescription)
                        .font(.subheadline)
                        .foregroundColor(.mutedForeground)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(baby.name), \(ageDescription)")
            .accessibilityHint("Double tap to switch baby")
            
            Image("AppIconSmall")
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)
            
            Button(action: onSettingsTapped) {
                Image(systemName: "gearshape.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.primary)
                    .frame(width: 36, height: 36)
                    .background(Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: .radiusSM))
            }
            .accessibilityLabel("Open settings")
            .accessibilityHint("Shows app settings and profile")
        }
        .padding(.horizontal, .spacingMD)
        .padding(.vertical, .spacingSM)
        .background(Color.background.opacity(0.001))
    }
}

/// Lightweight, supportive greeting for the Home tab.
struct HomeGreeting: View {
    let timeOfDay: HomeViewModel.TimeOfDay
    
    private var message: String {
        switch timeOfDay {
        case .morning:
            return "Good morning, you’ve got this."
        case .day:
            return "Keeping things steady."
        case .evening:
            return "Evening wind-down time."
        case .night:
            return "Late night? I’m here to help."
        }
    }
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: .spacingSM) {
            VStack(alignment: .leading, spacing: 4) {
                Text(message)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.foreground)
                    .multilineTextAlignment(.leading)
                Text("Quickly see what’s next and log in two taps.")
                    .font(.subheadline)
                    .foregroundColor(.mutedForeground)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, .spacingMD)
    }
}

/// Horizontal summary cards for quick glance status on Home.
struct HomeSummaryCarousel: View {
    let lastFeed: Event?
    let lastDiaper: Event?
    let activeSleep: Event?
    let lastSleep: Event?
    let nextNapWindow: NapWindow?
    let baby: Baby?
    
    var onFeedTapped: (() -> Void)?
    var onDiaperTapped: (() -> Void)?
    var onSleepTapped: (() -> Void)?
    var onNapTapped: (() -> Void)?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .spacingMD) {
                feedCard
                diaperCard
                sleepCard
                nextNapCard
            }
            .padding(.horizontal, .spacingMD)
            .padding(.vertical, .spacingSM)
        }
    }
    
    private var feedCard: some View {
        HomeSummaryCard(
            icon: "baby.bottle.fill",
            iconColor: .eventFeed,
            title: "Last Feed",
            primaryText: lastFeed.map { DateUtils.formatDetailedRelativeTime($0.startTime) } ?? "No feeds yet",
            secondaryText: formatFeedDetail(lastFeed),
            onTap: onFeedTapped
        )
        .accessibilityLabel(lastFeedAccessibilityLabel)
        .accessibilityHint("Double tap to view feed details")
    }
    
    private var lastFeedAccessibilityLabel: String {
        if let event = lastFeed {
            let time = DateUtils.formatDetailedRelativeTime(event.startTime)
            let detail = formatFeedDetail(event)
            return "Last feed, \(time). \(detail)"
        }
        return "No feeds logged yet"
    }
    
    private var diaperCard: some View {
        HomeSummaryCard(
            icon: "drop.circle.fill",
            iconColor: .eventDiaper,
            title: "Last Diaper",
            primaryText: lastDiaper.map { DateUtils.formatDetailedRelativeTime($0.startTime) } ?? "No diapers yet",
            secondaryText: lastDiaper?.subtype?.capitalized ?? "Try logging one",
            onTap: onDiaperTapped
        )
        .accessibilityLabel(lastDiaperAccessibilityLabel)
        .accessibilityHint("Double tap to view diaper history")
    }
    
    private var lastDiaperAccessibilityLabel: String {
        if let event = lastDiaper {
            let time = DateUtils.formatDetailedRelativeTime(event.startTime)
            let detail = event.subtype?.capitalized ?? "Diaper"
            return "Last diaper, \(time). \(detail)"
        }
        return "No diapers logged yet"
    }
    
    @ViewBuilder
    private var sleepCard: some View {
        if let active = activeSleep {
            HomeSummaryCard(
                icon: "moon.zzz.fill",
                iconColor: .eventSleep,
                title: "Sleeping",
                primaryText: formatActiveDuration(active),
                secondaryText: "Started \(DateUtils.formatDetailedRelativeTime(active.startTime))",
                isEmphasized: true,
                onTap: onSleepTapped
            )
            .accessibilityLabel("Sleeping, \(formatActiveDuration(active)) so far")
            .accessibilityHint("Double tap to open sleep details")
        } else {
            HomeSummaryCard(
                icon: "moon.zzz.fill",
                iconColor: .eventSleep,
                title: "Last Nap",
                primaryText: lastSleep.flatMap { $0.endTime }.map { DateUtils.formatDetailedRelativeTime($0) } ?? "No naps yet",
                secondaryText: formatSleepDetail(lastSleep),
                onTap: onSleepTapped
            )
            .accessibilityLabel(lastSleepAccessibilityLabel)
            .accessibilityHint("Double tap to open sleep details")
        }
    }
    
    private var lastSleepAccessibilityLabel: String {
        if let active = activeSleep {
            return "Sleeping, \(formatActiveDuration(active)) so far"
        }
        if let sleep = lastSleep, let end = sleep.endTime {
            return "Last nap ended \(DateUtils.formatDetailedRelativeTime(end))"
        }
        return "No sleep logged yet"
    }
    
    private var nextNapCard: some View {
        HomeSummaryCard(
            icon: "alarm.fill",
            iconColor: .eventSleep,
            title: "Next Nap",
            primaryText: formatNextNapPrimary(nextNapWindow),
            secondaryText: nextNapWindow?.reason ?? "Learning your baby’s rhythm",
            onTap: onNapTapped
        )
        .accessibilityLabel(nextNapAccessibilityLabel)
        .accessibilityHint("Double tap to view nap prediction details")
    }
    
    private var nextNapAccessibilityLabel: String {
        if let window = nextNapWindow {
            return "Next nap around \(formatWindowRange(window))"
        }
        return "Next nap prediction unavailable yet"
    }
    
    // MARK: - Formatting Helpers
    
    private func formatFeedDetail(_ event: Event?) -> String {
        guard let event else { return "Tap to log a feed" }
        if let amount = event.amount, let unit = event.unit {
            let roundedAmount: String
            if amount >= 100 {
                roundedAmount = "\(Int(amount))"
            } else if amount >= 10 {
                roundedAmount = String(format: "%.1f", amount)
            } else {
                roundedAmount = String(format: "%.2f", amount)
            }
            return "\(roundedAmount) \(unit)"
        }
        if let subtype = event.subtype {
            return subtype.capitalized
        }
        return "Logged"
    }
    
    private func formatSleepDetail(_ event: Event?) -> String {
        guard let event, let duration = event.durationMinutes else { return "Tap to log sleep" }
        return "Nap • \(DateUtils.formatDuration(minutes: duration))"
    }
    
    private func formatActiveDuration(_ event: Event) -> String {
        let minutes = Int(Date().timeIntervalSince(event.startTime) / 60)
        return DateUtils.formatDuration(minutes: max(minutes, 1))
    }
    
    private func formatNextNapPrimary(_ window: NapWindow?) -> String {
        guard let window else { return "Learning schedule" }
        let now = Date()
        if window.start > now {
            let minutes = Int(window.start.timeIntervalSince(now) / 60)
            if minutes <= 0 {
                return "Soon"
            } else if minutes < 90 {
                return "in ~\(minutes)m"
            } else {
                let hours = minutes / 60
                let mins = minutes % 60
                return mins == 0 ? "in ~\(hours)h" : "in ~\(hours)h \(mins)m"
            }
        } else if window.end > now {
            return "Window open"
        } else {
            return "Try winding down"
        }
    }
    
    private func formatWindowRange(_ window: NapWindow) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: window.start)) – \(formatter.string(from: window.end))"
    }
}

private struct HomeSummaryCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let primaryText: String
    let secondaryText: String?
    var isEmphasized: Bool = false
    var onTap: (() -> Void)?
    
    var body: some View {
        Button(action: {
            onTap?()
            Haptics.selection()
        }) {
            VStack(alignment: .leading, spacing: .spacingSM) {
                HStack(spacing: .spacingXS) {
                    Image(systemName: icon)
                        .font(.headline)
                        .foregroundColor(iconColor)
                        .accessibilityHidden(true)
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.mutedForeground)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer(minLength: 0)
                }
                
                Text(primaryText)
                    .font(isEmphasized ? .title3.weight(.bold) : .title3.weight(.semibold))
                    .foregroundColor(.foreground)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if let secondaryText, !secondaryText.isEmpty {
                    Text(secondaryText)
                        .font(.footnote)
                        .foregroundColor(.mutedForeground)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(.spacingMD)
            .frame(width: 220, alignment: .leading)
            .background(Color.surface)
            .cornerRadius(.radiusLG)
            .overlay(
                RoundedRectangle(cornerRadius: .radiusLG)
                    .stroke(Color.cardBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

/// Sticky banner that surfaces an active session (sleep/feed) with live timer.
struct OngoingTimerBanner: View {
    let event: Event
    let onStop: () -> Void
    var onEdit: (() -> Void)?
    
    @State private var now: Date = Date()
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    
    private var elapsedDescription: String {
        let minutes = Int(now.timeIntervalSince(event.startTime) / 60)
        return DateUtils.formatDuration(minutes: max(minutes, 1))
    }
    
    private var isSleep: Bool {
        event.type == .sleep
    }
    
    var body: some View {
        HStack(spacing: .spacingMD) {
            ZStack {
                Circle()
                    .fill((isSleep ? Color.eventSleep : Color.eventFeed).opacity(0.16))
                    .frame(width: 44, height: 44)
                Image(systemName: isSleep ? "moon.zzz.fill" : "timer")
                    .foregroundColor(isSleep ? .eventSleep : .eventFeed)
                    .font(.headline)
            }
            .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(isSleep ? "Sleeping" : "Ongoing")
                    .font(.headline)
                    .foregroundColor(.foreground)
                Text("\(elapsedDescription) so far")
                    .font(.subheadline)
                    .foregroundColor(.mutedForeground)
                    .lineLimit(1)
            }
            
            Spacer(minLength: 0)
            
            HStack(spacing: .spacingSM) {
                if let onEdit {
                    Button("Edit") {
                        Haptics.selection()
                        onEdit()
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.surface)
                    .cornerRadius(.radiusSM)
                    .overlay(
                        RoundedRectangle(cornerRadius: .radiusSM)
                            .stroke(Color.cardBorder, lineWidth: 1)
                    )
                }
                
                Button("Stop") {
                    Haptics.light()
                    onStop()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background((isSleep ? Color.eventSleep : Color.eventFeed))
                .cornerRadius(.radiusMD)
                .accessibilityLabel("Stop timer")
                .accessibilityHint("Stops the current session")
            }
        }
        .padding(.spacingMD)
        .background(Color.elevated)
        .cornerRadius(.radiusLG)
        .overlay(
            RoundedRectangle(cornerRadius: .radiusLG)
                .stroke(Color.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 6)
        .onReceive(timer) { newDate in
            now = newDate
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(isSleep ? "Sleeping" : "Ongoing"), \(elapsedDescription) elapsed")
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
