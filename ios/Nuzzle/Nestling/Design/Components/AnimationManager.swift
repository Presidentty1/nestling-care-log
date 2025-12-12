import SwiftUI

/// Centralized animation manager for consistent timing and behavior
/// Respects system preferences like Reduce Motion
struct AnimationManager {
    // MARK: - Animation Durations
    
    /// Quick response animations (button press, tap feedback)
    static let quickDuration: Double = 0.15
    
    /// Standard animations (most transitions)
    static let standardDuration: Double = 0.25
    
    /// Gentle animations (content changes, subtle feedback)
    static let gentleDuration: Double = 0.35
    
    /// Celebratory animations (onboarding complete, achievements)
    static let celebrationDuration: Double = 0.6
    
    // MARK: - Standard Animations
    
    /// Quick response for button presses
    static var quickResponse: Animation {
        if UIAccessibility.isReduceMotionEnabled {
            return .linear(duration: 0.01) // Nearly instant, respects Reduce Motion
        }
        return .easeOut(duration: quickDuration)
    }
    
    /// Standard smooth transition
    static var smooth: Animation {
        if UIAccessibility.isReduceMotionEnabled {
            return .linear(duration: 0.01)
        }
        return .easeInOut(duration: standardDuration)
    }
    
    /// Gentle spring (most UI elements)
    static var gentleSpring: Animation {
        if UIAccessibility.isReduceMotionEnabled {
            return .linear(duration: 0.01)
        }
        return .spring(response: gentleDuration, dampingFraction: 0.8)
    }
    
    /// Bouncy spring (playful moments)
    static var bouncySpring: Animation {
        if UIAccessibility.isReduceMotionEnabled {
            return .linear(duration: 0.01)
        }
        return .spring(response: 0.5, dampingFraction: 0.6)
    }
    
    /// Celebration animation (onboarding, milestones)
    static var celebration: Animation {
        if UIAccessibility.isReduceMotionEnabled {
            return .linear(duration: 0.01)
        }
        return .spring(response: celebrationDuration, dampingFraction: 0.7)
    }
    
    // MARK: - View Modifiers
    
    /// Scale effect for button press
    static func pressableScale() -> some ButtonStyle {
        PressableButtonStyle()
    }
    
    /// Fade in transition
    static var fadeIn: AnyTransition {
        if UIAccessibility.isReduceMotionEnabled {
            return .opacity
        }
        return .opacity.animation(smooth)
    }
    
    /// Slide in from trailing
    static var slideInTrailing: AnyTransition {
        if UIAccessibility.isReduceMotionEnabled {
            return .opacity
        }
        return .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
    
    /// Scale and fade (for cards appearing)
    static var scaleAndFade: AnyTransition {
        if UIAccessibility.isReduceMotionEnabled {
            return .opacity
        }
        return .scale(scale: 0.95).combined(with: .opacity)
    }
}

/// Button style with press animation
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(AnimationManager.quickResponse, value: configuration.isPressed)
    }
}

/// View extension for animation utilities
extension View {
    /// Apply pressable scale effect
    func pressableScale() -> some View {
        self.buttonStyle(PressableButtonStyle())
    }
    
    /// Fade in when appearing
    func fadeInOnAppear(delay: Double = 0) -> some View {
        self.modifier(FadeInModifier(delay: delay))
    }
    
    /// Pulse animation (gentle, for new content)
    func gentlePulse(trigger: some Equatable) -> some View {
        if UIAccessibility.isReduceMotionEnabled {
            return AnyView(self)
        }
        
        return AnyView(
            self.modifier(PulseModifier(trigger: trigger))
        )
    }
}

/// Fade in modifier
private struct FadeInModifier: ViewModifier {
    let delay: Double
    @State private var opacity: Double = 0
    
    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                withAnimation(AnimationManager.smooth.delay(delay)) {
                    opacity = 1
                }
            }
    }
}

/// Pulse modifier
private struct PulseModifier: ViewModifier {
    let trigger: AnyHashable
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .onChange(of: trigger) { _, _ in
                withAnimation(AnimationManager.gentleSpring) {
                    isPulsing = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(AnimationManager.gentleSpring) {
                        isPulsing = false
                    }
                }
            }
    }
}

#Preview {
    struct PreviewContainer: View {
        @State private var counter = 0
        
        var body: some View {
            VStack(spacing: .spacingLG) {
                Text("Animation Examples")
                    .font(.title)
                
                Button("Press Me") {
                    counter += 1
                }
                .buttonStyle(PressableButtonStyle())
                .padding()
                .background(Color.primary)
                .foregroundColor(.white)
                .cornerRadius(.radiusMD)
                
                Text("Counter: \(counter)")
                    .gentlePulse(trigger: counter)
                    .padding()
                    .background(Color.surface)
                    .cornerRadius(.radiusSM)
            }
            .padding()
        }
    }
    
    return PreviewContainer()
}




