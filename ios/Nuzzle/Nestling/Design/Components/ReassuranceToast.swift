import SwiftUI

/// Toast view for displaying reassurance messages
/// Shows warm, supportive messages to reduce anxiety
///
/// Usage:
/// ```swift
/// .toast(isPresented: $showReassurance) {
///     ReassuranceToast(message: reassuranceMessage)
/// }
/// ```
struct ReassuranceToast: View {
    let message: ReassuranceMessage
    let onAction: (() -> Void)?
    let onDismiss: (() -> Void)?
    
    init(
        message: ReassuranceMessage,
        onAction: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.message = message
        self.onAction = onAction
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with title and dismiss button
            HStack {
                Text(message.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let onDismiss = onDismiss {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .imageScale(.medium)
                    }
                }
            }
            
            // Body text
            Text(message.body)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Action button (if provided)
            if let actionLabel = message.actionLabel, let onAction = onAction {
                Button(action: onAction) {
                    HStack {
                        Text(actionLabel)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Image(systemName: "arrow.right")
                            .imageScale(.small)
                    }
                }
                .foregroundColor(.accentColor)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
    }
}

/// Toast modifier for showing reassurance messages
struct ReassuranceToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: ReassuranceMessage?
    let duration: TimeInterval
    let onAction: (() -> Void)?
    
    @State private var workItem: DispatchWorkItem?
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if isPresented, let message = message {
                    ReassuranceToast(
                        message: message,
                        onAction: onAction,
                        onDismiss: {
                            withAnimation {
                                isPresented = false
                            }
                            workItem?.cancel()
                        }
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        // Auto-dismiss after duration
                        let task = DispatchWorkItem {
                            withAnimation {
                                isPresented = false
                            }
                        }
                        workItem = task
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: task)
                    }
                    .padding(.top, 8)
                }
            }
    }
}

extension View {
    /// Show a reassurance toast message
    ///
    /// - Parameters:
    ///   - isPresented: Binding to control visibility
    ///   - message: The reassurance message to display
    ///   - duration: How long to show the toast (default: 5 seconds)
    ///   - onAction: Callback when action button is tapped
    func reassuranceToast(
        isPresented: Binding<Bool>,
        message: ReassuranceMessage?,
        duration: TimeInterval = 5.0,
        onAction: (() -> Void)? = nil
    ) -> some View {
        self.modifier(
            ReassuranceToastModifier(
                isPresented: isPresented,
                message: message,
                duration: duration,
                onAction: onAction
            )
        )
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(uiColor: .systemGroupedBackground))
    .reassuranceToast(
        isPresented: .constant(true),
        message: ReassuranceMessage(
            title: "Schedules take time 💙",
            body: "Most babies don't have predictable patterns until 3-4 months. You're doing great!",
            actionLabel: "Learn more",
            actionLink: "help://patterns"
        ),
        onAction: {
            print("Action tapped")
        }
    )
}
