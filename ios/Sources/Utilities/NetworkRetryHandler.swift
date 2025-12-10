import Foundation

/// Handles network request retries with exponential backoff
/// Provides user-friendly error messages and offline queue integration
class NetworkRetryHandler {
    static let shared = NetworkRetryHandler()

    private init() {}

    /// Retry configuration
    struct RetryConfig {
        let maxRetries: Int
        let baseDelay: TimeInterval
        let maxDelay: TimeInterval
        let backoffMultiplier: Double

        static let `default` = RetryConfig(
            maxRetries: 3,
            baseDelay: 1.0,
            maxDelay: 30.0,
            backoffMultiplier: 2.0
        )

        static let aggressive = RetryConfig(
            maxRetries: 5,
            baseDelay: 0.5,
            maxDelay: 10.0,
            backoffMultiplier: 1.5
        )
    }

    /// Execute a network operation with retry logic
    func executeWithRetry<T>(
        config: RetryConfig = .default,
        operation: () async throws -> T,
        onRetry: ((Int, Error) -> Void)? = nil
    ) async throws -> T {
        var lastError: Error?
        var delay = config.baseDelay

        for attempt in 0...config.maxRetries {
            do {
                let result = try await operation()
                return result
            } catch {
                lastError = error

                // Don't retry on certain errors
                if shouldNotRetry(error) {
                    throw error
                }

                // If this was the last attempt, throw the error
                if attempt == config.maxRetries {
                    throw error
                }

                // Notify about retry
                onRetry?(attempt + 1, error)

                // Wait before retrying
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

                // Increase delay for next attempt
                delay = min(delay * config.backoffMultiplier, config.maxDelay)
            }
        }

        // This should never be reached, but just in case
        throw lastError ?? NSError(domain: "NetworkRetryHandler", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error"])
    }

    /// Determine if an error should not be retried
    private func shouldNotRetry(_ error: Error) -> Bool {
        let nsError = error as NSError

        // Don't retry authentication errors (401, 403)
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorUserAuthenticationRequired, // 401
                 NSURLErrorNoPermissionsToReadFile, // 403-like
                 NSURLErrorBadURL, // 400
                 NSURLErrorBadServerResponse: // 5xx but not timeout
                return nsError.code >= 400 && nsError.code < 500
            default:
                break
            }
        }

        // Don't retry if it's a validation error or similar
        if let error = error as? EventValidationError {
            return true
        }

        return false
    }

    /// Get user-friendly error message for network errors
    func userFriendlyErrorMessage(for error: Error) -> String {
        let nsError = error as NSError

        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet:
                return "No internet connection. Changes will be saved locally and synced when you're back online."
            case NSURLErrorTimedOut:
                return "Request timed out. Please check your connection and try again."
            case NSURLErrorNetworkConnectionLost:
                return "Connection lost. Your data is safe and will sync automatically."
            case NSURLErrorCannotConnectToHost:
                return "Cannot connect to server. Please try again later."
            case NSURLErrorBadServerResponse:
                return "Server error. Please try again later."
            default:
                break
            }
        }

        // Check for CloudKit errors
        if let ckError = error as? CKError {
            switch ckError.code {
            case .networkUnavailable:
                return "iCloud not available. Changes will sync when connection is restored."
            case .serviceUnavailable:
                return "iCloud temporarily unavailable. Please try again later."
            case .quotaExceeded:
                return "iCloud storage full. Please free up space or disable iCloud sync."
            case .notAuthenticated:
                return "Not signed into iCloud. Please sign in to sync data."
            default:
                return "iCloud sync error. Changes will be retried automatically."
            }
        }

        // Generic fallback
        return "Something went wrong. Please try again."
    }

    /// Check if error indicates offline state
    func isOfflineError(_ error: Error) -> Bool {
        let nsError = error as NSError

        if nsError.domain == NSURLErrorDomain {
            return nsError.code == NSURLErrorNotConnectedToInternet ||
                   nsError.code == NSURLErrorNetworkConnectionLost
        }

        if let ckError = error as? CKError {
            return ckError.code == .networkUnavailable
        }

        return false
    }
}



