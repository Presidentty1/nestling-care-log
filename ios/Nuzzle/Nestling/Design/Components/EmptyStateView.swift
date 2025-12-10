import SwiftUI

struct EmptyStateView: View {
    enum Variant {
        case welcome
        case activity
        case search
        case history
    }
    
    let icon: String
    let title: String
    let message: String
    let variant: Variant
    let actionTitle: String?
    let action: (() -> Void)?
    let secondaryActionTitle: String?
    let secondaryAction: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        variant: Variant = .activity,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil,
        secondaryActionTitle: String? = nil,
        secondaryAction: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.variant = variant
        self.actionTitle = actionTitle
        self.action = action
        self.secondaryActionTitle = secondaryActionTitle
        self.secondaryAction = secondaryAction
    }
    
    @State private var isAnimating = false
    
    private var gradientColors: [Color] {
        switch variant {
        case .welcome: return [Color.eventFeed.opacity(0.16), Color.eventSleep.opacity(0.16)]
        case .activity: return [Color.primary.opacity(0.14), Color.eventTummy.opacity(0.1)]
        case .search: return [Color.primary.opacity(0.12), Color.surface.opacity(0.08)]
        case .history: return [Color.eventSleep.opacity(0.12), Color.eventDiaper.opacity(0.1)]
        }
    }
    
    var body: some View {
        VStack(spacing: .spacingMD) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: gradientColors),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 110, height: 110)
                    .blur(radius: 22)
                
                Image(systemName: icon)
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.primary,
                                Color.eventSleep
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.bounce, value: isAnimating)
                    .accessibilityHidden(true)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
            
            VStack(spacing: .spacingXS) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.foreground)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.mutedForeground)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, .spacingLG)
            }
            
            if let actionTitle = actionTitle, let action = action {
                PrimaryButton(actionTitle, action: action)
                    .padding(.horizontal, .spacingMD)
                    .padding(.top, .spacingSM)
            }
            
            if let secondaryActionTitle = secondaryActionTitle, let secondaryAction = secondaryAction {
                SecondaryButton(secondaryActionTitle, action: secondaryAction)
                    .padding(.horizontal, .spacingMD)
            }
        }
        .padding(.spacing2XL)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
        .accessibilityHint(actionTitle ?? "Add an entry to get started")
    }
}

#Preview {
    EmptyStateView(
        icon: "calendar",
        title: "No events logged",
        message: "Start logging events to see them here",
        actionTitle: "Log Event",
        action: {}
    )
}

