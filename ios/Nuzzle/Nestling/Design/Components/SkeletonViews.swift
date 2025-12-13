import SwiftUI

/// Skeleton loading views that match the final layout structure
/// Provides better perceived performance than generic spinners
struct SkeletonViews {
    // MARK: - Base Skeleton Component

    struct SkeletonView: View {
        let width: CGFloat?
        let height: CGFloat
        let cornerRadius: CGFloat

        init(width: CGFloat? = nil, height: CGFloat = 16, cornerRadius: CGFloat = 4) {
            self.width = width
            self.height = height
            self.cornerRadius = cornerRadius
        }

        var body: some View {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.skeletonBase)
                .frame(width: width, height: height)
                .shimmer()
                .accessibilityLabel("Loading content")
        }
    }

    // MARK: - Specific Skeleton Components

    struct CardSkeleton: View {
        let height: CGFloat

        var body: some View {
            RoundedRectangle(cornerRadius: .radiusLG)
                .fill(Color.skeletonSurface)
                .frame(height: height)
                .shimmer()
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }

    struct TextSkeleton: View {
        let width: CGFloat?
        let lines: Int

        init(width: CGFloat? = nil, lines: Int = 1) {
            self.width = width
            self.lines = lines
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(0..<lines, id: \.self) { _ in
                    SkeletonView(width: width, height: 14)
                }
            }
        }
    }

    struct AvatarSkeleton: View {
        let size: CGFloat

        var body: some View {
            Circle()
                .fill(Color.skeletonBase)
                .frame(width: size, height: size)
                .shimmer()
        }
    }

    struct ButtonSkeleton: View {
        let width: CGFloat?
        let height: CGFloat

        var body: some View {
            RoundedRectangle(cornerRadius: .radiusLG)
                .fill(Color.skeletonBase.opacity(0.5))
                .frame(width: width, height: height)
                .shimmer()
        }
    }

    // MARK: - Page-Specific Skeletons

    struct HomeSkeletonView: View {
        var body: some View {
            ScrollView {
                VStack(spacing: .spacingLG) {
                    // Header skeleton
                    HStack(spacing: .spacingMD) {
                        AvatarSkeleton(size: 44)
                        VStack(alignment: .leading, spacing: 4) {
                            SkeletonView(width: 120, height: 16)
                            SkeletonView(width: 80, height: 14)
                        }
                        Spacer()
                        SkeletonView(width: 80, height: 32, cornerRadius: 16)
                    }
                    .padding(.horizontal, .spacingLG)

                    // Hero nap card skeleton
                    CardSkeleton(height: 180)
                        .padding(.horizontal, .spacingLG)

                    // Quick actions skeleton
                    HStack(spacing: .spacingMD) {
                        ForEach(0..<4, id: \.self) { _ in
                            VStack(spacing: .spacingXS) {
                                SkeletonView(width: 60, height: 60, cornerRadius: 30)
                                SkeletonView(width: 40, height: 12)
                            }
                        }
                    }
                    .padding(.horizontal, .spacingLG)

                    // Summary tiles skeleton
                    HStack(spacing: .spacingMD) {
                        ForEach(0..<4, id: \.self) { _ in
                            CardSkeleton(height: 80)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, .spacingLG)

                    // AI tease card skeleton
                    CardSkeleton(height: 100)
                        .padding(.horizontal, .spacingLG)
                }
                .padding(.vertical, .spacingLG)
            }
            .background(Color.background)
            .accessibilityLabel("Loading dashboard")
        }
    }

    struct TimelineSkeletonView: View {
        var body: some View {
            ScrollView {
                VStack(spacing: .spacingLG) {
                    ForEach(0..<5, id: \.self) { _ in
                        HStack(alignment: .top, spacing: .spacingMD) {
                            // Time indicator
                            SkeletonView(width: 60, height: 16)

                            VStack(alignment: .leading, spacing: .spacingSM) {
                                // Event icon and title
                                HStack(spacing: .spacingSM) {
                                    SkeletonView(width: 24, height: 24, cornerRadius: 12)
                                    SkeletonView(width: 120, height: 16)
                                }

                                // Event details
                                SkeletonView(width: 200, height: 14)
                                SkeletonView(width: 150, height: 14)
                            }
                        }
                        .padding(.horizontal, .spacingLG)
                    }
                }
                .padding(.vertical, .spacingLG)
            }
            .background(Color.background)
            .accessibilityLabel("Loading timeline")
        }
    }

    struct InsightsSkeletonView: View {
        var body: some View {
            ScrollView {
                VStack(spacing: .spacingXL) {
                    // Chart skeleton
                    VStack(alignment: .leading, spacing: .spacingMD) {
                        SkeletonView(width: 150, height: 20)
                        SkeletonView(width: .infinity, height: 200, cornerRadius: 12)
                    }
                    .padding(.horizontal, .spacingLG)

                    // Insights cards
                    ForEach(0..<3, id: \.self) { _ in
                        VStack(alignment: .leading, spacing: .spacingMD) {
                            SkeletonView(width: 120, height: 16)
                            SkeletonView(width: .infinity, height: 60, cornerRadius: 8)
                        }
                        .padding(.horizontal, .spacingLG)
                    }
                }
                .padding(.vertical, .spacingLG)
            }
            .background(Color.background)
            .accessibilityLabel("Loading insights")
        }
    }

    struct SettingsSkeletonView: View {
        var body: some View {
            List {
                ForEach(0..<6, id: \.self) { _ in
                    HStack(spacing: .spacingMD) {
                        SkeletonView(width: 24, height: 24, cornerRadius: 6)
                        SkeletonView(width: 150, height: 16)
                        Spacer()
                        SkeletonView(width: 40, height: 20, cornerRadius: 10)
                    }
                    .padding(.vertical, 8)
                }
            }
            .accessibilityLabel("Loading settings")
        }
    }
}

