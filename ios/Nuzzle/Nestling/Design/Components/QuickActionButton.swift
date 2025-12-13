import SwiftUI
import UIKit

struct QuickActionButton: View {
    @EnvironmentObject var environment: AppEnvironment

    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    var isActive: Bool = false
    var longPressAction: (() -> Void)?
    var timeSinceLast: String?  // e.g., "2h ago"

    @State private var showSuccessFeedback = false
    @State private var rippleScale = 0.0

    init(title: String, icon: String, color: Color, isActive: Bool = false, action: @escaping () -> Void, longPressAction: (() -> Void)? = nil, timeSinceLast: String? = nil) {
        self.title = title
        self.icon = icon
        self.color = color
        self.isActive = isActive
        self.action = action
        self.longPressAction = longPressAction
        self.timeSinceLast = timeSinceLast
    }
    
    private var isCaregiverMode: Bool {
        environment.isCaregiverMode
    }
    
    private var buttonSize: CGFloat {
        isCaregiverMode ? .caregiverMinTouchTarget : 44
    }
    
    private var buttonFont: Font {
        isCaregiverMode ? .caregiverBody : .caption
    }
    
    var body: some View {
        ZStack {
            // Voice button overlay (when voice-first mode is enabled)
            if PolishFeatureFlags.shared.voiceFirstEnabled {
                GeometryReader { geometry in
                    Button(action: {
                        // Trigger voice command for this action
                        triggerVoiceCommand()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.primary.opacity(0.9))
                                .frame(width: 32, height: 32)

                            Image(systemName: "mic.fill")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 32, height: 32)
                    .position(x: geometry.size.width - 16, y: 16)
                    .accessibilityLabel("Voice command for \(title)")
                    .accessibilityHint("Tap to use voice instead of touch")
                }
            }

            Button(action: {
                logger.debug("🔵 QuickActionButton tapped: \(title)")
                Haptics.light()
                action()
                showSuccessFeedback()
                logger.debug("🔵 QuickActionButton action called: \(title)")
            }) {
            VStack(spacing: isCaregiverMode ? .spacingSM : .spacingXS) {
                ZStack {
                    Circle()
                        .fill(isActive ? color.opacity(0.2) : Color.clear)
                        .frame(width: buttonSize, height: buttonSize)
                    
                    Image(systemName: icon)
                        .font(isCaregiverMode ? .title2 : .title3)
                        .foregroundColor(isActive ? color : color)
                        .symbolBounce(value: isActive)
                }
                
                Text(title)
                    .font(buttonFont)
                    .foregroundColor(.foreground)
                    .lineLimit(1)

                // Add time since last badge
                if let timeSince = timeSinceLast {
                    Text(timeSince)
                        .font(.caption2)
                        .foregroundColor(.mutedForeground)
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: isCaregiverMode ? 120 : 100)
            .padding(isCaregiverMode ? .spacingLG : .spacingMD)
            .background(
                Group {
                    if isActive {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                color.opacity(0.15),
                                color.opacity(0.08)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.surface,
                                Color.surface.opacity(0.95)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                }
            )
            .cornerRadius(.radiusLG)
            .shadow(color: isActive ? color.opacity(0.25) : Color.black.opacity(0.05), radius: isActive ? 8 : 3, x: 0, y: isActive ? 4 : 2)
            .overlay(
                RoundedRectangle(cornerRadius: .radiusLG)
                    .stroke(isActive ? color.opacity(0.4) : Color.cardBorder, lineWidth: isActive ? 2 : 1)
            )
            }
            .contentShape(Rectangle()) // Ensure entire button area is tappable
            .buttonStyle(QuickActionButtonStyle(isActive: isActive))
            .simultaneousGesture(
                // Double-tap for enhanced haptic feedback only (action already called by button tap)
                TapGesture(count: 2)
                    .onEnded { _ in
                        logger.debug("🔵 QuickActionButton double-tap detected: \(title)")
                        Haptics.medium() // Enhanced feedback for double-tap
                    }
            )
            .simultaneousGesture(
                // Long press for detailed form
                LongPressGesture(minimumDuration: 0.5)
                    .onEnded { _ in
                        logger.debug("🔵 QuickActionButton long press: \(title)")
                        if let longPressAction = longPressAction {
                            Haptics.medium()
                            longPressAction()
                        }
                    }
            )
            .motionAnimation(.easeInOut(duration: 0.2), value: isActive)
            .accessibilityLabel("\(title) quick action")
            .accessibilityHint(isActive ? "Active. Double tap to stop, long press for detailed form" : "Double tap to log \(title.lowercased()), long press for detailed form")

            // Success feedback overlay
            if showSuccessFeedback {
                successFeedbackOverlay
            }
        }
    }

    private var successFeedbackOverlay: some View {
        ZStack {
            // Ripple effect
            Circle()
                .fill(color.opacity(0.3))
                .scaleEffect(rippleScale)
                .opacity(1 - rippleScale)

            // Checkmark overlay
            Image(systemName: "checkmark")
                .font(.title)
                .foregroundColor(.white)
                .background(
                    Circle()
                        .fill(color)
                        .frame(width: 40, height: 40)
                )
        }
        .allowsHitTesting(false) // Don't block interaction
    }

    private func showSuccessFeedback() {
        withAnimation(AnimationManager.celebration) {
            showSuccessFeedback = true
            rippleScale = 1.0
        }

        // Announce success to VoiceOver
        UIAccessibility.post(notification: .announcement, argument: "\(title) logged successfully")

        // Hide after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation {
                showSuccessFeedback = false
                rippleScale = 0.0
            }
        }
    }

    private func triggerVoiceCommand() {
        // Show voice command hint
        // In a real implementation, this would activate Siri or voice input
        // For now, just provide haptic feedback and show a hint

        Haptics.selection()

        // Analytics
        AnalyticsService.shared.track(event: "voice_button_tapped", properties: [
            "action_type": title.lowercased(),
            "voice_first_mode": true
        ])

        // TODO: Implement actual voice command activation
        // This could integrate with Siri or a custom voice interface
        // For example: activate Siri with specific phrase, or show voice input modal
    }
}

struct QuickActionButtonStyle: ButtonStyle {
    let isActive: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !MotionModifiers.reduceMotion ? 0.92 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    HStack(spacing: 8) {
        QuickActionButton(title: "Feed", icon: "drop.fill", color: .eventFeed, isActive: false, action: {}, longPressAction: nil, timeSinceLast: "2h ago")
        QuickActionButton(title: "Sleep", icon: "moon.fill", color: .eventSleep, isActive: true, action: {}, longPressAction: nil, timeSinceLast: nil)
        QuickActionButton(title: "Diaper", icon: "drop.circle.fill", color: .eventDiaper, isActive: false, action: {}, longPressAction: nil, timeSinceLast: "30m ago")
    }
    .padding()
}

