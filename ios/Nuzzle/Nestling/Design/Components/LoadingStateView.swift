import SwiftUI

struct LoadingStateView: View {
    let message: String?
    let useSkeleton: Bool
    
    init(message: String? = nil, useSkeleton: Bool = false) {
        self.message = message
        self.useSkeleton = useSkeleton
    }
    
    var body: some View {
        if useSkeleton {
            // Show skeleton loaders instead of spinner
            VStack(spacing: .spacingMD) {
                if let message = message {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.mutedForeground)
                        .padding(.bottom, .spacingSM)
                }
                SkeletonTimelineView(count: 3)
            }
            .frame(maxWidth: .infinity)
            .accessibilityLabel(message ?? "Loading")
        } else {
            // Traditional spinner
            VStack(spacing: .spacingMD) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.primary)
                
                if let message = message {
                    Text(message)
                        .font(.body)
                        .foregroundColor(.mutedForeground)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityLabel(message ?? "Loading")
        }
    }
}

#Preview {
    LoadingStateView(message: "Loading events...")
}

