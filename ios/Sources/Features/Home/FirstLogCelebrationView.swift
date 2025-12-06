import SwiftUI

/// Celebration modal shown after user logs their first event
/// Part of Phase 2: Personalization & Engagement
struct FirstLogCelebrationView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var confettiOpacity: Double = 0
    let eventType: EventType
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onContinue()
                }
            
            VStack(spacing: .spacingXL) {
                // Animated confetti/celebration icon
                ZStack {
                    // Confetti burst
                    ForEach(0..<12) { index in
                        ConfettiPiece(index: index)
                            .opacity(confettiOpacity)
                    }
                    
                    // Main icon
                    Image(systemName: eventType.iconName)
                        .font(.system(size: 80))
                        .foregroundColor(eventType.color)
                        .scaleEffect(scale)
                        .opacity(opacity)
                }
                .frame(height: 150)
                
                VStack(spacing: .spacingMD) {
                    Text("🎉 Great job!")
                        .font(.title.bold())
                        .foregroundColor(Color.adaptiveForeground(colorScheme))
                    
                    Text("You just logged your first \(eventType.displayName.lowercased()). That was easy, right?")
                        .font(.body)
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, .spacingMD)
                    
                    Text("Keep logging to unlock AI predictions and insights")
                        .font(.caption)
                        .foregroundColor(Color.adaptiveTextTertiary(colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, .spacingMD)
                }
                
                // Continue button
                Button(action: onContinue) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(Color.adaptivePrimaryForeground(colorScheme))
                        .frame(maxWidth: .infinity)
                        .padding(.spacingMD)
                        .background(Color.adaptivePrimary(colorScheme))
                        .cornerRadius(.radiusMD)
                }
                .padding(.horizontal, .spacingXL)
            }
            .padding(.spacingXL)
            .background(
                RoundedRectangle(cornerRadius: .radiusLG)
                    .fill(Color.adaptiveSurface(colorScheme))
            )
            .padding(.spacingXL)
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            // Animate entrance
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
            
            // Animate confetti slightly delayed
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                confettiOpacity = 1.0
            }
            
            // Haptic feedback
            Haptics.success()
        }
    }
}

/// Individual confetti piece for celebration animation
struct ConfettiPiece: View {
    let index: Int
    @State private var yOffset: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1
    
    private let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange]
    
    var body: some View {
        Circle()
            .fill(colors[index % colors.count])
            .frame(width: 8, height: 8)
            .offset(
                x: CGFloat(cos(Double(index) * .pi / 6)) * 80,
                y: yOffset
            )
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .onAppear {
                // Animate confetti falling
                withAnimation(.easeOut(duration: 1.5).delay(Double(index) * 0.05)) {
                    yOffset = 100
                    rotation = Double.random(in: 0...360)
                    opacity = 0
                }
            }
    }
}

#Preview {
    FirstLogCelebrationView(eventType: .feed) {
        print("Continue tapped")
    }
}

