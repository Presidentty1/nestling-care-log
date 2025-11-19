import Foundation
import SwiftUI

class PrivacyManager: ObservableObject {
    @Published var isAppPrivacyEnabled = false
    @Published var isFaceIDEnabled = false
    @Published var isCaregiverModeEnabled = false
    
    static let shared = PrivacyManager()
    
    private init() {
        loadSettings()
    }
    
    private func loadSettings() {
        // Load from UserDefaults or AppSettings
        isAppPrivacyEnabled = UserDefaults.standard.bool(forKey: "appPrivacyEnabled")
        isFaceIDEnabled = UserDefaults.standard.bool(forKey: "faceIDEnabled")
        isCaregiverModeEnabled = UserDefaults.standard.bool(forKey: "caregiverModeEnabled")
    }
    
    func saveSettings() {
        UserDefaults.standard.set(isAppPrivacyEnabled, forKey: "appPrivacyEnabled")
        UserDefaults.standard.set(isFaceIDEnabled, forKey: "faceIDEnabled")
        UserDefaults.standard.set(isCaregiverModeEnabled, forKey: "caregiverModeEnabled")
    }
}

// App Privacy View Modifier
struct AppPrivacyModifier: ViewModifier {
    let enabled: Bool
    
    func body(content: Content) -> some View {
        content
            .blur(radius: enabled ? 10 : 0)
            .redacted(reason: enabled ? .placeholder : [])
    }
}

extension View {
    func appPrivacy(enabled: Bool) -> some View {
        modifier(AppPrivacyModifier(enabled: enabled))
    }
}

