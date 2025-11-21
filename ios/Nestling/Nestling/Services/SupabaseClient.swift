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
        let url = Secrets.supabaseURL
        let key = Secrets.supabaseAnonKey

        // Validate configuration
        guard url != "https://your-project.supabase.co",
              key != "your-anon-key-here",
              !url.isEmpty,
              !key.isEmpty else {
            print("⚠️ Supabase not configured - using placeholder values")
            return
        }

        do {
            // Create Supabase client with simplified configuration
            guard let supabaseURL = URL(string: url) else {
                print("❌ Invalid Supabase URL")
                return
            }
            
            client = SupabaseClient(
                supabaseURL: supabaseURL,
                supabaseKey: key
            )
            isConfigured = true

            print("✅ Supabase client configured successfully")
        } catch {
            print("❌ Failed to configure Supabase client: \(error.localizedDescription)")
        }
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
        // Update Secrets (this is for testing only)
        // In production, use environment variables
        client = nil
        isConfigured = false

        // Reconfigure with new values
        guard let supabaseURL = URL(string: url) else {
            print("❌ Invalid Supabase URL")
            return
        }
        
        client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: key
        )
        isConfigured = true
    }
}