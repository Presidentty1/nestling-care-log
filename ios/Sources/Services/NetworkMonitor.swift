import Foundation
import Network
import Combine

/// Monitors network connectivity status and publishes changes.
/// Used for offline queue management and sync triggering.
@MainActor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published private(set) var isConnected: Bool = false
    @Published private(set) var connectionType: NWInterface.InterfaceType?

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.nestling.networkmonitor")

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.updateConnectionStatus(path)
            }
        }
        monitor.start(queue: monitorQueue)

        // Get initial status
        updateConnectionStatus(monitor.currentPath)
    }

    deinit {
        monitor.cancel()
    }

    private func updateConnectionStatus(_ path: NWPath) {
        let wasConnected = isConnected
        isConnected = path.status == .satisfied
        connectionType = path.usesInterfaceType(.wifi) ? .wifi : .cellular

        // Log connectivity changes
        if wasConnected != isConnected {
            Logger.networkInfo("Network connectivity changed: \(isConnected ? "connected" : "disconnected")")
        }
    }

    /// Wait for connectivity to be restored
    /// - Returns: A future that resolves when connectivity is available
    func waitForConnectivity() async {
        if isConnected { return }

        // Create a continuation to wait for connectivity
        await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable?

            cancellable = $isConnected
                .filter { $0 } // Only when connected
                .first()
                .sink { _ in
                    cancellable?.cancel()
                    continuation.resume()
                }
        }
    }
}

