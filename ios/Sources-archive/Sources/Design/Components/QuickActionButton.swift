import SwiftUI

struct QuickActionButton: View {
    @EnvironmentObject var environment: AppEnvironment
    
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    var isActive: Bool = false
    var isEmphasized: Bool = false // Epic 3 AC2: Visual emphasis for context-aware actions
    var longPressAction: (() -> Void)?
    
    init(
        title: String,
        icon: String,
        color: Color,
        isActive: Bool = false,
        isEmphasized: Bool = false,
        action: @escaping () -> Void,
        longPressAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.icon = icon
        self.color = color
        self.isActive = isActive
        self.isEmphasized = isEmphasized
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
            Haptics.light()
            action()
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
            .background(isEmphasized ? NuzzleTheme.primary.opacity(0.1) : NuzzleTheme.surface)
            .cornerRadius(.radiusMD)
            .overlay(
                RoundedRectangle(cornerRadius: .radiusMD)
                    .stroke(isEmphasized ? NuzzleTheme.primary : Color.clear, lineWidth: isEmphasized ? 2 : 0)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .gentlePress()
        .motionAnimation(.easeInOut(duration: 0.2), value: isActive)
        .onLongPressGesture(minimumDuration: 0.5) {
            if let longPressAction = longPressAction {
                Haptics.medium()
                longPressAction()
            }
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(isActive ? "Active. Double tap to stop, long press for detailed form" : "Double tap to log \(title.lowercased()), long press for detailed form")
    }
    
    private var accessibilityLabel: String {
        switch title.lowercased() {
        case "feed": return "Log a feed"
        case "sleep": return "Log sleep"
        case "diaper": return "Log a diaper"
        case "tummy": return "Log tummy time"
        default: return "\(title) quick action"
        }
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

