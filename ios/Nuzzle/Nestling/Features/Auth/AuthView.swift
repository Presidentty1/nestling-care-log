import SwiftUI

// MARK: - DEV NOTE: Skip Authentication
// The "Skip Sign Up" button below is for development only.
// To remove before production: Delete the #if DEBUG block around line 132-150
// and remove the skipAuthentication() method from AuthViewModel.swift (around line 174-182)

struct AuthView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var isSignUp = false
    @FocusState private var focusedField: Field?
    @State private var emailError: String?
    @State private var passwordError: String?
    
    var onAuthenticated: () -> Void
    
    init(viewModel: AuthViewModel, onAuthenticated: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onAuthenticated = onAuthenticated
    }
    
    enum Field {
        case email, password, name
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacingXL) {
                    // Logo and header
                    VStack(spacing: .spacingMD) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.eventFeed)
                        
                        Text("Nuzzle")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        // Outcome-focused headline
                        Text("Get 2 More Hours of Sleep")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.foreground)
                            .multilineTextAlignment(.center)
                        
                        Text("Track baby care in 2 taps. AI predicts naps. Sync with partner.")
                            .font(.subheadline)
                            .foregroundColor(.mutedForeground)
                            .multilineTextAlignment(.center)
                        
                        // Pricing transparency with trial callout
                        Text("7-day free trial • Then $5.99/mo")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.eventFeed)
                            .padding(.top, .spacingXS)
                        
                        // Benefit bullets (more outcome-focused)
                        VStack(alignment: .leading, spacing: .spacingSM) {
                            HStack(spacing: .spacingSM) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.eventFeed)
                                    .font(.caption)
                                Text("87% accurate nap predictions")
                                    .font(.caption)
                                    .foregroundColor(.mutedForeground)
                            }
                            HStack(spacing: .spacingSM) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.eventFeed)
                                    .font(.caption)
                                Text("Real-time sync with all caregivers")
                                    .font(.caption)
                                    .foregroundColor(.mutedForeground)
                            }
                            HStack(spacing: .spacingSM) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.eventFeed)
                                    .font(.caption)
                                Text("Works offline • Privacy-first")
                                    .font(.caption)
                                    .foregroundColor(.mutedForeground)
                            }
                        }
                        .padding(.top, .spacingSM)
                    }
                    .padding(.top, .spacingXL)
                    
                    // Auth Form
                    VStack(spacing: .spacingLG) {
                        // Tabs
                        Picker("Auth Mode", selection: $isSignUp) {
                            Text("Sign In").tag(false)
                            Text("Sign Up").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, .spacingMD)
                        .background(Color.surface.opacity(0.5))
                        .cornerRadius(.radiusMD)
                        
                        // Form Fields
                        VStack(spacing: .spacingMD) {
                            // Name field (only for sign up)
                            if isSignUp {
                                VStack(alignment: .leading, spacing: .spacingXS) {
                                    Text("Name")
                                        .font(.caption)
                                        .foregroundColor(.mutedForeground)
                                    TextField("Enter your name", text: $viewModel.name)
                                        .textFieldStyle(.roundedBorder)
                                        .textContentType(.name)
                                        .autocapitalization(.words)
                                        .focused($focusedField, equals: .name)
                                }
                                .padding(.horizontal, .spacingMD)
                            }
                            
                            // Email field
                            VStack(alignment: .leading, spacing: .spacingXS) {
                                Text("Email")
                                    .font(.caption)
                                    .foregroundColor(.mutedForeground)
                                TextField("Email address", text: $viewModel.email)
                                    .textFieldStyle(.roundedBorder)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                                    .focused($focusedField, equals: .email)
                                    .onChange(of: viewModel.email) { _, newValue in
                                        validateEmail(newValue)
                                    }
                                
                                if let emailError = emailError {
                                    Text(emailError)
                                        .font(.caption)
                                        .foregroundColor(.destructive)
                                        .padding(.top, 2)
                                }
                            }
                            .padding(.horizontal, .spacingMD)
                            
                            // Password field
                            VStack(alignment: .leading, spacing: .spacingXS) {
                                Text("Password")
                                    .font(.caption)
                                    .foregroundColor(.mutedForeground)
                                SecureField("Password", text: $viewModel.password)
                                    .textFieldStyle(.roundedBorder)
                                    .textContentType(isSignUp ? .newPassword : .password)
                                    .focused($focusedField, equals: .password)
                                    .onChange(of: viewModel.password) { _, newValue in
                                        validatePassword(newValue)
                                    }
                                
                                if let passwordError = passwordError {
                                    Text(passwordError)
                                        .font(.caption)
                                        .foregroundColor(.destructive)
                                        .padding(.top, 2)
                                }
                            }
                            .padding(.horizontal, .spacingMD)
                        }
                        
                        // Error message (for auth errors)
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.destructive)
                                .padding(.horizontal, .spacingMD)
                        }
                        
                        // Submit button with clear no-credit-card messaging
                        Button(action: {
                            handleSubmit()
                        }) {
                            VStack(spacing: 4) {
                                HStack {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text(isSignUp ? "Get Started Free" : "Sign In")
                                            .fontWeight(.semibold)
                                    }
                                }
                                if isSignUp && !viewModel.isLoading {
                                    Text("No credit card required")
                                        .font(.caption2)
                                        .opacity(0.9)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: isSignUp ? 60 : 50)
                            .background(Color.eventFeed)
                            .foregroundColor(.white)
                            .cornerRadius(.radiusMD)
                        }
                        .disabled(viewModel.isLoading || !isFormValid)
                        .padding(.horizontal, .spacingMD)
                        
                        // Password reset (sign in only)
                        if !isSignUp {
                            Button("Forgot password?") {
                                Task {
                                    await viewModel.sendPasswordReset()
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.eventFeed)
                            .padding(.top, .spacingXS)
                            .disabled(viewModel.isLoading)
                        }

                        // Password reset confirmation
                        if viewModel.passwordResetSent {
                            Text("Password reset email sent! Check your inbox.")
                                .font(.caption)
                                .foregroundColor(.green)
                                .padding(.top, .spacingXS)
                        }
                    }
                    .padding(.top, .spacingLG)
                    
                    // Continue without account option
                    VStack(spacing: .spacingSM) {
                        Divider()
                            .padding(.vertical, .spacingMD)
                        
                        Button(action: {
                            // Continue without account - use local-only data storage
                            viewModel.skipAuthentication()
                            // Trigger the callback immediately to proceed to onboarding/content
                            onAuthenticated()
                        }) {
                            VStack(spacing: .spacingXS) {
                                Text("Continue without account")
                                    .fontWeight(.medium)
                                Text("You can create an account later to sync with caregivers")
                                    .font(.caption2)
                                    .multilineTextAlignment(.center)
                            }
                            .font(.subheadline)
                            .foregroundColor(.mutedForeground)
                        }
                        .padding(.bottom, .spacingSM)
                        
                        // Legal links
                        HStack(spacing: .spacingMD) {
                            Button("Privacy Policy") {
                                if let url = URL(string: "https://nuzzleapp.com/privacy") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .font(.caption2)
                            .foregroundColor(.mutedForeground)
                            
                            Text("•")
                                .font(.caption2)
                                .foregroundColor(.mutedForeground)
                            
                            Button("Terms of Use") {
                                if let url = URL(string: "https://nuzzleapp.com/terms") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .font(.caption2)
                            .foregroundColor(.mutedForeground)
                        }
                        .padding(.bottom, .spacingMD)
                    }
                    .padding(.horizontal, .spacingMD)
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .onSubmit {
                handleFieldSubmit()
            }
        }
    }
    
    // MARK: - Validation
    
    private var isFormValid: Bool {
        guard !viewModel.email.isEmpty, !viewModel.password.isEmpty else {
            return false
        }
        guard emailError == nil, passwordError == nil else {
            return false
        }
        if isSignUp && viewModel.name.isEmpty {
            return false
        }
        return true
    }
    
    private func validateEmail(_ email: String) {
        if email.isEmpty {
            emailError = nil
            return
        }
        
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        if !emailPredicate.evaluate(with: email) {
            emailError = "Invalid email format"
        } else {
            emailError = nil
        }
    }
    
    private func validatePassword(_ password: String) {
        if password.isEmpty {
            passwordError = nil
            return
        }
        
        if password.count < 8 {
            passwordError = "Password too short (must be at least 8 characters)"
        } else {
            passwordError = nil
        }
    }
    
    // MARK: - Actions
    
    private func handleSubmit() {
        Task {
            focusedField = nil // Dismiss keyboard
            
            do {
                if isSignUp {
                    try await viewModel.signUp()
                } else {
                    try await viewModel.signIn()
                }
                
                // If successful, trigger callback
                if viewModel.session != nil {
                    await MainActor.run {
                        onAuthenticated()
                    }
                }
            } catch {
                // Set user-friendly error message
                if let authError = error as? AuthError {
                    viewModel.errorMessage = authError.errorDescription
                    if case .authenticationFailed = authError {
                        viewModel.errorMessage = "Email or password doesn't match"
                    }
                } else {
                    viewModel.errorMessage = error.localizedDescription
                }
                print("Auth error: \(error)")
            }
        }
    }
    
    private func handleFieldSubmit() {
        switch focusedField {
        case .name:
            focusedField = .email
        case .email:
            focusedField = .password
        case .password:
            handleSubmit()
        case .none:
            break
        }
    }
}

#Preview {
    AuthView(viewModel: AuthViewModel()) {
        print("Authenticated!")
    }
}

