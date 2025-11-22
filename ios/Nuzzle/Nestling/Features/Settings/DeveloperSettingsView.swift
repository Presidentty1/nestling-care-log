import SwiftUI

struct DeveloperSettingsView: View {
    @EnvironmentObject var environment: AppEnvironment
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
                    let verified = WidgetTestHelper.verifyAppGroups()
                    // Could show alert with result
                }
            }
            
            Section("Subscription Testing") {
                Toggle("Force Pro Status", isOn: Binding(
                    get: { ProSubscriptionService.shared.isProUser },
                    set: { newValue in
                        // For debugging only - force Pro status
                        ProSubscriptionService.shared.isProUser = newValue
                        if !newValue {
                            ProSubscriptionService.shared.subscriptionStatus = .notSubscribed
                        } else {
                            ProSubscriptionService.shared.subscriptionStatus = .subscribed
                        }
                    }
                ))

                Button("Simulate Trial Expiration") {
                    // Set trial to expired state
                    ProSubscriptionService.shared.trialDaysRemaining = nil
                    ProSubscriptionService.shared.isProUser = false
                    ProSubscriptionService.shared.subscriptionStatus = .notSubscribed
                }

                Button("Clear Subscription Data") {
                    // Clear UserDefaults related to subscriptions
                    UserDefaults.standard.removeObject(forKey: "nestling_trial_start_date")
                    ProSubscriptionService.shared.trialDaysRemaining = nil
                    ProSubscriptionService.shared.isProUser = false
                    ProSubscriptionService.shared.subscriptionStatus = .notSubscribed
                }

                Button("Reset Trial Eligibility") {
                    // Reset trial to be available again
                    UserDefaults.standard.removeObject(forKey: "nestling_trial_start_date")
                    ProSubscriptionService.shared.trialDaysRemaining = nil
                        Task { await ProSubscriptionService.shared.checkSubscriptionStatus() }
                }
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
                    Text(ProSubscriptionService.shared.isProUser ? "Yes" : "No")
                        .foregroundColor(ProSubscriptionService.shared.isProUser ? .primary : .mutedForeground)
                }

                HStack {
                    Text("Trial Days Remaining")
                    Spacer()
                    Text(ProSubscriptionService.shared.trialDaysRemaining.map { "\($0)" } ?? "N/A")
                        .foregroundColor(.mutedForeground)
                }

                HStack {
                    Text("App Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                        .foregroundColor(.mutedForeground)
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
        switch ProSubscriptionService.shared.subscriptionStatus {
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

