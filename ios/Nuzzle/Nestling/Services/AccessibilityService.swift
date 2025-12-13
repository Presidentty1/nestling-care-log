import SwiftUI
import Combine

/// Centralized accessibility service for the app
/// Provides Dynamic Type support, VoiceOver helpers, and touch target enforcement
@MainActor
final class AccessibilityService: ObservableObject {
    static let shared = AccessibilityService()
    
    // MARK: - Published Properties
    
    @Published var isVoiceOverRunning: Bool = false
    @Published var isSwitchControlRunning: Bool = false
    @Published var isReduceMotionEnabled: Bool = false
    @Published var isBoldTextEnabled: Bool = false
    @Published var prefersCrossFadeTransitions: Bool = false
    @Published var shouldDifferentiateWithoutColor: Bool = false
    @Published var isReduceTransparencyEnabled: Bool = false
    @Published var preferredContentSizeCategory: UIContentSizeCategory = .medium
    
    // MARK: - Computed Properties
    
    /// Returns true if any assistive technology is active
    var isAssistiveTechnologyActive: Bool {
        isVoiceOverRunning || isSwitchControlRunning
    }
    
    /// Returns true if user needs extra large text
    var needsExtraLargeText: Bool {
        let largeCategories: [UIContentSizeCategory] = [
            .accessibilityMedium,
            .accessibilityLarge,
            .accessibilityExtraLarge,
            .accessibilityExtraExtraLarge,
            .accessibilityExtraExtraExtraLarge
        ]
        return largeCategories.contains(preferredContentSizeCategory)
    }
    
    /// Returns the minimum recommended touch target size
    var minimumTouchTargetSize: CGFloat {
        // Apple's HIG recommends 44pt, but for accessibility we increase
        isAssistiveTechnologyActive || needsExtraLargeText ? 56 : 44
    }
    
    /// Animation duration multiplier based on reduce motion preference
    var animationDurationMultiplier: Double {
        isReduceMotionEnabled ? 0.01 : 1.0
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        setupNotifications()
        refreshAccessibilityState()
    }
    
    // MARK: - Setup
    
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: UIAccessibility.voiceOverStatusDidChangeNotification)
            .sink { [weak self] _ in
                self?.refreshAccessibilityState()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIAccessibility.switchControlStatusDidChangeNotification)
            .sink { [weak self] _ in
                self?.refreshAccessibilityState()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIAccessibility.reduceMotionStatusDidChangeNotification)
            .sink { [weak self] _ in
                self?.refreshAccessibilityState()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIAccessibility.boldTextStatusDidChangeNotification)
            .sink { [weak self] _ in
                self?.refreshAccessibilityState()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIContentSizeCategory.didChangeNotification)
            .sink { [weak self] _ in
                self?.refreshAccessibilityState()
            }
            .store(in: &cancellables)
    }
    
    private func refreshAccessibilityState() {
        isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
        isSwitchControlRunning = UIAccessibility.isSwitchControlRunning
        isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
        isBoldTextEnabled = UIAccessibility.isBoldTextEnabled
        prefersCrossFadeTransitions = UIAccessibility.prefersCrossFadeTransitions
        shouldDifferentiateWithoutColor = UIAccessibility.shouldDifferentiateWithoutColor
        isReduceTransparencyEnabled = UIAccessibility.isReduceTransparencyEnabled
        preferredContentSizeCategory = UIApplication.shared.preferredContentSizeCategory
    }
    
    // MARK: - VoiceOver Helpers
    
    /// Post an announcement to VoiceOver
    static func announce(_ message: String, afterDelay: TimeInterval = 0) {
        if afterDelay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + afterDelay) {
                UIAccessibility.post(notification: .announcement, argument: message)
            }
        } else {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }
    
    /// Notify VoiceOver that the screen has changed
    static func screenChanged(focusElement: Any? = nil) {
        UIAccessibility.post(notification: .screenChanged, argument: focusElement)
    }
    
    /// Notify VoiceOver that the layout has changed
    static func layoutChanged(focusElement: Any? = nil) {
        UIAccessibility.post(notification: .layoutChanged, argument: focusElement)
    }
    
    // MARK: - Accessibility Label Helpers
    
    /// Creates a time-based accessibility label (e.g., "2 hours ago" or "at 3:45 PM")
    static func timeLabel(for date: Date, style: TimeAccessibilityStyle = .relative) -> String {
        switch style {
        case .relative:
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            return formatter.localizedString(for: date, relativeTo: Date())
            
        case .absolute:
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateStyle = .none
            return "at \(formatter.string(from: date))"
            
        case .both:
            let relative = timeLabel(for: date, style: .relative)
            let absolute = timeLabel(for: date, style: .absolute)
            return "\(relative), \(absolute)"
        }
    }
    
    /// Creates a duration accessibility label
    static func durationLabel(minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours) hour\(hours == 1 ? "" : "s")"
            } else {
                return "\(hours) hour\(hours == 1 ? "" : "s") and \(remainingMinutes) minute\(remainingMinutes == 1 ? "" : "s")"
            }
        }
    }
    
    /// Creates an amount accessibility label with proper unit pronunciation
    static func amountLabel(amount: Double, unit: String) -> String {
        let formattedAmount = amount.truncatingRemainder(dividingBy: 1) == 0 
            ? String(format: "%.0f", amount) 
            : String(format: "%.1f", amount)
        
        let unitSpoken: String
        switch unit.lowercased() {
        case "ml":
            unitSpoken = "milliliters"
        case "oz":
            let isPlural = amount != 1
            unitSpoken = isPlural ? "ounces" : "ounce"
        case "min", "mins", "minutes":
            let isPlural = amount != 1
            unitSpoken = isPlural ? "minutes" : "minute"
        default:
            unitSpoken = unit
        }
        
        return "\(formattedAmount) \(unitSpoken)"
    }
    
    enum TimeAccessibilityStyle {
        case relative
        case absolute
        case both
    }
}

