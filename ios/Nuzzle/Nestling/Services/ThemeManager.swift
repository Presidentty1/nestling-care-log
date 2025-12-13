import SwiftUI
import Combine

/// Manages the app's theme preferences and provides the effective color scheme
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    /// Storage key for theme preference
    private static let themePreferenceKey = "app_theme_preference"
    /// Storage key for night mode (red tint)
    private static let nightModeKey = "app_night_mode_enabled"
    
    private init() {}

    /// User's theme preference: "light", "dark", or nil for system
    @AppStorage(ThemeManager.themePreferenceKey)
    var themePreference: String? {
        didSet {
            // Trigger UI updates with animation
            withAnimation(.easeInOut(duration: 0.3)) {
                objectWillChange.send()
            }
        }
    }
    
    /// Night Mode (red tint) for low-light usage
    @AppStorage(ThemeManager.nightModeKey)
    var nightModeEnabled: Bool = false {
        didSet {
            withAnimation(.easeInOut(duration: 0.3)) {
                objectWillChange.send()
            }
        }
    }

    /// The effective color scheme based on user preference and system setting
    var effectiveTheme: ColorScheme? {
        switch themePreference {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil // System preference
        }
    }

    /// Whether night mode colors should be used
    var nightModeColors: Bool {
        nightModeEnabled || autoNightMode
    }

    /// Auto-enable night mode based on time (10pm-6am)
    var autoNightMode: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 22 || hour < 6
    }

    /// Whether the user has explicitly set a theme (vs using system)
    var hasExplicitThemePreference: Bool {
        themePreference != nil
    }

    /// Set theme to light mode
    func setLightMode() {
        themePreference = "light"
    }

    /// Set theme to dark mode
    func setDarkMode() {
        themePreference = "dark"
    }

    /// Set theme to follow system preference
    func setSystemMode() {
        themePreference = nil
    }

    /// Toggle between light and dark (for quick toggle buttons)
    func toggleTheme() {
        if themePreference == "light" {
            setDarkMode()
        } else {
            setLightMode()
        }
    }

    /// Get the current system color scheme
    var systemColorScheme: ColorScheme? {
        #if canImport(UIKit)
        return UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .light
        #else
        return nil
        #endif
    }
}