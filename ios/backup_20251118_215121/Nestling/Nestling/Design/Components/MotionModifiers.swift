import SwiftUI

/// View modifiers for motion and transitions that respect Reduce Motion.
struct MotionModifiers {
    /// Check if Reduce Motion is enabled
    static var reduceMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }
}

extension View {
    /// Add a subtle transition that respects Reduce Motion.
    /// - Parameter transition: The transition to apply (default: .opacity)
    func motionTransition(_ transition: AnyTransition = .opacity) -> some View {
        if MotionModifiers.reduceMotion {
            return AnyView(self)
        } else {
            return AnyView(self.transition(transition))
        }
    }
    
    /// Add animation that respects Reduce Motion.
    /// - Parameters:
    ///   - animation: The animation to apply
    ///   - value: The value to animate
    func motionAnimation<V: Equatable>(_ animation: Animation = .easeInOut(duration: 0.2), value: V) -> some View {
        if MotionModifiers.reduceMotion {
            return AnyView(self)
        } else {
            return AnyView(self.animation(animation, value: value))
        }
    }
    
    /// Add a gentle scale effect for button presses (respects Reduce Motion).
    func gentlePress() -> some View {
        self.modifier(GentlePressModifier())
    }
}

struct GentlePressModifier: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed && !MotionModifiers.reduceMotion ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        isPressed = true
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
    }
}

/// Transition for presenting sheets (bottom slide-up)
extension AnyTransition {
    static var sheetSlide: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    }
    
    /// Transition for quick action confirmations
    static var quickAction: AnyTransition {
        .scale(scale: 0.95).combined(with: .opacity)
    }
}

