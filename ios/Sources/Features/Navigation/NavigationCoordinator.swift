import SwiftUI

@MainActor
class NavigationCoordinator: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var showFeedForm = false
    @Published var showSleepForm = false
    @Published var showDiaperForm = false
    @Published var showTummyForm = false
    @Published var showPredictions = false
    
    // Prefill data for forms
    @Published var feedPrefillAmount: Double?
    @Published var feedPrefillUnit: String?
    @Published var diaperPrefillType: String?
    @Published var tummyPrefillDuration: Double?
    
    func handleDeepLink(_ route: DeepLinkRoute) {
        switch route {
        case .logFeed(let amount, let unit):
            selectedTab = 0 // Home tab
            feedPrefillAmount = amount
            feedPrefillUnit = unit
            showFeedForm = true
        case .logDiaper(let type):
            selectedTab = 0
            diaperPrefillType = type
            showDiaperForm = true
        case .logTummy(let duration):
            selectedTab = 0
            tummyPrefillDuration = duration
            showTummyForm = true
        case .sleepStart:
            selectedTab = 0
            showSleepForm = true
        case .sleepStop:
            selectedTab = 0
            // Stop active sleep - handled by HomeViewModel
        case .openHome:
            selectedTab = 0
        case .openPredictions:
            selectedTab = 2 // Labs tab
            showPredictions = true
        case .openHistory:
            selectedTab = 1 // History tab
        case .openSettings:
            selectedTab = 3 // Settings tab
        case .unknown:
            break
        }
    }
    
    func clearPrefillData() {
        feedPrefillAmount = nil
        feedPrefillUnit = nil
        diaperPrefillType = nil
        tummyPrefillDuration = nil
    }
    
    /// Navigate to a specific event (for Spotlight deep links)
    @Published var targetEventId: String?
    @Published var targetEventDate: Date?
    
    func navigateToEvent(_ event: Event) {
        targetEventId = event.id
        targetEventDate = event.startTime
        selectedTab = 1 // History tab
    }
}

