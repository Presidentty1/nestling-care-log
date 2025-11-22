import UIKit

/// Haptic feedback helper for user interactions.
/// Respects Reduce Motion accessibility setting.
struct Haptics {
    /// Check if Reduce Motion is enabled
    private static var reduceMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }
    
    /// Success haptic (for save, complete actions)
    static func success() {
        guard !reduceMotion else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
    
    /// Warning haptic (for confirmations, important notices)
    static func warning() {
        guard !reduceMotion else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }
    
    /// Error haptic (for failures, validation errors)
    static func error() {
        guard !reduceMotion else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }
    
    /// Light impact (for subtle interactions like button taps)
    static func light() {
        guard !reduceMotion else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Medium impact (for primary actions)
    static func medium() {
        guard !reduceMotion else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Heavy impact (for significant actions like delete)
    static func heavy() {
        guard !reduceMotion else { return }
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Selection haptic (for picker changes, toggles)
    static func selection() {
        guard !reduceMotion else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}

