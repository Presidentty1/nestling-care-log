import Foundation
// TODO: Uncomment when Supabase Swift SDK is added via SPM
// import Supabase

/// Supabase client provider singleton.
///
/// Handles initialization and configuration of the Supabase Swift SDK.
/// Loads credentials from environment variables or build configuration.
///
/// Setup Steps:
/// 1. Add Supabase Swift SDK via Swift Package Manager in Xcode:
///    - File → Add Package Dependencies
///    - URL: https://github.com/supabase/supabase-swift
///    - Version: Latest
///    - Add to Nestling target
///
/// 2. Uncomment the `import Supabase` line above
/// 3. Uncomment the client initialization code below
///
/// Usage:
/// ```swift
/// let provider = SupabaseClientProvider.shared
/// let client = provider.client
/// ```
final class SupabaseClientProvider {
    static let shared = SupabaseClientProvider()
    
    // TODO: Uncomment when Supabase Swift SDK is added
    // let client: SupabaseClient
    
    private var configured = false
    
    private init() {
        // Load credentials from environment variables
        let url = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? ""
        let anonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? ""

        guard !url.isEmpty, !anonKey.isEmpty else {
            print("⚠️ WARNING: Supabase credentials not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY environment variables or build settings.")
            return
        }
        
        // TODO: Uncomment when Supabase Swift SDK is added
        // Initialize Supabase client
        // self.client = SupabaseClient(
        //     supabaseURL: URL(string: url)!,
        //     supabaseKey: anonKey
        // )
        
        self.configured = true
        print("✅ SupabaseClientProvider initialized with URL: \(url)")
    }
    
    /// Check if Supabase is configured and ready to use
    var isConfigured: Bool {
        configured
    }
    
    /// Legacy configure method (deprecated - now uses environment variables automatically)
    @available(*, deprecated, message: "Credentials are now loaded automatically from environment variables")
    func configure(url: String, anonKey: String) {
        // This method is kept for backward compatibility but does nothing
        // Credentials are loaded from environment variables in init()
    }
    
    /// Get current user session
    /// Returns nil if not authenticated
    func getCurrentSession() async throws -> Any? {
        guard isConfigured else {
            throw SupabaseError.notConfigured
        }
        
        // TODO: Uncomment when Supabase Swift SDK is added
        // return try await client.auth.session
        
        return nil
    }
    
    /// Sign in with email and password
    func signIn(email: String, password: String) async throws {
        guard isConfigured else {
            throw SupabaseError.notConfigured
        }
        
        // TODO: Uncomment when Supabase Swift SDK is added
        // try await client.auth.signIn(email: email, password: password)
    }
    
    /// Sign up with email and password
    func signUp(email: String, password: String, name: String?) async throws {
        guard isConfigured else {
            throw SupabaseError.notConfigured
        }
        
        // TODO: Uncomment when Supabase Swift SDK is added
        // let response = try await client.auth.signUp(
        //     email: email,
        //     password: password,
        //     data: ["name": name ?? ""]
        // )
    }
    
    /// Sign out current user
    func signOut() async throws {
        guard isConfigured else {
            throw SupabaseError.notConfigured
        }
        
        // TODO: Uncomment when Supabase Swift SDK is added
        // try await client.auth.signOut()
    }
}

// Backward compatibility alias
typealias SupabaseClient = SupabaseClientProvider

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

