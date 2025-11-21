import Foundation
import Combine
import Supabase

/// ViewModel for authentication flow (sign up, sign in, sign out)
@MainActor
class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var name = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var session: Supabase.Session?
    @Published var hasSkippedAuth = false // Track if user skipped authentication

    private var supabaseClient: SupabaseClient?
    private var authStateSubscription: AnyCancellable?

    init() {
        // Initialize Supabase client
        do {
            self.supabaseClient = try SupabaseClientProvider.shared.getClient()
        } catch {
            print("⚠️ Supabase client not configured: \(error.localizedDescription)")
        }

        // Check for existing session on init
        Task {
            await restoreSession()
        }

        // Set up auth state listener
        setupAuthStateListener()
    }
    
    // MARK: - Authentication Methods
    
    /// Sign up with email and password
    func signUp() async throws {
        guard !email.isEmpty, !password.isEmpty else {
            throw AuthError.invalidInput("Email and password are required")
        }

        guard password.count >= 8 else {
            throw AuthError.invalidInput("Password must be at least 8 characters")
        }

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        guard let client = supabaseClient else {
            throw AuthError.notConfigured
        }
        
        do {
            let response = try await client.auth.signUp(
                email: email,
                password: password
            )

            if let session = response.session {
                self.session = session
                // Session is automatically persisted by Supabase
                print("✅ Signed up successfully")
            } else {
                // Email confirmation required
                throw AuthError.emailConfirmationRequired
            }
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
    }
    
    /// Sign in with email and password
    func signIn() async throws {
        guard !email.isEmpty, !password.isEmpty else {
            throw AuthError.invalidInput("Email and password are required")
        }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        guard let client = supabaseClient else {
            throw AuthError.notConfigured
        }

        do {
            let session = try await client.auth.signIn(
                email: email,
                password: password
            )

            self.session = session
            print("✅ Signed in successfully")
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
    }
    
    /// Sign out current user
    func signOut() async throws {
        guard let client = supabaseClient else {
            throw AuthError.notConfigured
        }

        try await client.auth.signOut()
        self.session = nil
        print("✅ Signed out successfully")
    }
    
    /// Restore session from Supabase
    func restoreSession() async {
        guard let client = supabaseClient else {
            print("Supabase client not configured")
            return
        }

        do {
            let session = try await client.auth.session
            self.session = session
            if session != nil {
                print("✅ Session restored successfully")
            }
        } catch {
            print("Failed to restore session: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Auth State Listener
    
    private func setupAuthStateListener() {
        guard let client = supabaseClient else { return }

        // Set up auth state changes listener using AsyncStream
        Task {
            for await (event, session) in client.auth.authStateChanges {
                await handleAuthStateChange(event: event, session: session)
            }
        }
    }
    
    private func handleAuthStateChange(event: AuthChangeEvent, session: Supabase.Session?) {
        switch event {
        case .initialSession:
            if let session = session {
                self.session = session
            }
        case .signedIn:
            self.session = session
            print("✅ Auth state: signed in")
        case .signedOut:
            self.session = nil
            print("✅ Auth state: signed out")
        case .tokenRefreshed:
            self.session = session
            print("✅ Auth state: token refreshed")
        default:
            break
        }
    }
    
    // MARK: - Dev Mode
    
    /// Skip authentication to use app in guest mode (local-only data)
    func skipAuthentication() {
        print("✅ Skipping authentication - using guest mode")
        // Mark that user has skipped auth so app can proceed
        hasSkippedAuth = true
        session = nil
    }
    
    // MARK: - Session Persistence (Keychain)
    
    // TODO: Uncomment when Supabase SDK is added
    // private func saveSession(_ session: Session) async throws {
    //     // TODO: Implement Keychain storage
    //     // Use Keychain API to securely store session
    // }
    //
    // private func loadSession() async throws -> Session? {
    //     // TODO: Implement Keychain retrieval
    //     // Load session from Keychain
    //     return nil
    // }
    
    private func clearSession() async throws {
        // TODO: Implement Keychain deletion
        // Remove session from Keychain
    }
    
    deinit {
        authStateSubscription?.cancel()
    }
}

// MARK: - Auth Models

struct AuthSession {
    let userId: UUID
    let email: String?
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    
    // TODO: Uncomment when Supabase Swift SDK is added
    // init(from session: Session) {
    //     self.userId = UUID(uuidString: session.user.id.uuidString) ?? UUID()
    //     self.email = session.user.email
    //     self.accessToken = session.accessToken
    //     self.refreshToken = session.refreshToken ?? ""
    //     self.expiresAt = session.expiresAt ?? Date.distantFuture
    // }
}

enum AuthError: LocalizedError {
    case invalidInput(String)
    case notConfigured
    case authenticationFailed(String)
    case emailConfirmationRequired
    case notImplemented(String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidInput(let message):
            return message
        case .notConfigured:
            return "Supabase is not configured. Please check environment variables SUPABASE_URL and SUPABASE_ANON_KEY"
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .emailConfirmationRequired:
            return "Please check your email to confirm your account"
        case .notImplemented(let message):
            return message
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

