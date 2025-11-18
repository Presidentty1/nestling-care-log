import SwiftUI
import os.signpost

@main
struct NestlingApp: App {
    @StateObject private var environment: AppEnvironment
    @State private var showOnboarding = false
    
    private let launchSignpostID: OSSignpostID
    
    init() {
        // Use DataStoreSelector to choose implementation
        // Defaults to Core Data if available, falls back to JSON
        let dataStore = DataStoreSelector.create()
        _environment = StateObject(wrappedValue: AppEnvironment(dataStore: dataStore))
        
        // Start launch signpost
        launchSignpostID = SignpostLogger.beginInterval("AppLaunch", log: SignpostLogger.ui)
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if showOnboarding {
                    OnboardingView(dataStore: environment.dataStore) {
                        showOnboarding = false
                        environment.refreshBabies()
                        environment.refreshSettings()
                    }
                } else {
                    ContentView()
                        .environmentObject(environment)
                        .appPrivacy(enabled: PrivacyManager.shared.isAppPrivacyEnabled)
                        .onAppear {
                            // End launch signpost when ContentView appears
                            SignpostLogger.endInterval("AppLaunch", signpostID: launchSignpostID, log: SignpostLogger.ui)
                            
                            // Process pending widget actions
                            processWidgetActions()
                        }
                        .onOpenURL { url in
                            let route = DeepLinkRouter.parse(url: url)
                            if let coordinator = environment.navigationCoordinator {
                                coordinator.handleDeepLink(route)
                            }
                        }
                        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                            // Handle Universal Links
                            if let url = userActivity.webpageURL {
                                let route = DeepLinkRouter.parse(url: url)
                                if let coordinator = environment.navigationCoordinator {
                                    coordinator.handleDeepLink(route)
                                }
                            }
                        }
                        .onContinueUserActivity(CSSearchableItemActionType) { userActivity in
                            // Handle Spotlight search results
                            handleSpotlightActivity(userActivity)
                        }
                        .task {
                            // Check Face ID if enabled
                            if PrivacyManager.shared.isFaceIDEnabled {
                                let authenticated = await AuthenticationManager.shared.authenticate()
                                if !authenticated {
                                    // Handle authentication failure
                                }
                            }
                        }
                }
            }
            .task {
                // Check if onboarding is needed
                let onboardingService = OnboardingService(dataStore: environment.dataStore)
                let completed = await onboardingService.isOnboardingCompleted()
                if !completed {
                    showOnboarding = true
                }
            }
        }
    }
    
    /// Handle Spotlight search result tap
    private func handleSpotlightActivity(_ userActivity: NSUserActivity) {
        guard let identifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
              identifier.hasPrefix("com.nestling.events.") else {
            return
        }
        
        // Extract event ID from identifier
        let eventId = String(identifier.dropFirst("com.nestling.events.".count))
        
        // Navigate to History tab and scroll to event
        Task {
            if let coordinator = environment.navigationCoordinator {
                coordinator.selectedTab = 1 // History tab
                
                // Find event and navigate to its date
                if let baby = environment.currentBaby {
                    let events = try? await environment.dataStore.fetchEvents(for: baby)
                    if let event = events?.first(where: { $0.id == eventId }) {
                        // Navigate to the date of the event
                        // This would be handled by HistoryViewModel
                        coordinator.navigateToEvent(event)
                    }
                }
            }
        }
    }
    
    /// Process widget actions queued from widgets
    private func processWidgetActions() {
        guard let (action, parameters) = WidgetActionService.shared.consumePendingAction() else {
            return
        }
        
        Task { @MainActor in
            // Actions are processed via deep links or direct DataStore calls
            // Widget actions trigger navigation or data operations
            switch action {
            case .logFeed120ml, .logFeed150ml:
                let amount = parameters["amount"] as? Double ?? 120
                let unit = parameters["unit"] as? String ?? "ml"
                // Trigger feed form with prefill
                if let coordinator = environment.navigationCoordinator {
                    coordinator.feedPrefillAmount = amount
                    coordinator.feedPrefillUnit = unit
                    coordinator.showFeedForm = true
                }
            case .startSleep:
                if let coordinator = environment.navigationCoordinator {
                    coordinator.showSleepForm = true
                }
            case .stopSleep:
                // Stop active sleep - handled by HomeViewModel
                break
            }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var environment: AppEnvironment
    
    var body: some View {
        TabView(selection: Binding(
            get: { environment.navigationCoordinator.selectedTab },
            set: { environment.navigationCoordinator.selectedTab = $0 }
        )) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "calendar")
                }
                .tag(1)
            
            LabsView()
                .tabItem {
                    Label("Labs", systemImage: "flask.fill")
                }
                .tag(2)
            
            SettingsRootView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .commands {
            CommandMenu("Quick Actions") {
                Button("Log Feed") {
                    if let coordinator = environment.navigationCoordinator {
                        coordinator.showFeedForm = true
                    }
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Button("Start/Stop Sleep") {
                    if let coordinator = environment.navigationCoordinator {
                        coordinator.showSleepForm = true
                    }
                }
                .keyboardShortcut("s", modifiers: .command)
                
                Button("Log Diaper") {
                    if let coordinator = environment.navigationCoordinator {
                        coordinator.showDiaperForm = true
                    }
                }
                .keyboardShortcut("d", modifiers: .command)
                
                Button("Start Tummy Timer") {
                    if let coordinator = environment.navigationCoordinator {
                        coordinator.showTummyForm = true
                    }
                }
                .keyboardShortcut("t", modifiers: .command)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppEnvironment(dataStore: InMemoryDataStore()))
}

