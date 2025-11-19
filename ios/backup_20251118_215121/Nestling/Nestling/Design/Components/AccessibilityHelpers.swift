import SwiftUI

/// Helper for accessibility features
struct AccessibilityHelpers {
    /// Check if High Contrast is enabled
    static var isHighContrastEnabled: Bool {
        UIAccessibility.isDarkerSystemColorsEnabled || UIAccessibility.isIncreaseContrastEnabled
    }
    
    /// Enhanced contrast color for high contrast mode
    static func enhancedContrastColor(_ baseColor: Color) -> Color {
        if isHighContrastEnabled {
            // Return darker/more saturated version for better contrast
            return baseColor.opacity(0.9)
        }
        return baseColor
    }
}

extension View {
    /// Apply high contrast adjustments if enabled
    func highContrastAdjustment() -> some View {
        self.modifier(HighContrastModifier())
    }
}

struct HighContrastModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .environment(\.accessibilityHighContrastEnabled, AccessibilityHelpers.isHighContrastEnabled)
    }
}

