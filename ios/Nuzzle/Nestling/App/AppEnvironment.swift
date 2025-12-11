import Foundation
import Combine

/// Central dependency container for the app.
/// Provides access to DataStore and shared view models.
@MainActor
class AppEnvironment: ObservableObject {
    let dataStore: DataStore
    let navigationCoordinator: NavigationCoordinator
    
    @Published var appSettings: AppSettings = .default()
    @Published var currentBaby: Baby?
    @Published var babies: [Baby] = []
    @Published var isCaregiverMode: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init(dataStore: DataStore) {
        self.dataStore = dataStore
        self.navigationCoordinator = NavigationCoordinator()
        loadInitialData()
        loadCaregiverMode()
    }
    
    private func loadCaregiverMode() {
        isCaregiverMode = UserDefaults.standard.bool(forKey: "isCaregiverMode")
    }
    
    func setCaregiverMode(_ enabled: Bool) {
        isCaregiverMode = enabled
        UserDefaults.standard.set(enabled, forKey: "isCaregiverMode")
        AnalyticsService.shared.track(event: "caregiver_mode_enabled", properties: [
            "enabled": enabled
        ])
    }
    
    private func loadInitialData() {
        Task {
            do {
                // Load babies
                let loadedBabies = try await dataStore.fetchBabies()
                await MainActor.run {
                    self.babies = loadedBabies
                    if currentBaby == nil, let firstBaby = loadedBabies.first {
                        self.currentBaby = firstBaby
                    }
                }
                
                // Load settings
                let settings = try await dataStore.fetchAppSettings()
                await MainActor.run {
                    self.appSettings = settings
                    UserDefaults.standard.set(settings.celebrationsEnabled, forKey: "celebrationsEnabled")
                    UserDefaults.standard.set(settings.analyticsEnabled, forKey: "analyticsEnabled")
                }
            } catch {
                print("Error loading initial data: \(error)")
            }
        }
    }
    
    func refreshBabies() async {
        do {
            let loadedBabies = try await dataStore.fetchBabies()
            await MainActor.run {
                self.babies = loadedBabies
                // Update current baby if it still exists
                if let currentId = currentBaby?.id,
                   let updatedBaby = loadedBabies.first(where: { $0.id == currentId }) {
                    self.currentBaby = updatedBaby
                } else if currentBaby == nil, let firstBaby = loadedBabies.first {
                    self.currentBaby = firstBaby
                }
            }
        } catch {
            print("Error refreshing babies: \(error)")
        }
    }
    
    func refreshSettings() {
        Task {
            do {
                let settings = try await dataStore.fetchAppSettings()
                await MainActor.run {
                    self.appSettings = settings
                    UserDefaults.standard.set(settings.celebrationsEnabled, forKey: "celebrationsEnabled")
                    UserDefaults.standard.set(settings.analyticsEnabled, forKey: "analyticsEnabled")
                }
            } catch {
                print("Error refreshing settings: \(error)")
            }
        }
    }
}

