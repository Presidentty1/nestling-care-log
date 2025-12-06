import SwiftUI

// MARK: - Colors

/// Nuzzle adaptive theme supporting light and dark modes
enum NuzzleTheme {
    // MARK: - Light Mode Colors
    static let backgroundLight = Color(red: 248/255, green: 250/255, blue: 251/255) // #F8FAFB - Warm, nurturing white
    static let surfaceLight = Color.white // #FFFFFF - Clean, trustworthy surfaces
    static let surfaceSoftLight = Color(red: 248/255, green: 250/255, blue: 251/255).opacity(0.8) // #F8FAFB - Gentle highlights
    static let elevatedLight = Color.white // #FFFFFF - Elevated elements

    static let primaryLight = Color(red: 46/255, green: 125/255, blue: 106/255) // #2E7D6A - Calming, trustworthy teal
    static let primaryForegroundLight = Color.white
    static let primary600Light = Color(red: 37/255, green: 99/255, blue: 85/255) // #25655D - Deeper teal for interaction
    static let primary100Light = Color(red: 216/255, green: 239/255, blue: 233/255) // #D8EFE9 - Gentle teal tint

    // Event colors designed for emotional resonance and quick recognition
    static let accentFeedLight = primaryLight // #2E7D6A - Primary teal (nurturing, care)
    static let accentSleepLight = Color(red: 139/255, green: 92/255, blue: 246/255) // #8B5CF6 - Soft purple (peaceful rest)
    static let accentDiaperLight = Color(red: 245/255, green: 158/255, blue: 11/255) // #F59E0B - Warm amber (gentle attention)
    static let accentTummyLight = Color(red: 34/255, green: 197/255, blue: 94/255) // #22C55E - Fresh green (healthy growth)

    static let textPrimaryLight = Color(red: 15/255, green: 23/255, blue: 42/255) // #0F172A - Deep, readable text (trust)
    static let textSecondaryLight = Color(red: 100/255, green: 116/255, blue: 139/255) // #64748B - Supportive secondary text
    static let textSubtleLight = Color(red: 148/255, green: 163/255, blue: 184/255) // #94A3B8 - Gentle hints

    static let borderLight = Color(red: 226/255, green: 232/255, blue: 240/255) // #E2E8F0 - Soft, calming borders

    // MARK: - Dark Mode Colors (Current)
    static let background = Color(red: 5/255, green: 10/255, blue: 16/255) // #050A10 - Deep navy
    static let surface = Color(red: 13/255, green: 21/255, blue: 31/255) // #0D151F - Card background
    static let surfaceSoft = Color(red: 18/255, green: 28/255, blue: 39/255) // #121C27 - Lighter surface
    static let elevated = Color(red: 24/255, green: 39/255, blue: 55/255) // #182737 - Elevated cards

    static let primary = Color(red: 46/255, green: 199/255, blue: 166/255) // #2EC7A6 - CTA mint/teal
    static let primaryForeground = Color.white
    static let primary600 = Color(red: 37/255, green: 167/255, blue: 146/255) // #25A792 - Darker teal for pressed states
    static let primary100 = Color(red: 24/255, green: 65/255, blue: 58/255) // #18413A - Dark teal background

    static let accentFeed = primary // Same as primary for feeds
    static let accentSleep = Color(red: 154/255, green: 139/255, blue: 255/255) // #9A8BFF - Soft indigo
    static let accentDiaper = Color(red: 255/255, green: 185/255, blue: 90/255) // #FFB95A - Warm amber
    static let accentTummy = Color(red: 107/255, green: 214/255, blue: 118/255) // #6BD676 - Soft green

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textSubtle = Color.white.opacity(0.5)

    static let border = Color(red: 32/255, green: 48/255, blue: 57/255) // #203039 - Subtle borders

    // MARK: - Adaptive Color Helpers

    /// Get adaptive background color based on color scheme
    static func adaptiveBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark ? background : backgroundLight
    }

    /// Get adaptive surface color based on color scheme
    static func adaptiveSurface(for scheme: ColorScheme) -> Color {
        scheme == .dark ? surface : surfaceLight
    }

    /// Get adaptive elevated surface color based on color scheme
    static func adaptiveElevated(for scheme: ColorScheme) -> Color {
        scheme == .dark ? elevated : elevatedLight
    }

    /// Get adaptive primary color based on color scheme
    static func adaptivePrimary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? primary : primaryLight
    }

    /// Get adaptive primary foreground color based on color scheme
    static func adaptivePrimaryForeground(for scheme: ColorScheme) -> Color {
        scheme == .dark ? primaryForeground : primaryForegroundLight
    }

    /// Get adaptive text primary color based on color scheme
    static func adaptiveTextPrimary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? textPrimary : textPrimaryLight
    }

    /// Get adaptive text secondary color based on color scheme
    static func adaptiveTextSecondary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? textSecondary : textSecondaryLight
    }

    /// Get adaptive border color based on color scheme
    static func adaptiveBorder(for scheme: ColorScheme) -> Color {
        scheme == .dark ? border : borderLight
    }

    /// Get adaptive accent color for event type based on color scheme
    static func adaptiveAccent(for eventType: String, scheme: ColorScheme) -> Color {
        let colors: [String: (dark: Color, light: Color)] = [
            "feed": (accentFeed, accentFeedLight),
            "sleep": (accentSleep, accentSleepLight),
            "diaper": (accentDiaper, accentDiaperLight),
            "tummy": (accentTummy, accentTummyLight)
        ]

        guard let colorPair = colors[eventType.lowercased()] else {
            return scheme == .dark ? primary : primaryLight
        }

        return scheme == .dark ? colorPair.dark : colorPair.light
    }
}

