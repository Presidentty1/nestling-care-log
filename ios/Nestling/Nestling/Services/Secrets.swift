import Foundation

/// Secrets configuration for the Nestling app.
///
/// This file contains sensitive configuration values.
/// **DO NOT** commit actual secrets to version control.
/// Instead, use environment variables or Xcode build settings.
///
/// For local development, you can add these to your Xcode scheme:
/// - Edit Scheme → Run → Arguments → Environment Variables
/// - Add: SUPABASE_URL = "https://your-project.supabase.co"
/// - Add: SUPABASE_ANON_KEY = "your-anon-key-here"
///
/// Or update the values below directly (but don't commit them).
struct Secrets {
    /// Supabase project URL
    static var supabaseURL: String {
        // Try environment variable first
        if let url = ProcessInfo.processInfo.environment["SUPABASE_URL"], !url.isEmpty {
            return url
        }

        // Fallback to hardcoded value (update this with your actual URL)
        // Replace with your Supabase project URL
        return "https://your-project.supabase.co"
    }

    /// Supabase anonymous (public) key
    static var supabaseAnonKey: String {
        // Try environment variable first
        if let key = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"], !key.isEmpty {
            return key
        }

        // Fallback to hardcoded value (update this with your actual key)
        // Replace with your Supabase anon key
        return "your-anon-key-here"
    }

    /// Supabase JWT secret (for edge function calls)
    static var supabaseJWT: String? {
        ProcessInfo.processInfo.environment["SUPABASE_JWT"]
    }
    
    /// Check if secrets are properly configured
    static var isConfigured: Bool {
        let url = supabaseURL
        let key = supabaseAnonKey
        return url != "https://your-project.supabase.co" && 
               key != "your-anon-key-here" &&
               !url.isEmpty && 
               !key.isEmpty
    }
}

