import SwiftUI

struct QuickActionButton: View {
    @EnvironmentObject var environment: AppEnvironment
    
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    var isActive: Bool = false
    var longPressAction: (() -> Void)?
    
    init(title: String, icon: String, color: Color, isActive: Bool = false, action: @escaping () -> Void, longPressAction: (() -> Void)? = nil) {
        self.title = title
        self.icon = icon
        self.color = color
        self.isActive = isActive
        self.action = action
        self.longPressAction = longPressAction
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
        Button(action: {
            print("🔵 QuickActionButton tapped: \(title)")
            Haptics.light()
            action()
            print("🔵 QuickActionButton action called: \(title)")
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
            }
            .frame(maxWidth: .infinity)
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
            .cornerRadius(.radiusMD)
            .shadow(color: isActive ? color.opacity(0.2) : Color.black.opacity(0.05), radius: isActive ? 6 : 2, x: 0, y: isActive ? 3 : 1)
            .overlay(
                RoundedRectangle(cornerRadius: .radiusMD)
                    .stroke(isActive ? color.opacity(0.3) : Color.separator, lineWidth: isActive ? 1.5 : 0.5)
            )
        }
        .contentShape(Rectangle()) // Ensure entire button area is tappable
        .buttonStyle(QuickActionButtonStyle(isActive: isActive))
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    print("🔵 QuickActionButton long press: \(title)")
                    if let longPressAction = longPressAction {
                        Haptics.medium()
                        longPressAction()
                    }
                }
        )
        .motionAnimation(.easeInOut(duration: 0.2), value: isActive)
        .accessibilityLabel("\(title) quick action")
        .accessibilityHint(isActive ? "Active. Double tap to stop, long press for detailed form" : "Double tap to log \(title.lowercased()), long press for detailed form")
    }
}

struct QuickActionButtonStyle: ButtonStyle {
    let isActive: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !MotionModifiers.reduceMotion ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    HStack(spacing: 8) {
        QuickActionButton(title: "Feed", icon: "drop.fill", color: .eventFeed) {}
        QuickActionButton(title: "Sleep", icon: "moon.fill", color: .eventSleep, isActive: true) {}
        QuickActionButton(title: "Diaper", icon: "drop.circle.fill", color: .eventDiaper) {}
    }
    .padding()
}