// MARK: - Adaptive Color Extensions

extension Color {
    // Adaptive colors that respond to color scheme
    static func adaptivePrimary(_ scheme: ColorScheme) -> Color {
        NuzzleTheme.adaptivePrimary(for: scheme)
    }

    static func adaptivePrimaryForeground(_ scheme: ColorScheme) -> Color {
        NuzzleTheme.adaptivePrimaryForeground(for: scheme)
    }

    static func adaptiveBackground(_ scheme: ColorScheme) -> Color {
        NuzzleTheme.adaptiveBackground(for: scheme)
    }

    static func adaptiveSurface(_ scheme: ColorScheme) -> Color {
        NuzzleTheme.adaptiveSurface(for: scheme)
    }

    static func adaptiveElevated(_ scheme: ColorScheme) -> Color {
        NuzzleTheme.adaptiveElevated(for: scheme)
    }

    static func adaptiveForeground(_ scheme: ColorScheme) -> Color {
        NuzzleTheme.adaptiveTextPrimary(for: scheme)
    }

    static func adaptiveMutedForeground(_ scheme: ColorScheme) -> Color {
        NuzzleTheme.adaptiveTextSecondary(for: scheme)
    }

    static func adaptiveBorder(_ scheme: ColorScheme) -> Color {
        NuzzleTheme.adaptiveBorder(for: scheme)
    }

    static func adaptiveEventAccent(_ eventType: String, scheme: ColorScheme) -> Color {
        NuzzleTheme.adaptiveAccent(for: eventType, scheme: scheme)
    }

    // Legacy colors - redirect to dark mode for backward compatibility
    static let primary = NuzzleTheme.primary
    static let primaryForeground = NuzzleTheme.primaryForeground

    // Semantic colors (adaptive versions should be used in new code)
    static let success = primary
    static let warning = Color(red: 0.96, green: 0.65, blue: 0.14) // #F5A623
    static let destructive = Color(red: 0.84, green: 0.27, blue: 0.27) // #D64545
    static let info = Color(red: 0.22, green: 0.61, blue: 0.96) // #2196F3

    // Event Colors - now use theme accents (legacy)
    static let eventFeed = NuzzleTheme.accentFeed
    static let eventSleep = NuzzleTheme.accentSleep
    static let eventDiaper = NuzzleTheme.accentDiaper
    static let eventTummy = NuzzleTheme.accentTummy

    // Backgrounds - use theme colors (legacy)
    static let background = NuzzleTheme.background
    static let surface = NuzzleTheme.surface

    // Text - use theme colors (legacy)
    static let foreground = NuzzleTheme.textPrimary
    static let mutedForeground = NuzzleTheme.textSecondary
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

// MARK: - Adaptive Shadows

/// Shadow level enumeration for consistent elevation
enum ShadowLevel {
    case sm, md, lg, xl, soft

    var darkModeColor: Color {
        switch self {
        case .sm: return Color.black.opacity(0.2)
        case .md: return Color.black.opacity(0.3)
        case .lg: return Color.black.opacity(0.4)
        case .xl: return Color.black.opacity(0.5)
        case .soft: return Color.black.opacity(0.35)
        }
    }

    var lightModeColor: Color {
        switch self {
        case .sm: return Color(red: 13/255, green: 27/255, blue: 30/255).opacity(0.04) // #0D1B1E
        case .md: return Color(red: 13/255, green: 27/255, blue: 30/255).opacity(0.08) // #0D1B1E
        case .lg: return Color(red: 13/255, green: 27/255, blue: 30/255).opacity(0.12) // #0D1B1E
        case .xl: return Color(red: 13/255, green: 27/255, blue: 30/255).opacity(0.16) // #0D1B1E
        case .soft: return Color(red: 13/255, green: 27/255, blue: 30/255).opacity(0.06) // #0D1B1E
        }
    }

    var radius: CGFloat {
        switch self {
        case .sm: return 1
        case .md: return 6
        case .lg: return 12
        case .xl: return 16
        case .soft: return 10
        }
    }

    var x: CGFloat {
        switch self {
        case .sm: return 0
        case .md: return 0
        case .lg: return 0
        case .xl: return 0
        case .soft: return 0
        }
    }

    var y: CGFloat {
        switch self {
        case .sm: return 1
        case .md: return 4
        case .lg: return 8
        case .xl: return 12
        case .soft: return 6
        }
    }
}

extension View {
    /// Apply adaptive shadow based on color scheme
    func adaptiveShadow(_ level: ShadowLevel, scheme: ColorScheme) -> some View {
        let color = scheme == .dark ? level.darkModeColor : level.lightModeColor
        return self.shadow(color: color, radius: level.radius, x: level.x, y: level.y)
    }

    /// Convenience methods for common shadow levels
    func adaptiveShadowSM(_ scheme: ColorScheme) -> some View {
        adaptiveShadow(.sm, scheme: scheme)
    }

    func adaptiveShadowMD(_ scheme: ColorScheme) -> some View {
        adaptiveShadow(.md, scheme: scheme)
    }

    func adaptiveShadowLG(_ scheme: ColorScheme) -> some View {
        adaptiveShadow(.lg, scheme: scheme)
    }

    func adaptiveShadowXL(_ scheme: ColorScheme) -> some View {
        adaptiveShadow(.xl, scheme: scheme)
    }

    func adaptiveShadowSoft(_ scheme: ColorScheme) -> some View {
        adaptiveShadow(.soft, scheme: scheme)
    }
}

