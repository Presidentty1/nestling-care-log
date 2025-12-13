import SwiftUI

/// Simplified home view for night-time use - minimal interface to reduce cognitive load
struct NightModeHomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @EnvironmentObject var environment: AppEnvironment
    @Binding var showFeedForm: Bool
    @Binding var showSleepForm: Bool
    @Binding var showDiaperForm: Bool
    @Binding var showTummyForm: Bool
    @Binding var showCryRecorder: Bool

    private var currentBaby: Baby? {
        environment.currentBaby
    }

    var body: some View {
        VStack(spacing: .spacing3XL) {
            // Header with baby name and time
            VStack(spacing: .spacingSM) {
                if let baby = currentBaby {
                    Text(baby.name)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.foreground)
                }

                Text(DateUtils.formatTime(Date()))
                    .font(.system(size: 16))
                    .foregroundColor(.mutedForeground)
            }
            .padding(.top, .spacing3XL)

            Spacer()

            // Quick Actions - Only Sleep and Feed for night time
            VStack(spacing: .spacingXL) {
                // Sleep action (prominent when active)
                if viewModel.activeSleep != nil {
                    VStack(spacing: .spacingMD) {
                        Text("Sleep Active")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.eventSleep)

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
                        .frame(height: 120)
                    }
                } else {
                    QuickActionButton(
                        title: "Start Sleep",
                        icon: "moon.fill",
                        color: .eventSleep,
                        action: {
                            viewModel.quickLogSleep()
                        },
                        longPressAction: {
                            showSleepForm = true
                        }
                    )
                    .frame(height: 100)
                }

                // Feed action
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
                .frame(height: 100)
            }

            Spacer()

            // Status bar - time since last events
            VStack(spacing: .spacingSM) {
                if let lastFeed = viewModel.events.filter({ $0.type == .feed }).last {
                    HStack {
                        Image(systemName: "drop.fill")
                            .foregroundColor(.eventFeed)
                        Text("Last feed: \(DateUtils.formatRelativeTime(lastFeed.startTime))")
                            .foregroundColor(.mutedForeground)
                    }
                }

                if let lastSleep = viewModel.events.filter({ $0.type == .sleep }).last {
                    HStack {
                        Image(systemName: "moon.fill")
                            .foregroundColor(.eventSleep)
                        Text("Last sleep: \(DateUtils.formatRelativeTime(lastSleep.startTime))")
                            .foregroundColor(.mutedForeground)
                    }
                }
            }
            .font(.system(size: 14))
            .padding(.bottom, .spacing2XL)
        }
        .background(Color.nightBackground)
        .ignoresSafeArea()
    }
}

#Preview {
    NightModeHomeView(
        viewModel: HomeViewModel(
            dataStore: InMemoryDataStore(),
            baby: Baby.mock(),
            showToast: { _, _ in }
        ),
        showFeedForm: .constant(false),
        showSleepForm: .constant(false),
        showDiaperForm: .constant(false),
        showTummyForm: .constant(false),
        showCryRecorder: .constant(false)
    )
}

