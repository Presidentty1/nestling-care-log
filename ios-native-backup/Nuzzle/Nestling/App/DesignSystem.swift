import SwiftUI

// MARK: - Colors

extension Color {
    // MARK: - Dark Mode Support Helper
    
    /// Create a color that adapts to light/dark mode
    static func adaptive(light: Color, dark: Color) -> Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
    
    // MARK: - Brand Colors
    
    /// Primary brand color - Teal
    static let primary = Color(red: 0.18, green: 0.49, blue: 0.42) // #2E7D6A
    static let primaryForeground = Color.white
    
    // MARK: - Semantic Colors
    
    static let success = primary
    static let warning = Color(red: 0.96, green: 0.65, blue: 0.14) // #F5A623
    static let destructive = Color(red: 0.84, green: 0.27, blue: 0.27) // #D64545
    
    // MARK: - Event Colors (Vibrant, work in both modes)
    
    /// Feed event color - Soft blue
    static let eventFeed = Color(red: 0.04, green: 0.65, blue: 0.93) // #0BA5EC
    /// Sleep event color - Purple
    static let eventSleep = Color(red: 0.55, green: 0.36, blue: 0.96) // #8B5CF6
    /// Diaper event color - Warm orange
    static let eventDiaper = Color(red: 0.98, green: 0.58, blue: 0.24) // #FB923C
    /// Tummy time event color - Green
    static let eventTummy = Color(red: 0.06, green: 0.73, blue: 0.51) // #10B981
    
    // MARK: - Background Colors (Dark Mode Adaptive)
    
    /// Main app background - Light: #F8FAFB, Dark: #0F1417
    static let background = adaptive(
        light: Color(red: 0.97, green: 0.98, blue: 0.98),
        dark: Color(red: 0.06, green: 0.08, blue: 0.09)
    )
    
    /// Card/surface background - Light: White, Dark: #141A1E
    static let surface = adaptive(
        light: Color.white,
        dark: Color(red: 0.08, green: 0.10, blue: 0.12)
    )
    
    /// Elevated surface (higher cards) - Light: White, Dark: #182127
    static let elevated = adaptive(
        light: Color.white,
        dark: Color(red: 0.09, green: 0.13, blue: 0.15)
    )
    
    // MARK: - Text Colors (Dark Mode Adaptive)
    
    /// Primary text color - Light: #0D1B1E, Dark: #EAF0F2
    static let foreground = adaptive(
        light: Color(red: 0.05, green: 0.11, blue: 0.12),
        dark: Color(red: 0.92, green: 0.94, blue: 0.95)
    )
    
    /// Secondary/muted text color - Light: #8FA1A8, Dark: #86969E
    static let mutedForeground = adaptive(
        light: Color(red: 0.56, green: 0.63, blue: 0.66),
        dark: Color(red: 0.53, green: 0.59, blue: 0.62)
    )
    
    // MARK: - UI Element Colors
    
    /// Separator/border color
    static let separator = adaptive(
        light: Color(red: 0.90, green: 0.92, blue: 0.93),
        dark: Color(red: 0.13, green: 0.19, blue: 0.22)
    )
    
    /// Card border color
    static let cardBorder = adaptive(
        light: Color(red: 0.90, green: 0.92, blue: 0.93),
        dark: Color(red: 0.13, green: 0.19, blue: 0.22)
    )
}

// MARK: - Spacing

extension CGFloat {
    static let spacing2XS: CGFloat = 2
    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 16
    static let spacingLG: CGFloat = 24
    static let spacingXL: CGFloat = 32
    static let spacing2XL: CGFloat = 48
    static let spacing3XL: CGFloat = 64
}

// MARK: - Corner Radius

extension CGFloat {
    static let radiusXS: CGFloat = 8
    static let radiusSM: CGFloat = 12
    static let radiusMD: CGFloat = 16
    static let radiusLG: CGFloat = 20
    static let radiusXL: CGFloat = 24
}

// MARK: - Typography

extension Font {
    static let largeTitle = Font.system(size: 34, weight: .bold)
    static let display = Font.system(size: 28, weight: .bold)
    static let headline = Font.system(size: 22, weight: .bold)
    static let title = Font.system(size: 17, weight: .semibold)
    static let body = Font.system(size: 15, weight: .regular)
    static let caption = Font.system(size: 13, weight: .regular)
    static let label = Font.system(size: 11, weight: .medium)
}

// MARK: - Caregiver Mode

extension CGFloat {
    /// Minimum touch target for caregiver mode (larger than standard 44pt)
    static let caregiverMinTouchTarget: CGFloat = 56
    
    /// Increased spacing for caregiver mode
    static let caregiverSpacingMultiplier: CGFloat = 1.5
}

extension Font {
    /// Larger font sizes for caregiver mode
    static let caregiverHeadline = Font.system(size: 26, weight: .bold)
    static let caregiverTitle = Font.system(size: 20, weight: .semibold)
    static let caregiverBody = Font.system(size: 18, weight: .regular)
}

