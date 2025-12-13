import SwiftUI

// Import for feature flags and sharing
private let featureFlags = PolishFeatureFlags.shared

/// Celebration view for special moments (first log, streaks, milestones)
struct CelebrationView: View {
    let type: CelebrationType
    let onDismiss: () -> Void
    let babyName: String? = nil // For share functionality
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    @State private var showConfetti = false
    @State private var showShareSheet = false
    
    enum CelebrationType {
        case firstLog
        case streakAchieved(days: Int)
        case milestoneUnlocked(name: String)
        
        var icon: String {
            switch self {
            case .firstLog: return "checkmark.circle.fill"
            case .streakAchieved: return "flame.fill"
            case .milestoneUnlocked: return "star.fill"
            }
        }
        
        var title: String {
            switch self {
            case .firstLog: return "You did it!"
            case .streakAchieved(let days): return "\(days) Day Streak!"
            case .milestoneUnlocked(let name): return name
            }
        }
        
        var message: String {
            switch self {
            case .firstLog: return "Your first log is complete. Keep tracking to unlock patterns and predictions."
            case .streakAchieved: return "You're building a great tracking habit!"
            case .milestoneUnlocked: return "Milestone unlocked!"
            }
        }
        
        var color: Color {
            switch self {
            case .firstLog: return .success
            case .streakAchieved: return .warning
            case .milestoneUnlocked: return .primary
            }
        }
    }

    private var shouldShowShareButton: Bool {
        guard featureFlags.shareCardsEnabled else { return false }

        // Only show share for significant milestones
        switch type {
        case .streakAchieved, .milestoneUnlocked:
            return true
        default:
            return false
        }
    }

    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            // Celebration card
            VStack(spacing: .spacingXL) {
                // Icon with glow
                ZStack {
                    Circle()
                        .fill(type.color.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .blur(radius: 20)
                    
                    Circle()
                        .fill(type.color.opacity(0.15))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: type.icon)
                        .font(.system(size: 50))
                        .foregroundColor(type.color)
                }
                .scaleEffect(scale)
                
                VStack(spacing: .spacingMD) {
                    Text(type.title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.foreground)
                    
                    Text(type.message)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.mutedForeground)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Action buttons
                if shouldShowShareButton {
                    HStack(spacing: .spacingMD) {
                        // Share button
                        Button(action: shareMilestone) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share")
                            }
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(type.color)
                            .frame(height: 56)
                            .padding(.horizontal, .spacingLG)
                            .background(Color.surface)
                            .cornerRadius(.radiusXL)
                            .overlay(
                                RoundedRectangle(cornerRadius: .radiusXL)
                                    .stroke(type.color, lineWidth: 2)
                            )
                        }

                        // Continue button
                        Button(action: dismiss) {
                            Text("Continue")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(type.color)
                                .cornerRadius(.radiusXL)
                        }
                    }
                } else {
                    Button(action: dismiss) {
                        Text("Continue")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(type.color)
                            .cornerRadius(.radiusXL)
                    }
                }
            }
            .padding(.spacingXL)
            .background(Color.elevated)
            .cornerRadius(.radiusXL)
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
            .padding(.horizontal, .spacingXL)
            .opacity(opacity)
            
            // Confetti effect (optional)
            if showConfetti {
                ConfettiView()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
            
            // Show confetti after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    showConfetti = true
                }
            }
            
            // Haptic feedback
            Haptics.success()
        }
    }
    .sheet(isPresented: $showShareSheet) {
        MilestoneShareSheet(
            milestone: convertToShareableMilestone() ?? .streakAchieved(days: 1),
            babyName: babyName ?? "",
            onDismiss: { showShareSheet = false }
        )
    }

    private func shareMilestone() {
        showShareSheet = true
    }

    private func convertToShareableMilestone() -> ShareableMilestoneCard.ShareableMilestone? {
        switch type {
        case .streakAchieved(let days):
            return .streakAchieved(days: days)
        case .milestoneUnlocked:
            return .patternDiscovered // Generic milestone
        default:
            return nil
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            opacity = 0
            scale = 0.9
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}

/// Simple confetti animation
struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    
    struct ConfettiPiece: Identifiable {
        let id: UUID
        let x: CGFloat
        let y: CGFloat
        let color: Color
        let rotation: Double
        let size: CGFloat
        
        init(id: UUID = UUID(), x: CGFloat, y: CGFloat, color: Color, rotation: Double, size: CGFloat) {
            self.id = id
            self.x = x
            self.y = y
            self.color = color
            self.rotation = rotation
            self.size = size
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiPieces) { piece in
                    Circle()
                        .fill(piece.color)
                        .frame(width: piece.size, height: piece.size)
                        .position(x: piece.x, y: piece.y)
                        .rotationEffect(.degrees(piece.rotation))
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            generateConfetti()
        }
    }
    
    private func generateConfetti() {
        let colors: [Color] = [.primary, .eventFeed, .eventSleep, .eventDiaper, .eventTummy, .success]
        let screenWidth = UIScreen.main.bounds.width
        
        for i in 0..<30 {
            let piece = ConfettiPiece(
                x: CGFloat.random(in: 0...screenWidth),
                y: -50,
                color: colors.randomElement() ?? .primary,
                rotation: Double.random(in: 0...360),
                size: CGFloat.random(in: 6...12)
            )
            confettiPieces.append(piece)
            
            // Animate falling
            withAnimation(.easeIn(duration: Double.random(in: 1.5...2.5)).delay(Double(i) * 0.02)) {
                if let index = confettiPieces.firstIndex(where: { $0.id == piece.id }) {
                    confettiPieces[index] = ConfettiPiece(
                        id: piece.id,
                        x: piece.x + CGFloat.random(in: -50...50),
                        y: UIScreen.main.bounds.height + 50,
                        color: piece.color,
                        rotation: piece.rotation + Double.random(in: 360...720),
                        size: piece.size
                    )
                }
            }
        }
    }
}

#Preview {
    CelebrationView(type: .firstLog) {
        print("Dismissed")
    }
}

