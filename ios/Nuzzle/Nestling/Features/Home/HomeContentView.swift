import SwiftUI

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
    
    var body: some View {
        ScrollView {
            VStack(spacing: .spacingXL) {
                babySelectorSection
                trialBannerSection
                firstLogSection
                statusTilesSection
                
                // UX-03: Quick Actions always appear early (above fold) for fast logging
                quickActionsSection
                
                guidanceStripSection
                
                // Dynamic Layout (Epic 7 AC7.2) - Enhanced with goal-based personalization
                // Note: Quick Actions moved above to ensure visibility without scroll
                if viewModel.shouldSimplifyUI {
                    // "Just Survive" mode: Minimal insights
                    streaksSection
                } else if viewModel.shouldPrioritizeSleep {
                    // "Track Sleep" goal: Show nap insights
                    insightSection
                    streaksSection
                } else if viewModel.shouldPrioritizeFeeding {
                    // "Monitor Feeding" goal: Show feeding insights
                    insightSection
                    streaksSection
                } else if viewModel.timeOfDay == .morning || viewModel.timeOfDay == .day {
                    // Default day: Insights after actions
                    insightSection
                    streaksSection
                } else {
                    // Default evening/night: Insights/Summary
                    insightSection
                    streaksSection
                }
                
                timelineContent(for: viewModel)
            }
            .padding(.bottom, .spacingXL)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
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
