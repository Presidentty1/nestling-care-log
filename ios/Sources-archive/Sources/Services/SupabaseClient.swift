import Foundation
import Supabase

/// Supabase client wrapper for iOS.
///
/// Provides authentication and session management for the Nestling app.
/// Requires Supabase Swift SDK to be added via Swift Package Manager.
class SupabaseClient {
    static let shared = SupabaseClient()

    private var configured = false
    private(set) var client: SupabaseClient?
    var url: String?
    var anonKey: String?

    private init() {}
    
    /// Configure Supabase client with project URL and anonymous key
    /// - Parameters:
    ///   - url: Your Supabase project URL (e.g., "https://xxx.supabase.co")
    ///   - anonKey: Your Supabase anonymous key
    func configure(url: String, anonKey: String) {
        self.url = url
        self.anonKey = anonKey
        self.configured = true

        // Initialize Supabase client
        guard let supabaseURL = URL(string: url) else {
            Logger.dataError("Invalid Supabase URL: \(url)")
            return
        }

        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: anonKey
        )
    }
    
    /// Check if Supabase is configured
    var isConfigured: Bool {
        configured && url != nil && anonKey != nil
    }
    
    /// Get current user session
    /// Returns the session if authenticated, nil otherwise
    func getCurrentSession() async throws -> Session? {
        guard isConfigured, let client = client else {
            throw SupabaseError.notConfigured
        }

        do {
            return try await client.auth.session
        } catch {
            // Not authenticated or session expired
            return nil
        }
    }
    
    /// Sign in with email and password
    func signIn(email: String, password: String) async throws {
        guard isConfigured, let client = client else {
            throw SupabaseError.notConfigured
        }

        do {
            try await client.auth.signIn(email: email, password: password)
        } catch {
            Logger.authError("Sign in failed: \(error.localizedDescription)")
            throw SupabaseError.authenticationFailed
        }
    }

    /// Sign up with email and password
    func signUp(email: String, password: String, name: String?) async throws {
        guard isConfigured, let client = client else {
            throw SupabaseError.notConfigured
        }

        do {
            let authMetaData: [String: AnyJSON] = name != nil ? ["name": .string(name!)] : [:]
            try await client.auth.signUp(
                email: email,
                password: password,
                data: authMetaData
            )
        } catch {
            Logger.authError("Sign up failed: \(error.localizedDescription)")
            throw SupabaseError.authenticationFailed
        }
    }

    /// Sign out current user
    func signOut() async throws {
        guard isConfigured, let client = client else {
            throw SupabaseError.notConfigured
        }

        do {
            try await client.auth.signOut()
        } catch {
            Logger.authError("Sign out failed: \(error.localizedDescription)")
            throw SupabaseError.authenticationFailed
        }
    }
}

enum SupabaseError: LocalizedError {
    case notConfigured
    case authenticationFailed
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Supabase client not configured. Call configure(url:key:) first."
        case .authenticationFailed:
            return "Authentication failed"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}


