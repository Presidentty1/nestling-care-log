import Foundation

/// Manages undo operations for deletions.
/// Provides a lightweight undo queue with expiration.
@MainActor
class UndoManager: ObservableObject {
    static let shared = UndoManager()
    
    struct UndoableDeletion {
        let event: Event
        let deletedAt: Date
        let restoreAction: () async throws -> Void
        
        var isExpired: Bool {
            Date().timeIntervalSince(deletedAt) > 7.0 // 7 second window
        }
    }
    
    @Published private(set) var pendingDeletion: UndoableDeletion?
    
    private init() {}
    
    /// Register a deletion for potential undo.
    /// - Parameters:
    ///   - event: The event that was deleted
    ///   - restoreAction: Async closure to restore the event
    func registerDeletion(event: Event, restoreAction: @escaping () async throws -> Void) {
        pendingDeletion = UndoableDeletion(
            event: event,
            deletedAt: Date(),
            restoreAction: restoreAction
        )
        
        // Auto-expire after 7 seconds
        Task {
            try? await Task.sleep(nanoseconds: 7_000_000_000)
            if let deletion = pendingDeletion, deletion.event.id == event.id {
                await MainActor.run {
                    if pendingDeletion?.event.id == event.id {
                        pendingDeletion = nil
                    }
                }
            }
        }
    }
    
    /// Perform undo operation.
    func undo() async throws {
        guard let deletion = pendingDeletion, !deletion.isExpired else {
            throw UndoError.expired
        }
        
        try await deletion.restoreAction()
        pendingDeletion = nil
    }
    
    /// Clear pending deletion (called when user dismisses or time expires).
    func clear() {
        pendingDeletion = nil
    }
    
    /// Check if there's an undoable deletion.
    var hasUndoableDeletion: Bool {
        guard let deletion = pendingDeletion else { return false }
        return !deletion.isExpired
    }
}

enum UndoError: LocalizedError {
    case expired
    
    var errorDescription: String? {
        switch self {
        case .expired:
            return "Undo window has expired"
        }
    }
}