// MARK: - SwiftUI View Extensions

extension View {
    /// Ensures the view meets minimum touch target size requirements
    func accessibleTouchTarget(
        minWidth: CGFloat? = nil,
        minHeight: CGFloat? = nil
    ) -> some View {
        let service = AccessibilityService.shared
        let targetSize = service.minimumTouchTargetSize
        
        return self.frame(
            minWidth: minWidth ?? targetSize,
            minHeight: minHeight ?? targetSize
        )
        .contentShape(Rectangle()) // Ensure entire area is tappable
    }
    
    /// Adds standard accessibility traits for interactive elements
    func accessibleButton(
        label: String,
        hint: String? = nil,
        isEnabled: Bool = true
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isButton)
            .accessibilityRemoveTraits(isEnabled ? [] : .isButton)
            .accessibilityAddTraits(isEnabled ? [] : .isStaticText)
    }
    
    /// Adds accessibility for toggle/switch controls
    func accessibleToggle(
        label: String,
        isOn: Bool,
        hint: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityValue(isOn ? "On" : "Off")
            .accessibilityHint(hint ?? "Double tap to toggle")
            .accessibilityAddTraits(.isButton)
    }
    
    /// Adds accessibility for time-based displays
    func accessibleTime(
        date: Date,
        context: String,
        style: AccessibilityService.TimeAccessibilityStyle = .both
    ) -> some View {
        let timeLabel = AccessibilityService.timeLabel(for: date, style: style)
        return self.accessibilityLabel("\(context): \(timeLabel)")
    }
    
    /// Adds accessibility for progress/status displays
    func accessibleProgress(
        label: String,
        current: Double,
        total: Double,
        unit: String = ""
    ) -> some View {
        let percentage = Int((current / total) * 100)
        let valueText = unit.isEmpty 
            ? "\(Int(current)) of \(Int(total))" 
            : "\(Int(current)) of \(Int(total)) \(unit)"
        
        return self
            .accessibilityLabel(label)
            .accessibilityValue("\(valueText), \(percentage) percent")
    }
    
    /// Adaptive layout that switches to vertical stacking for large text
    func adaptiveHStack<Content: View>(
        spacing: CGFloat = .spacingMD,
        @ViewBuilder content: () -> Content
    ) -> some View {
        AdaptiveHStack(spacing: spacing, content: content)
    }
    
    /// Hides from accessibility when decorative
    func accessibilityHiddenIfDecorative(_ isDecorative: Bool = true) -> some View {
        self.accessibilityHidden(isDecorative)
    }
    
    /// Applies reduced motion animations
    func reducedMotionAnimation<V: Equatable>(
        _ animation: Animation? = .default,
        value: V
    ) -> some View {
        let reducedAnimation = AccessibilityService.shared.isReduceMotionEnabled 
            ? nil 
            : animation
        return self.animation(reducedAnimation, value: value)
    }
}

// MARK: - Adaptive Layout Components

/// A stack that switches between HStack and VStack based on content size category
struct AdaptiveHStack<Content: View>: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    let spacing: CGFloat
    let content: Content
    
    init(spacing: CGFloat = .spacingMD, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: spacing) {
                content
            }
        } else {
            HStack(spacing: spacing) {
                content
            }
        }
    }
}

/// A view that scales with Dynamic Type
struct ScaledView<Content: View>: View {
    @ScaledMetric(relativeTo: .body) var scale: CGFloat
    
    let baseSize: CGFloat
    let content: (CGFloat) -> Content
    
    init(baseSize: CGFloat, @ViewBuilder content: @escaping (CGFloat) -> Content) {
        self._scale = ScaledMetric(wrappedValue: baseSize, relativeTo: .body)
        self.baseSize = baseSize
        self.content = content
    }
    
    var body: some View {
        content(scale)
    }
}

// MARK: - Accessibility Modifiers

/// Modifier for ensuring minimum touch target
struct MinimumTouchTargetModifier: ViewModifier {
    @ObservedObject var accessibilityService = AccessibilityService.shared
    
    func body(content: Content) -> some View {
        content
            .frame(minWidth: accessibilityService.minimumTouchTargetSize,
                   minHeight: accessibilityService.minimumTouchTargetSize)
            .contentShape(Rectangle())
    }
}

/// Modifier for Dynamic Type aware spacing
struct DynamicSpacingModifier: ViewModifier {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    let baseSpacing: CGFloat
    
    var adjustedSpacing: CGFloat {
        if dynamicTypeSize.isAccessibilitySize {
            return baseSpacing * 1.5
        } else if dynamicTypeSize >= .xxxLarge {
            return baseSpacing * 1.25
        }
        return baseSpacing
    }
    
    func body(content: Content) -> some View {
        content.padding(adjustedSpacing)
    }
}

extension View {
    func dynamicPadding(_ spacing: CGFloat) -> some View {
        modifier(DynamicSpacingModifier(baseSpacing: spacing))
    }
    
    func minimumTouchTarget() -> some View {
        modifier(MinimumTouchTargetModifier())
    }
}

// MARK: - Accessibility Preview Helpers

#if DEBUG
extension View {
    /// Preview with different accessibility configurations
    func accessibilityPreview() -> some View {
        VStack {
            // Normal
            self
                .previewDisplayName("Normal")
            
            // Extra Large Text
            self
                .dynamicTypeSize(.accessibility1)
                .previewDisplayName("AX1")
            
            // VoiceOver simulation (visual indicator only)
            self
                .border(Color.blue, width: 2)
                .previewDisplayName("VO Focus")
        }
    }
}
#endif
