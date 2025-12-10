import SwiftUI

/// View modifier that applies a red-tint overlay for night mode
struct NightModeOverlay: ViewModifier {
    @ObservedObject var themeManager: ThemeManager
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if themeManager.nightModeEnabled {
                        // Red tint overlay for night mode
                        Color.red
                            .opacity(0.15)
                            .blendMode(.multiply)
                            .ignoresSafeArea()
                            .allowsHitTesting(false) // Allow touches to pass through
                    }
                }
            )
    }
}

extension View {
    /// Apply night mode overlay if enabled
    func nightModeOverlay(themeManager: ThemeManager) -> some View {
        modifier(NightModeOverlay(themeManager: themeManager))
    }
}

