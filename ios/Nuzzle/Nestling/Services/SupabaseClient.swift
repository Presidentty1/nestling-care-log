import Foundation
import Supabase

/// Supabase client configuration and shared instance
@MainActor
class SupabaseClientProvider {
    static let shared = SupabaseClientProvider()

    private(set) var client: SupabaseClient?
    private(set) var isConfigured = false

    private init() {
        configure()
    }

    private func configure() {
        let environment = ProcessInfo.processInfo.environment
        let url = environment["SUPABASE_URL"] ?? ""
        let key = environment["SUPABASE_ANON_KEY"] ?? ""

        // Validate configuration
        guard !url.isEmpty,
              !key.isEmpty else {
            logger.debug("⚠️ Supabase not configured - environment variables SUPABASE_URL and SUPABASE_ANON_KEY are required")
            return
        }

        // Create Supabase client with simplified configuration
        guard let supabaseURL = URL(string: url) else {
            logger.debug("❌ Invalid Supabase URL")
            return
        }
        
        client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: key
        )
        isConfigured = true

        logger.debug("✅ Supabase client configured successfully")
    }

    /// Get the configured Supabase client
    func getClient() throws -> SupabaseClient {
        guard let client = client, isConfigured else {
            throw NSError(
                domain: "SupabaseClient",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Supabase client not configured"]
            )
        }
        return client
    }

    /// Reconfigure client (useful for testing)
    func reconfigure(url: String, key: String) {
        // For testing only - in production, environment variables are used
        client = nil
        isConfigured = false

        // Reconfigure with new values
        guard let supabaseURL = URL(string: url) else {
            logger.debug("❌ Invalid Supabase URL")
            return
        }
        
        client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: key
        )
        isConfigured = true
    }
}