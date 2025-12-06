import SwiftUI
import os.signpost
import CoreSpotlight
import FirebaseCore

@main
struct NuzzleApp: App {
    @StateObject private var environment: AppEnvironment
    @StateObject private var authViewModel = AuthViewModel()
    @State private var showOnboarding = false
    @State private var isCheckingAuth = true
    @State private var isCheckingOnboarding = true
    
    private let launchSignpostID: OSSignpostID
    
    init() {
        // Initialize Firebase (only if GoogleService-Info.plist exists)
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           FileManager.default.fileExists(atPath: path) {
            FirebaseApp.configure()
            print("✅ Firebase configured successfully")
        } else {
            print("⚠️ GoogleService-Info.plist not found - Firebase features will be disabled")
            print("   To enable Firebase: Add GoogleService-Info.plist to the project")
        }

        // Initialize crash reporting
        _ = CrashReportingService.shared

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
                if isCheckingAuth {
                    // Show loading screen while checking auth status
                    ZStack {
                        Color.background
                            .ignoresSafeArea()
                        VStack(spacing: .spacingMD) {
                            ProgressView()
                            Text("Loading...")
                                .font(.caption)
                                .foregroundColor(.mutedForeground)
                        }
                    }
                    .task {
                        // Add timeout to prevent infinite loading
                        let timeoutTask = Task {
                            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                            if isCheckingAuth {
                                print("⚠️ WARNING: Auth check timed out, proceeding to auth screen")
                                await MainActor.run {
                                    isCheckingAuth = false
                                }
                            }
                        }
                        
                        // Check for existing session
                        await authViewModel.restoreSession()
                        timeoutTask.cancel()
                        
                        await MainActor.run {
                            isCheckingAuth = false
                            // If session exists or auth was skipped, check onboarding
                            if authViewModel.session != nil || authViewModel.hasSkippedAuth {
                                isCheckingOnboarding = true
                                checkOnboarding()
                            }
                        }
                    }
                } else if authViewModel.session == nil && !authViewModel.hasSkippedAuth {
                    // No session and hasn't skipped - show Auth
                    AuthView(viewModel: authViewModel) {
                        // On authenticated or skipped, check onboarding immediately
                        isCheckingOnboarding = true
                        checkOnboarding()
                    }
                    .onChange(of: authViewModel.hasSkippedAuth) { oldValue, newValue in
                        // React to hasSkippedAuth changes immediately
                        if newValue && !oldValue {
                            isCheckingOnboarding = true
                            checkOnboarding()
                        }
                    }
                } else if isCheckingOnboarding {
                    // Show loading screen while checking onboarding status
                    Color.background
                        .ignoresSafeArea()
                        .overlay {
                            VStack(spacing: .spacingMD) {
                                ProgressView()
                                Text("Checking setup...")
                                    .font(.caption)
                                    .foregroundColor(.mutedForeground)
                            }
                        }
                        .task {
                            // Fallback timeout - if checkOnboarding doesn't complete in 5 seconds, proceed anyway
                            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                            if isCheckingOnboarding {
                                print("⚠️ WARNING: Onboarding check timed out, proceeding to app")
                                isCheckingOnboarding = false
                            }
                        }
                } else if showOnboarding {
                    OnboardingView(dataStore: environment.dataStore) {
                        showOnboarding = false
                        // Refresh babies and settings after onboarding completes
                        Task {
                            await environment.refreshBabies()
                            await environment.refreshSettings()
                        }
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
                            environment.navigationCoordinator.handleDeepLink(route)
                        }
                        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                            // Handle Universal Links
                            if let url = userActivity.webpageURL {
                                let route = DeepLinkRouter.parse(url: url)
                                environment.navigationCoordinator.handleDeepLink(route)
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
        }
    }
    
    // MARK: - Helper Methods
    
    private func checkOnboarding() {
        Task { @MainActor in
            print("🔍 Starting onboarding check...")
            
            // Add timeout to prevent infinite loading (declare early for guest mode)
            let timeoutTask = Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                if isCheckingOnboarding {
                    print("⚠️ WARNING: checkOnboarding timed out after 1.5 seconds, proceeding anyway")
                    await MainActor.run {
                        isCheckingOnboarding = false
                        // On timeout, just show onboarding
                        showOnboarding = true
                    }
                }
            }
            
            // For guest mode (skipped auth), proceed immediately
            if authViewModel.hasSkippedAuth {
                print("✅ Guest mode: Proceeding immediately to onboarding check")
                timeoutTask.cancel()
                isCheckingOnboarding = false
                
                // Check babies in background, but don't wait - just show onboarding for now
                // User can skip onboarding if they already have data
                Task {
                    do {
                        let babies = try await environment.dataStore.fetchBabies()
                        if !babies.isEmpty {
                            await environment.refreshBabies()
                            // If we have babies, hide onboarding
                            showOnboarding = false
                        }
                    } catch {
                        print("⚠️ Error checking babies: \(error)")
                    }
                }
                
                // Always show onboarding for guest mode (they can skip if they want)
                showOnboarding = true
                return
            }
            
            // For authenticated users, check onboarding
            let onboardingService = OnboardingService(dataStore: environment.dataStore)
            let completedResult = await withTimeout(seconds: 0.5) {
                await onboardingService.isOnboardingCompleted()
            }
            
            // Also check if user has any babies - if not, force onboarding
            let babiesResult = await withTimeout(seconds: 0.5) {
                try await environment.dataStore.fetchBabies()
            }
            
            timeoutTask.cancel()
            isCheckingOnboarding = false
            
            switch (completedResult, babiesResult) {
            case (.success(let completed), .success(let babies)):
                let hasBabies = !babies.isEmpty
                // Show onboarding if:
                // 1. Onboarding was never completed, OR
                // 2. Onboarding was completed but no babies exist (data might have been cleared)
                if !completed || !hasBabies {
                    showOnboarding = true
                } else {
                    // Refresh babies list in environment
                    await environment.refreshBabies()
                }
            default:
                // On timeout or error, show onboarding
                print("⚠️ Timeout or error during onboarding check, showing onboarding")
                showOnboarding = true
            }
        }
    }
    
