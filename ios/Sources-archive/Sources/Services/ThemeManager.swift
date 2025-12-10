import SwiftUI

/// Manages the app's theme preferences and provides the effective color scheme
class ThemeManager: ObservableObject {
    /// Storage key for theme preference
    private static let themePreferenceKey = "app_theme_preference"

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


