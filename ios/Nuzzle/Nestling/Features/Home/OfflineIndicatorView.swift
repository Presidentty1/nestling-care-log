import SwiftUI

struct OfflineIndicatorView: View {
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    var body: some View {
        if !networkMonitor.isConnected {
            HStack(spacing: 6) {
                Image(systemName: "wifi.slash")
                    .font(.caption)
                Text("Offline")
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
            .accessibilityLabel("Offline mode active")
        }
    }
}

#Preview {
    OfflineIndicatorView()
}