    // Helper to add timeout to async operations
    private func withTimeout<T>(seconds: Double, operation: @escaping () async throws -> T) async -> Result<T, Error> {
        await withTaskGroup(of: Result<T, Error>.self) { group in
            // Add the actual operation
            group.addTask {
                do {
                    let result = try await operation()
                    return .success(result)
                } catch {
                    return .failure(error)
                }
            }
            
            // Add timeout task
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                return .failure(TimeoutError())
            }
            
            // Get first result (either success or timeout)
            let result = await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    private struct TimeoutError: Error {}
    
    /// Handle Spotlight search result tap
    private func handleSpotlightActivity(_ userActivity: NSUserActivity) {
        guard let identifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
              identifier.hasPrefix("com.nestling.events.") else {
            return
        }
        
        // Extract event ID from identifier
        let eventIdString = String(identifier.dropFirst("com.nestling.events.".count))
        guard let eventId = UUID(uuidString: eventIdString) else {
            return
        }
        
        // Navigate to History tab and scroll to event
        Task {
            environment.navigationCoordinator.selectedTab = 1 // History tab
            
            // Find event and navigate to its date
            if let baby = environment.currentBaby {
                let startDate = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
                let events = try? await environment.dataStore.fetchEvents(for: baby, from: startDate, to: Date())
                if let event = events?.first(where: { $0.id == eventId }) {
                    // Navigate to the date of the event
                    // This would be handled by HistoryViewModel
                    environment.navigationCoordinator.navigateToEvent(event)
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
                environment.navigationCoordinator.feedPrefillAmount = amount
                environment.navigationCoordinator.feedPrefillUnit = unit
                environment.navigationCoordinator.showFeedForm = true
            case .startSleep:
                environment.navigationCoordinator.showSleepForm = true
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
        .motionTransition(.opacity)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppEnvironment(dataStore: InMemoryDataStore()))
}

