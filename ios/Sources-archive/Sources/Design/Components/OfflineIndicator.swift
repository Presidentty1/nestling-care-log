import SwiftUI

/// Displays offline status and pending operation count
struct OfflineIndicator: View {
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var queueService = OfflineQueueService.shared

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if !networkMonitor.isConnected {
            HStack(spacing: .spacingSM) {
                Image(systemName: "wifi.slash")
                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                    .font(.system(size: 12))

                Text("Offline")
                    .font(.caption)
                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme))

                if queueService.pendingCount > 0 {
                    Text("• \(queueService.pendingCount) pending")
                        .font(.caption)
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                }
            }
            .padding(.horizontal, .spacingSM)
            .padding(.vertical, .spacingXS)
            .background(Color.adaptiveSurface(colorScheme).opacity(0.8))
            .cornerRadius(.radiusSM)
            .accessibilityLabel("Device is offline with \(queueService.pendingCount) pending operations")
        } else if queueService.isSyncing {
            HStack(spacing: .spacingSM) {
                ProgressView()
                    .scaleEffect(0.7)
                    .tint(Color.adaptivePrimary(colorScheme))

                Text("Syncing...")
                    .font(.caption)
                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
            }
            .padding(.horizontal, .spacingSM)
            .padding(.vertical, .spacingXS)
            .background(Color.adaptiveSurface(colorScheme).opacity(0.8))
            .cornerRadius(.radiusSM)
            .accessibilityLabel("Syncing offline operations")
        } else {
            EmptyView()
        }
    }
}

struct OfflineIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            OfflineIndicator()
                .padding()
        }
        .previewLayout(.sizeThatFits)
    }
}


