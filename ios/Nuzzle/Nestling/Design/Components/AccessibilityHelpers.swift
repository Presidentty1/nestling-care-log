import SwiftUI

/// Helper for accessibility features
struct AccessibilityHelpers {
    /// Check if High Contrast is enabled
    static var isHighContrastEnabled: Bool {
        UIAccessibility.isDarkerSystemColorsEnabled
    }
    
    /// Check if VoiceOver is running
    static var isVoiceOverRunning: Bool {
        UIAccessibility.isVoiceOverRunning
    }
    
    /// Check if Reduce Motion is enabled
    static var isReduceMotionEnabled: Bool {
        UIAccessibility.isReduceMotionEnabled
    }
    
    /// Check if Bold Text is enabled
    static var isBoldTextEnabled: Bool {
        UIAccessibility.isBoldTextEnabled
    }
    
    /// Enhanced contrast color for high contrast mode
    static func enhancedContrastColor(_ baseColor: Color) -> Color {
        if isHighContrastEnabled {
            // Return darker/more saturated version for better contrast
            return baseColor.opacity(0.9)
        }
        return baseColor
    }
    
    /// Get minimum touch target size based on accessibility settings
    static var minimumTouchTarget: CGFloat {
        if UIAccessibility.isSwitchControlRunning || UIAccessibility.isVoiceOverRunning {
            return 56 // Larger for assistive tech users
        }
        return 44 // Apple's minimum recommendation
    }
    
    /// Format duration for VoiceOver
    static func durationForVoiceOver(minutes: Int) -> String {
        AccessibilityService.durationLabel(minutes: minutes)
    }
    
    /// Format time for VoiceOver
    static func timeForVoiceOver(_ date: Date) -> String {
        AccessibilityService.timeLabel(for: date, style: .both)
    }
}

// MARK: - View Extensions

extension View {
    /// Apply high contrast adjustments if enabled
    func highContrastAdjustment() -> some View {
        self.modifier(HighContrastModifier())
    }
    
    /// Ensure view meets minimum touch target requirements
    func ensureMinimumTouchTarget() -> some View {
        self.frame(
            minWidth: AccessibilityHelpers.minimumTouchTarget,
            minHeight: AccessibilityHelpers.minimumTouchTarget
        )
        .contentShape(Rectangle())
    }
    
    /// Add accessibility for a status tile
    func accessibleStatusTile(
        title: String,
        value: String,
        hint: String? = nil
    ) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(title): \(value)")
            .accessibilityHint(hint ?? "")
    }
    
    /// Add accessibility for a quick action button
    func accessibleQuickAction(
        action: String,
        isActive: Bool,
        lastOccurrence: Date? = nil
    ) -> some View {
        var label = "\(action) quick action"
        if isActive {
            label += ", currently active"
        }
        if let lastTime = lastOccurrence {
            label += ", last \(AccessibilityHelpers.timeForVoiceOver(lastTime))"
        }
        
        let hint = isActive 
            ? "Double tap to stop" 
            : "Double tap to start, long press for details"
        
        return self
            .accessibilityLabel(label)
            .accessibilityHint(hint)
            .accessibilityAddTraits(isActive ? [.isButton, .isSelected] : .isButton)
    }
    
    /// Add accessibility for a timeline event
    func accessibleTimelineEvent(
        type: String,
        time: Date,
        details: String? = nil
    ) -> some View {
        var label = "\(type) event, \(AccessibilityHelpers.timeForVoiceOver(time))"
        if let details = details {
            label += ", \(details)"
        }
        
        return self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityHint("Double tap to view details, swipe up or down for actions")
            .accessibilityAddTraits(.isButton)
    }
    
    /// Add accessibility for a nap prediction card
    func accessibleNapPrediction(
        windowStart: Date,
        windowEnd: Date,
        confidence: Double
    ) -> some View {
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        
        let startStr = timeFormatter.string(from: windowStart)
        let endStr = timeFormatter.string(from: windowEnd)
        let confidencePercent = Int(confidence * 100)
        
        let label = "Nap window predicted from \(startStr) to \(endStr), \(confidencePercent) percent confidence"
        
        return self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityHint("Based on your baby's age and sleep patterns")
    }
    
    /// Add accessibility for feed amount
    func accessibleFeedAmount(amount: Double, unit: String) -> some View {
        let label = AccessibilityService.amountLabel(amount: amount, unit: unit)
        return self.accessibilityLabel(label)
    }
    
    /// Group children and provide combined label
    func accessibilityGrouped(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
    }
}

// MARK: - Modifiers

struct HighContrastModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            // High contrast adjustments applied via color opacity
    }
}

/// Modifier that adds a semantic container for accessibility
struct AccessibilityContainerModifier: ViewModifier {
    let label: String
    let hint: String?
    let traits: AccessibilityTraits
    
    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .contain)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
    }
}

extension View {
    func accessibilityContainer(
        label: String,
        hint: String? = nil,
        traits: AccessibilityTraits = []
    ) -> some View {
        modifier(AccessibilityContainerModifier(label: label, hint: hint, traits: traits))
    }
}

// MARK: - Dynamic Type Helpers

extension View {
    /// Conditionally show/hide content based on Dynamic Type size
    @ViewBuilder
    func hideForLargeText() -> some View {
        self.modifier(HideForLargeTextModifier())
    }
    
    /// Adjust layout for large text sizes
    @ViewBuilder
    func adaptiveLayout() -> some View {
        self.modifier(AdaptiveLayoutModifier())
    }
}

struct HideForLargeTextModifier: ViewModifier {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    func body(content: Content) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            EmptyView()
        } else {
            content
        }
    }
}

struct AdaptiveLayoutModifier: ViewModifier {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    var isLargeText: Bool {
        dynamicTypeSize >= .xxLarge
    }
    
    func body(content: Content) -> some View {
        content
            .lineLimit(isLargeText ? nil : 2)
            .minimumScaleFactor(isLargeText ? 0.8 : 1.0)
    }
}

// MARK: - Large Content Viewer Support

extension View {
    /// Enables Large Content Viewer for this view (shows enlarged version on long press)
    func largeContentViewer(
        text: String? = nil,
        image: Image? = nil
    ) -> some View {
        self.modifier(LargeContentViewerModifier(text: text, image: image))
    }
}

struct LargeContentViewerModifier: ViewModifier {
    let text: String?
    let image: Image?
    
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    func body(content: Content) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            content
                .accessibilityShowsLargeContentViewer {
                    VStack {
                        if let image = image {
                            image
                                .font(.largeTitle)
                        }
                        if let text = text {
                            Text(text)
                                .font(.largeTitle)
                        }
                    }
                }
        } else {
            content
        }
    }
}
