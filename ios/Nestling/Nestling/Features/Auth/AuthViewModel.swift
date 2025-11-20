import Foundation
import Combine
// TODO: Uncomment when Supabase Swift SDK is added
// import Supabase

/// ViewModel for authentication flow (sign up, sign in, sign out)
@MainActor
class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var name = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var session: AuthSession?
    
    private let provider = SupabaseClientProvider.shared
    private var authStateSubscription: AnyCancellable?
    
    init() {
        // Check for existing session on init
        Task {
            await restoreSession()
        }
        
        // Set up auth state listener when SDK is added
        // TODO: Uncomment when Supabase Swift SDK is added
        // setupAuthStateListener()
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
        
        guard provider.isConfigured else {
            throw AuthError.notConfigured
        }
        
        // TODO: Uncomment when Supabase Swift SDK is added
        // do {
        //     let response = try await provider.client.auth.signUp(
        //         email: email,
        //         password: password,
        //         data: ["name": name.isEmpty ? nil : name]
        //     )
        //     
        //     if let session = response.session {
        //         self.session = AuthSession(from: session)
        //         // Save session to Keychain
        //         try await saveSession(session)
        //     } else {
        //         // Email confirmation required
        //         throw AuthError.emailConfirmationRequired
        //     }
        // } catch {
        //     self.errorMessage = error.localizedDescription
        //     throw error
        // }
        
        throw AuthError.notImplemented("Auth requires Supabase SDK - see SUPABASE_SETUP.md")
    }
    
    /// Sign in with email and password
    func signIn() async throws {
        guard !email.isEmpty, !password.isEmpty else {
            throw AuthError.invalidInput("Email and password are required")
        }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        guard provider.isConfigured else {
            throw AuthError.notConfigured
        }
        
        // TODO: Uncomment when Supabase Swift SDK is added
        // do {
        //     let response = try await provider.client.auth.signIn(
        //         email: email,
        //         password: password
        //     )
        //     
        //     guard let session = response.session else {
        //         throw AuthError.authenticationFailed("No session returned")
        //     }
        //     
        //     self.session = AuthSession(from: session)
        //     // Save session to Keychain
        //     try await saveSession(session)
        // } catch {
        //     self.errorMessage = error.localizedDescription
        //     throw error
        // }
        
        throw AuthError.notImplemented("Auth requires Supabase SDK - see SUPABASE_SETUP.md")
    }
    
    /// Sign out current user
    func signOut() async throws {
        guard provider.isConfigured else {
            throw AuthError.notConfigured
        }
        
        // TODO: Uncomment when Supabase Swift SDK is added
        // try await provider.client.auth.signOut()
        // self.session = nil
        // try await clearSession()
        
        throw AuthError.notImplemented("Auth requires Supabase SDK - see SUPABASE_SETUP.md")
    }
    
    /// Restore session from Keychain
    func restoreSession() async {
        guard provider.isConfigured else { return }
        
        // TODO: Uncomment when Supabase Swift SDK is added
        // do {
        //     let session = try await loadSession()
        //     if let session = session {
        //         self.session = AuthSession(from: session)
        //         // Refresh session if needed
        //         try await provider.client.auth.refreshSession()
        //     }
        // } catch {
        //     print("Failed to restore session: \(error)")
        // }
    }
    
    // MARK: - Auth State Listener
    
    private func setupAuthStateListener() {
        // TODO: Uncomment when Supabase Swift SDK is added
        // let authStateChanges = provider.client.auth.authStateChanges
        // authStateSubscription = authStateChanges
        //     .sink { [weak self] event in
        //         Task { @MainActor in
        //             switch event {
        //             case .initialSession(let session):
        //                 if let session = session {
        //                     self?.session = AuthSession(from: session)
        //                 }
        //             case .signedIn(let session):
        //                 self?.session = AuthSession(from: session)
        //                 try? await self?.saveSession(session)
        //             case .signedOut:
        //                 self?.session = nil
        //                 try? await self?.clearSession()
        //             case .tokenRefreshed(let session):
        //                 self?.session = AuthSession(from: session)
        //                 try? await self?.saveSession(session)
        //             default:
        //                 break
        //             }
        //         }
        //     }
    }
    
    // MARK: - Dev Mode
    
    #if DEBUG
    /// Skip authentication for development (DEV ONLY - remove before production)
    func skipAuthentication() {
        print("⚠️ DEV MODE: Skipping authentication")
        // Set a mock session so the app proceeds normally
        // This is a placeholder - in production, this would be a real Supabase session
        session = AuthSession(
            userId: UUID(),
            email: "dev@nestling.app",
            accessToken: "dev-token-\(UUID().uuidString)",
            refreshToken: "dev-refresh-\(UUID().uuidString)",
            expiresAt: Date().addingTimeInterval(86400 * 365) // Expires in 1 year
        )
    }
    #endif
    
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

