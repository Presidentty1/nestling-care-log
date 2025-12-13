import SwiftUI

struct MicroCelebrationView: View {
    @State private var showSparkles = false
    @State private var sparklePositions: [CGPoint] = []
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            // Subtle sparkle animations
            ForEach(0..<sparklePositions.count, id: \.self) { index in
                Image(systemName: "sparkle")
                    .font(.system(size: 12))
                    .foregroundColor(.primary.opacity(0.6))
                    .position(sparklePositions[index])
                    .scaleEffect(showSparkles ? 1.0 : 0.0)
                    .opacity(showSparkles ? 1.0 : 0.0)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .delay(Double(index) * 0.1)
                        .repeatCount(2, autoreverses: true),
                        value: showSparkles
                    )
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            generateSparklePositions()
            withAnimation {
                showSparkles = true
            }
            // Auto-dismiss after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                onComplete()
            }
        }
    }

    private func generateSparklePositions() {
        // Generate random positions around the screen center
        let screenSize = UIScreen.main.bounds.size
        let centerX = screenSize.width / 2
        let centerY = screenSize.height / 2

        sparklePositions = (0..<6).map { _ in
            CGPoint(
                x: centerX + CGFloat.random(in: -100...100),
                y: centerY + CGFloat.random(in: -100...100)
            )
        }
    }
}

#Preview {
    ZStack {
        Color.background
        MicroCelebrationView(onComplete: {})
    }
}
