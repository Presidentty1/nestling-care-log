import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: .spacingMD) {
            ZStack {
                // Gradient background circle
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.eventFeed.opacity(0.1),
                                Color.eventSleep.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .blur(radius: 20)
                
                Image(systemName: icon)
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.eventFeed,
                                Color.eventSleep
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.bounce, value: isAnimating)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
            
            Text(title)
                .font(.headline)
                .foregroundColor(.foreground)
            
            Text(message)
                .font(.body)
                .foregroundColor(.mutedForeground)
                .multilineTextAlignment(.center)
                .padding(.horizontal, .spacingMD)
            
            if let actionTitle = actionTitle, let action = action {
                PrimaryButton(actionTitle, action: action)
                    .padding(.horizontal, .spacingMD)
                    .padding(.top, .spacingSM)
            }
        }
        .padding(.spacing2XL)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
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

