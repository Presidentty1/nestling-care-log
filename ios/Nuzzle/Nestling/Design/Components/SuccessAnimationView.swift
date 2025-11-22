import SwiftUI

/// Success animation overlay for confirming actions
struct SuccessAnimationView: View {
    @Binding var isVisible: Bool
    let message: String
    
    var body: some View {
        if isVisible {
            ZStack {
                // Background blur
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                
                VStack(spacing: .spacingMD) {
                    ZStack {
                        Circle()
                            .fill(Color.success)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(isVisible ? 1.0 : 0.5)
                    .opacity(isVisible ? 1.0 : 0.0)
                    
                    Text(message)
                        .font(.headline)
                        .foregroundColor(.foreground)
                        .multilineTextAlignment(.center)
                }
                .padding(.spacingXL)
                .background(
                    RoundedRectangle(cornerRadius: .radiusLG)
                        .fill(Color.surface)
                        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                )
                .padding(.spacingXL)
            }
            .transition(.opacity.combined(with: .scale))
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isVisible)
            .onAppear {
                Haptics.success()
                
                // Auto-dismiss after 1.5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        isVisible = false
                    }
                }
            }
        }
    }
}

/// View modifier for showing success animations
struct SuccessAnimationModifier: ViewModifier {
    @Binding var showSuccess: Bool
    let message: String
    
    func body(content: Content) -> some View {
        content
            .overlay {
                SuccessAnimationView(isVisible: $showSuccess, message: message)
            }
    }
}

extension View {
    /// Show a success animation overlay
    func successAnimation(isVisible: Binding<Bool>, message: String) -> some View {
        modifier(SuccessAnimationModifier(showSuccess: isVisible, message: message))
    }
}

#Preview {
    @Previewable @State var showSuccess = true
    
    return ZStack {
        Color.background
        Text("Content")
    }
    .successAnimation(isVisible: $showSuccess, message: "Event logged!")
}

