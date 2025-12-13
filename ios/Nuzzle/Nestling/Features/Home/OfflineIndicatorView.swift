import SwiftUI

struct OfflineIndicatorView: View {
    enum Context {
        case general
        case aiFeatures
        case sharing
        case notifications
    }

    let context: Context

    @StateObject private var networkMonitor = NetworkMonitor.shared

    init(context: Context = .general) {
        self.context = context
    }

    var body: some View {
        if !networkMonitor.isConnected {
            HStack(spacing: 6) {
                Image(systemName: iconForContext)
                    .font(.caption)
                Text(messageForContext)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.6))
            .cornerRadius(16)
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.easeInOut, value: networkMonitor.isConnected)
            .accessibilityLabel("\(messageForContext). Offline mode active")
        }
    }

    private var iconForContext: String {
        switch context {
        case .general: return "wifi.slash"
        case .aiFeatures: return "brain"
        case .sharing: return "square.and.arrow.up"
        case .notifications: return "bell.slash"
        }
    }

    private var messageForContext: String {
        switch context {
        case .general: return "Offline"
        case .aiFeatures: return "AI features offline"
        case .sharing: return "Sharing queued"
        case .notifications: return "Notifications limited"
        }
    }
}

#Preview {
    OfflineIndicatorView()
}