// MARK: - Shimmer Effect Extension

extension View {
    /// Applies a shimmer loading effect
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.skeletonBase.opacity(0),
                            Color.skeletonHighlight.opacity(0.6),
                            Color.skeletonBase.opacity(0)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                    .animation(
                        Animation.linear(duration: 1.5)
                            .repeatForever(autoreverses: false)
                            .delay(.random(in: 0...0.5)),
                        value: phase
                    )
                }
            )
            .onAppear {
                phase = 1
            }
            .mask(content) // Ensure shimmer doesn't extend beyond content bounds
    }
}

// MARK: - Color Extensions for Skeleton

extension Color {
    static let skeletonBase = Color(UIColor.systemGray5)
    static let skeletonHighlight = Color(UIColor.systemGray4)
    static let skeletonSurface = Color(UIColor.systemGray6.opacity(0.5))

    // Adaptive skeleton colors for dark mode
    static let adaptiveSkeletonBase = Color.adaptive(
        light: Color(UIColor.systemGray5),
        dark: Color(UIColor.systemGray4)
    )

    static let adaptiveSkeletonHighlight = Color.adaptive(
        light: Color(UIColor.systemGray4),
        dark: Color(UIColor.systemGray3)
    )

    static let adaptiveSkeletonSurface = Color.adaptive(
        light: Color(UIColor.systemGray6.opacity(0.5)),
        dark: Color(UIColor.systemGray5.opacity(0.3))
    )
}

// MARK: - Usage Examples

#Preview("Home Skeleton") {
    SkeletonViews.HomeSkeletonView()
}

#Preview("Timeline Skeleton") {
    SkeletonViews.TimelineSkeletonView()
}

#Preview("Individual Components") {
    VStack(spacing: 16) {
        SkeletonViews.SkeletonView(width: 200, height: 16)
        SkeletonViews.TextSkeleton(width: 150, lines: 2)
        SkeletonViews.AvatarSkeleton(size: 40)
        SkeletonViews.ButtonSkeleton(width: 100, height: 36)
        SkeletonViews.CardSkeleton(height: 80)
    }
    .padding()
}
