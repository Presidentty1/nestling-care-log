import SwiftUI

/// Skeleton loading view for better perceived performance
struct SkeletonView: View {
    @State private var isAnimating = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: .radiusMD)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.mutedForeground.opacity(0.2),
                        Color.mutedForeground.opacity(0.1),
                        Color.mutedForeground.opacity(0.2)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}

/// Skeleton card for timeline rows
struct SkeletonCard: View {
    var body: some View {
        HStack(spacing: .spacingMD) {
            // Icon placeholder
            Circle()
                .fill(Color.mutedForeground.opacity(0.2))
                .frame(width: 36, height: 36)
            
            // Content placeholder
            VStack(alignment: .leading, spacing: 8) {
                SkeletonView()
                    .frame(height: 16)
                    .frame(width: 120)
                
                SkeletonView()
                    .frame(height: 12)
                    .frame(width: 80)
            }
            
            Spacer()
            
            // Time placeholder
            SkeletonView()
                .frame(width: 50, height: 12)
        }
        .padding(.spacingMD)
        .background(Color.surface)
        .cornerRadius(.radiusMD)
    }
}

/// Skeleton view for summary cards
struct SkeletonSummaryCard: View {
    var body: some View {
        VStack(spacing: .spacingSM) {
            Circle()
                .fill(Color.mutedForeground.opacity(0.2))
                .frame(width: 48, height: 48)
            
            SkeletonView()
                .frame(width: 40, height: 20)
            
            SkeletonView()
                .frame(width: 60, height: 12)
        }
        .frame(maxWidth: .infinity)
        .padding(.spacingMD)
        .background(Color.surface)
        .cornerRadius(.radiusMD)
    }
}

/// Skeleton loading state for timeline
struct SkeletonTimelineView: View {
    let count: Int
    
    init(count: Int = 3) {
        self.count = count
    }
    
    var body: some View {
        VStack(spacing: .spacingSM) {
            ForEach(0..<count, id: \.self) { _ in
                SkeletonCard()
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        SkeletonSummaryCard()
        SkeletonCard()
        SkeletonTimelineView(count: 3)
    }
    .padding()
    .background(Color.background)
}

