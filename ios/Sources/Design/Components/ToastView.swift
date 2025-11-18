import SwiftUI

enum ToastType {
    case success
    case error
    case info
}

struct ToastView: View {
    let message: String
    let type: ToastType
    
    var body: some View {
        HStack(spacing: .spacingSM) {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
            
            Text(message)
                .font(.body)
                .foregroundColor(.foreground)
        }
        .padding(.spacingMD)
        .background(Color.surface)
        .cornerRadius(.radiusMD)
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        .padding(.horizontal, .spacingMD)
        .accessibilityLabel("\(type == .success ? "Success" : type == .error ? "Error" : "Information"): \(message)")
    }
    
    private var iconName: String {
        switch type {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    private var iconColor: Color {
        switch type {
        case .success: return .success
        case .error: return .destructive
        case .info: return .info
        }
    }
}

struct ToastModifier: ViewModifier {
    @Binding var toast: ToastMessage?
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if let toast = toast {
                        VStack {
                            Spacer()
                            ToastView(message: toast.message, type: toast.type, undoAction: toast.undoAction)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        .animation(.spring(response: 0.3), value: toast)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(toast.type == .success ? "Success" : toast.type == .error ? "Error" : "Information"): \(toast.message)")
                        .accessibilityAddTraits(.isModal)
                        .onAppear {
                            // Announce to VoiceOver when toast appears
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                UIAccessibility.post(notification: .announcement, argument: "\(toast.type == .success ? "Success" : toast.type == .error ? "Error" : "Information"): \(toast.message)")
                            }
                        }
                    }
                },
                alignment: .bottom
            )
    }
}

struct ToastMessage: Identifiable {
    let id = UUID()
    let message: String
    let type: ToastType
    var undoAction: (() -> Void)? = nil
}

extension View {
    func toast(_ toast: Binding<ToastMessage?>) -> some View {
        modifier(ToastModifier(toast: $toast))
    }
}

#Preview {
    VStack(spacing: 16) {
        ToastView(message: "Event saved successfully", type: .success)
        ToastView(message: "Failed to save event", type: .error)
        ToastView(message: "Information message", type: .info)
    }
    .padding()
}

