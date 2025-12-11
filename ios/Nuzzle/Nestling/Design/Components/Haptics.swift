import UIKit

/// Haptic feedback helper for user interactions.
/// Respects Reduce Motion accessibility setting.
struct Haptics {
    /// Check if Reduce Motion is enabled
    private static var reduceMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }
    
    /// Check if celebrations (haptics/confetti) are enabled in settings
    private static var celebrationsEnabled: Bool {
        UserDefaults.standard.object(forKey: "celebrationsEnabled") as? Bool ?? true
    }
    
    /// Success haptic (for save, complete actions)
    static func success() {
        guard celebrationsEnabled, !reduceMotion else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
    
    /// Warning haptic (for confirmations, important notices)
    static func warning() {
        guard celebrationsEnabled, !reduceMotion else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }
    
    /// Error haptic (for failures, validation errors)
    static func error() {
        guard celebrationsEnabled, !reduceMotion else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }
    
    /// Light impact (for subtle interactions like button taps)
    static func light() {
        guard celebrationsEnabled, !reduceMotion else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Medium impact (for primary actions)
    static func medium() {
        guard celebrationsEnabled, !reduceMotion else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Heavy impact (for significant actions like delete)
    static func heavy() {
        guard celebrationsEnabled, !reduceMotion else { return }
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Selection haptic (for picker changes, toggles)
    static func selection() {
        guard celebrationsEnabled, !reduceMotion else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}

