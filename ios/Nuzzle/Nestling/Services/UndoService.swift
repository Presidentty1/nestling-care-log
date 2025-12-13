import SwiftUI

/// Service for managing undo operations throughout the app.
/// Provides a standardized way to offer users the ability to reverse actions.
@MainActor
final class UndoService: ObservableObject {
    static let shared = UndoService()

    @Published var currentUndo: UndoAction?

    struct UndoAction {
        let id = UUID()
        let message: String
        let undoHandler: () async throws -> Void
        let expiresAt: Date
    }

    /// Offer an undo operation to the user
    /// - Parameters:
    ///   - message: User-facing message like "Event deleted"
    ///   - duration: How long to show the undo option (default 5 seconds)
    ///   - handler: Async function to execute if user taps undo
    func offerUndo(message: String, duration: TimeInterval = 5, handler: @escaping () async throws -> Void) {
        currentUndo = UndoAction(
            message: message,
            undoHandler: handler,
            expiresAt: Date().addingTimeInterval(duration)
        )

        // Auto-dismiss after duration
        Task {
            try? await Task.sleep(for: .seconds(duration))
            if currentUndo?.id == currentUndo?.id {
                currentUndo = nil
            }
        }
    }

    /// Execute the current undo action
    func executeUndo() async {
        guard let action = currentUndo else { return }
        currentUndo = nil
        try? await action.undoHandler()
        Haptics.success()
    }

    /// Dismiss the current undo without executing it
    func dismiss() {
        currentUndo = nil
    }

    /// Check if an undo is currently available
    var hasUndo: Bool {
        currentUndo != nil
    }

    /// Time remaining for current undo in seconds
    var timeRemaining: TimeInterval? {
        guard let expiresAt = currentUndo?.expiresAt else { return nil }
        return max(0, expiresAt.timeIntervalSince(Date()))
    }
}
