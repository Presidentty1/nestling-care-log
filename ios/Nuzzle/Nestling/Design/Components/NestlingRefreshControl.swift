import SwiftUI

/// Custom refresh control with animated nestling icon
/// Provides visual feedback during pull-to-refresh operations
struct NestlingRefreshControl: View {
    let isRefreshing: Bool
    let progress: CGFloat // 0.0 to 1.0

    var body: some View {
        ZStack {
            // Background circle that fills as user pulls
            Circle()
                .stroke(Color.accentColor.opacity(0.2), lineWidth: 3)
                .frame(width: 40, height: 40)

            // Progress fill
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(Color.accentColor, lineWidth: 3)
                .frame(width: 40, height: 40)
                .rotationEffect(.degrees(-90)) // Start from top

            // Nestling icon that animates when refreshing
            Image(systemName: "bird.fill")
                .font(.system(size: 16))
                .foregroundColor(.accentColor)
                .scaleEffect(isRefreshing ? 1.2 : 1.0)
                .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                .animation(isRefreshing ? .linear(duration: 1.0).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                .opacity(progress > 0.1 ? 1.0 : 0.0) // Only show when pulled enough
        }
        .frame(width: 60, height: 60)
        .contentShape(Rectangle())
    }
}

// MARK: - Integration Helper

/// View modifier that adds pull-to-refresh with custom NestlingRefreshControl
struct NestlingRefreshModifier: ViewModifier {
    let isRefreshing: Bool
    let progress: CGFloat
    let onRefresh: () async -> Void

    @State private var refreshTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .refreshable {
                refreshTask?.cancel()
                refreshTask = Task {
                    await onRefresh()
                }
                await refreshTask?.value
            }
            .overlay(
                Group {
                    if isRefreshing || progress > 0 {
                        VStack {
                            NestlingRefreshControl(isRefreshing: isRefreshing, progress: progress)
                            Spacer()
                        }
                        .padding(.top, 20)
                        .allowsHitTesting(false) // Don't block content interaction
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .animation(.easeInOut, value: isRefreshing)
            )
    }
}

extension View {
    /// Add pull-to-refresh with NestlingRefreshControl
    func nestlingRefresh(
        isRefreshing: Bool,
        progress: CGFloat = 0,
        onRefresh: @escaping () async -> Void
    ) -> some View {
        modifier(NestlingRefreshModifier(
            isRefreshing: isRefreshing,
            progress: progress,
            onRefresh: onRefresh
        ))
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            Text("Pull down to refresh")
                .font(.title)

            ForEach(0..<20) { i in
                Text("Item \(i)")
                    .padding()
                    .background(Color.surface)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
    .nestlingRefresh(isRefreshing: false, progress: 0.5) {
        try? await Task.sleep(for: .seconds(2))
    }
}

