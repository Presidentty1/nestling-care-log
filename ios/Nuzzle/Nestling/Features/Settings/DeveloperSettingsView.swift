import SwiftUI

struct DeveloperSettingsView: View {
    @EnvironmentObject var environment: AppEnvironment
    @StateObject private var proService = ProSubscriptionService.shared
    @StateObject private var polishFlags = PolishFeatureFlags.shared
    @State private var showWidgetTest = false
    @State private var showResetConfirmation = false
    
    var body: some View {
        List {
            Section("Widget Testing") {
                Button("Reload All Widgets") {
                    WidgetTestHelper.reloadAllWidgets()
                }
                
                Button("Test Widget Data") {
                    let testData = WidgetTestHelper.generateTestData()
                    WidgetTestHelper.testDataPersistence(data: testData)
                }
                
                Button("Clear Test Data") {
                    WidgetTestHelper.clearTestData()
                }
                
                Button("Verify App Groups") {
                    _ = WidgetTestHelper.verifyAppGroups()
                    // Could show alert with result
                }
            }
            
            Section("Subscription Testing") {
                Toggle("🔓 Enable Pro Mode (Dev Only)", isOn: Binding(
                    get: { proService.isProUser },
                    set: { newValue in
                        // Force Pro status for development testing
                        proService.isProUser = newValue
                        if newValue {
                            proService.subscriptionStatus = .subscribed
                            // Set trial days to simulate active subscription
                            proService.trialDaysRemaining = 999
                            // Persist dev mode setting
                            UserDefaults.standard.set(true, forKey: "dev_pro_mode_enabled")
                        } else {
                            proService.subscriptionStatus = .notSubscribed
                            proService.trialDaysRemaining = nil
                            // Clear dev mode setting
                            UserDefaults.standard.removeObject(forKey: "dev_pro_mode_enabled")
                        }
                    }
                ))
                .font(.headline)
                .foregroundColor(.primary)

                Text("Toggle this to enable/disable all Pro features for testing. This only works in development builds.")
                    .font(.caption)
                    .foregroundColor(.mutedForeground)

                Button("Activate Pro Mode") {
                    proService.isProUser = true
                    proService.subscriptionStatus = .subscribed
                    proService.trialDaysRemaining = 999
                    UserDefaults.standard.set(true, forKey: "dev_pro_mode_enabled")
                }
                .buttonStyle(.borderedProminent)

                Button("Deactivate Pro Mode") {
                    proService.isProUser = false
                    proService.subscriptionStatus = .notSubscribed
                    proService.trialDaysRemaining = nil
                    UserDefaults.standard.removeObject(forKey: "dev_pro_mode_enabled")
                }
                .buttonStyle(.bordered)

                Button("Simulate Trial Expiration") {
                    // Set trial to expired state
                    proService.trialDaysRemaining = nil
                    proService.isProUser = false
                    proService.subscriptionStatus = .notSubscribed
                }

                Button("Clear Subscription Data") {
                    // Clear UserDefaults related to subscriptions
                    UserDefaults.standard.removeObject(forKey: "nestling_trial_start_date")
                    UserDefaults.standard.removeObject(forKey: "dev_pro_mode_enabled")
                    proService.trialDaysRemaining = nil
                    proService.isProUser = false
                    proService.subscriptionStatus = .notSubscribed
                }

                Button("Reset Trial Eligibility") {
                    Task {
                        // Reset trial to be available again
                        UserDefaults.standard.removeObject(forKey: "nestling_trial_start_date")
                        proService.trialDaysRemaining = nil
                        await proService.checkSubscriptionStatus()
                    }
                }

                Button("Refresh Subscription Status") {
                    Task {
                        await proService.checkSubscriptionStatus()
                    }
                }
            }

            Section("Polish Feature Flags") {
                Toggle("🔧 Kill Switch - Disable All Polish", isOn: Binding(
                    get: { polishFlags.allPolishDisabled },
                    set: { enabled in
                        UserDefaults.standard.set(enabled, forKey: "polish.killSwitch")
                    }
                ))
                .font(.headline)
                .foregroundColor(.red)

                Text("Emergency disable for all polish features. Use if polish causes issues.")
                    .font(.caption)
                    .foregroundColor(.mutedForeground)

                Divider()

                Group {
                    Text("Tier 1: Quick Wins")
                        .font(.subheadline)
                        .foregroundColor(.primary)

                    Toggle("Skeleton Loading", isOn: Binding(
                        get: { polishFlags.skeletonLoadingEnabled },
                        set: { polishFlags.setFlag("skeletonLoading", enabled: $0) }
                    ))

                    Toggle("Contextual Badges", isOn: Binding(
                        get: { polishFlags.contextualBadgesEnabled },
                        set: { polishFlags.setFlag("contextualBadges", enabled: $0) }
                    ))

                    Toggle("Smart CTAs", isOn: Binding(
                        get: { polishFlags.smartCTAsEnabled },
                        set: { polishFlags.setFlag("smartCTAs", enabled: $0) }
                    ))
                }

                Group {
                    Text("Tier 2: High Impact")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .padding(.top, 8)

                    Toggle("Shareable Cards", isOn: Binding(
                        get: { polishFlags.shareCardsEnabled },
                        set: { polishFlags.setFlag("shareCards", enabled: $0) }
                    ))

                    Toggle("Timeline Grouping", isOn: Binding(
                        get: { polishFlags.timelineGroupingEnabled },
                        set: { polishFlags.setFlag("timelineGrouping", enabled: $0) }
                    ))

                    Toggle("Rich Notifications", isOn: Binding(
                        get: { polishFlags.richNotificationsEnabled },
                        set: { polishFlags.setFlag("richNotifications", enabled: $0) }
                    ))

                    Toggle("Swipe Actions", isOn: Binding(
                        get: { polishFlags.swipeActionsEnabled },
                        set: { polishFlags.setFlag("swipeActions", enabled: $0) }
                    ))
                }

                Group {
                    Text("Tier 3: Defensive")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .padding(.top, 8)

                    Toggle("Optimistic UI", isOn: Binding(
                        get: { polishFlags.optimisticUIEnabled },
                        set: { polishFlags.setFlag("optimisticUI", enabled: $0) }
                    ))

                    Toggle("Celebration Throttle", isOn: Binding(
                        get: { polishFlags.celebrationThrottleEnabled },
                        set: { polishFlags.setFlag("celebrationThrottle", enabled: $0) }
                    ))
                }

                Button("Reset All Polish Flags to Defaults") {
                    polishFlags.resetAllToDefaults()
                }
                .buttonStyle(.bordered)
                .padding(.top, 8)
            }

            Section("Data Management") {
                Button("Reset All Data", role: .destructive) {
                    showResetConfirmation = true
                }
            }
            
            Section("Debug Info") {
                HStack {
                    Text("Data Store Type")
                    Spacer()
                    Text(dataStoreType)
                        .foregroundColor(.mutedForeground)
                }

                HStack {
                    Text("Subscription Status")
                    Spacer()
                    Text(subscriptionStatusText)
                        .foregroundColor(.mutedForeground)
                }

                HStack {
                    Text("Pro User")
                    Spacer()
                    Text(proService.isProUser ? "Yes" : "No")
                        .foregroundColor(proService.isProUser ? .primary : .mutedForeground)
                }

                HStack {
                    Text("Trial Days Remaining")
                    Spacer()
                    Text(proService.trialDaysRemaining.map { "\($0)" } ?? "N/A")
                        .foregroundColor(.mutedForeground)
                }

                HStack {
                    Text("Dev Pro Mode")
                    Spacer()
                    Text(UserDefaults.standard.bool(forKey: "dev_pro_mode_enabled") ? "Enabled" : "Disabled")
                        .foregroundColor(UserDefaults.standard.bool(forKey: "dev_pro_mode_enabled") ? .primary : .mutedForeground)
                }

                HStack {
                    Text("App Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                        .foregroundColor(.mutedForeground)
                }

                DisclosureGroup("Polish Flags Debug") {
                    Text(polishFlags.debugDescription)
                        .font(.caption)
                        .foregroundColor(.mutedForeground)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .navigationTitle("Developer")
        .alert("Reset All Data", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                Task {
                    // Reset data store
                    // This would clear all data - implement carefully
                }
            }
        } message: {
            Text("This will delete all babies, events, and settings. This action cannot be undone.")
        }
    }
    
    private var dataStoreType: String {
        if environment.dataStore is JSONBackedDataStore {
            return "JSON"
        } else if String(describing: type(of: environment.dataStore)).contains("CoreData") {
            return "Core Data"
        } else {
            return "In Memory"
        }
    }

    private var subscriptionStatusText: String {
        switch proService.subscriptionStatus {
        case .notSubscribed:
            return "Not Subscribed"
        case .subscribed:
            return "Active"
        case .expired:
            return "Expired"
        case .inGracePeriod:
            return "Grace Period"
        case .inBillingRetryPeriod:
            return "Billing Retry"
        }
    }
}

#Preview {
    NavigationStack {
        DeveloperSettingsView()
            .environmentObject(AppEnvironment(dataStore: InMemoryDataStore()))
    }
}

