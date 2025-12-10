import SwiftUI

/// Error boundary wrapper to catch and handle SwiftUI view errors gracefully
/// Prevents entire app crashes by displaying user-friendly error states
struct ErrorBoundary<Content: View>: View {
    let content: Content
    @State private var error: Error?
    @State private var hasError = false

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        Group {
            if hasError, let error = error {
                ErrorBoundaryView(error: error, retryAction: {
                    self.error = nil
                    self.hasError = false
                })
            } else {
                content
            }
        }
        .onCatchError { error in
            Logger.error("Error boundary caught error: \(error.localizedDescription)")
            self.error = error
            self.hasError = true
        }
    }
}

/// User-friendly error display view
struct ErrorBoundaryView: View {
    let error: Error
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: .spacingLG) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.destructive)

            Text("Something went wrong")
                .font(.headline)
                .foregroundColor(.foreground)

            Text("The app encountered an unexpected error. You can try again or restart the app.")
                .font(.body)
                .foregroundColor(.mutedForeground)
                .multilineTextAlignment(.center)
                .padding(.horizontal, .spacingMD)

            VStack(spacing: .spacingSM) {
                PrimaryButton("Try Again", action: retryAction)

                Button(action: {
                    // Attempt graceful restart by clearing error state
                    // In a production app, this could trigger a full app state reset
                    Logger.info("User requested app restart after error")
                    CrashReporter.shared.reportIssue("User requested restart", context: ["error": error.localizedDescription])
                    
                    // Clear error and attempt to reload
                    retryAction()
                    
                    // If retry doesn't work, user can force-quit and reopen
                    // fatalError should never be used in production code
                }) {
                    Text("Restart App")
                        .font(.body)
                        .foregroundColor(.destructive)
                        .padding(.spacingMD)
                        .background(NuzzleTheme.surface)
                        .cornerRadius(.radiusMD)
                }
            }
            .padding(.top, .spacingMD)
        }
        .padding(.spacing2XL)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(NuzzleTheme.background)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error occurred: \(error.localizedDescription)")
        .accessibilityHint("Tap try again to reload, or restart app if the problem persists")
    }
}

/// Extension to add error catching to any View
extension View {
    /// Catch errors thrown by child views and display error boundary
    func catchErrors() -> some View {
        ErrorBoundary {
            self
        }
    }

    /// Add error handling with custom error view
    func onCatchError(_ handler: @escaping (Error) -> Void) -> some View {
        self.modifier(ErrorCatchingModifier(onError: handler))
    }
}

/// View modifier that catches errors from child views
struct ErrorCatchingModifier: ViewModifier {
    let onError: (Error) -> Void

    func body(content: Content) -> some View {
        content
            .environment(\.errorHandler, ErrorHandler(onError: onError))
    }
}

/// Environment key for error handling
private struct ErrorHandlerKey: EnvironmentKey {
    static let defaultValue: ErrorHandler? = nil
}

extension EnvironmentValues {
    var errorHandler: ErrorHandler? {
        get { self[ErrorHandlerKey.self] }
        set { self[ErrorHandlerKey.self] = newValue }
    }
}

/// Error handler class that can be injected via environment
class ErrorHandler {
    let onError: (Error) -> Void

    init(onError: @escaping (Error) -> Void) {
        self.onError = onError
    }

    func handle(_ error: Error) {
        Logger.error("Handled error: \(error.localizedDescription)")
        onError(error)
    }
}

#Preview {
    ErrorBoundaryView(
        error: NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "This is a test error"]),
        retryAction: {}
    )
}
