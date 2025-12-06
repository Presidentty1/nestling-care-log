import SwiftUI

// MARK: - Colors

extension Color {
    // Brand
    static let primary = Color(red: 0.18, green: 0.49, blue: 0.42) // #2E7D6A
    static let primaryForeground = Color.white
    
    // Semantic
    static let success = primary
    static let warning = Color(red: 0.96, green: 0.65, blue: 0.14) // #F5A623
    static let destructive = Color(red: 0.84, green: 0.27, blue: 0.27) // #D64545
    
    // Event Colors
    static let eventFeed = Color(red: 0.04, green: 0.65, blue: 0.93) // #0BA5EC
    static let eventSleep = Color(red: 0.55, green: 0.36, blue: 0.96) // #8B5CF6
    static let eventDiaper = Color(red: 0.98, green: 0.58, blue: 0.24) // #FB923C
    static let eventTummy = Color(red: 0.06, green: 0.73, blue: 0.51) // #10B981
    
    // Backgrounds
    static let background = Color(red: 0.97, green: 0.98, blue: 0.98) // #F8FAFB
    static let surface = Color.white
    
    // Text
    static let foreground = Color(red: 0.05, green: 0.11, blue: 0.12) // #0D1B1E
    static let mutedForeground = Color(red: 0.56, green: 0.63, blue: 0.66) // #8FA1A8
}

// MARK: - Spacing

extension CGFloat {
    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 16
    static let spacingLG: CGFloat = 24
    static let spacingXL: CGFloat = 32
    static let spacing2XL: CGFloat = 48
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

