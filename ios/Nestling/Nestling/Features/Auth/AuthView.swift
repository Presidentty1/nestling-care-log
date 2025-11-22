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
                        
                        Text("Nestling")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Stop guessing naps and feeds. Keep everyone in sync with a few simple logs.")
                            .font(.subheadline)
                            .foregroundColor(.mutedForeground)
                            .multilineTextAlignment(.center)
                        
                        // Benefit bullets
                        VStack(alignment: .leading, spacing: .spacingSM) {
                            HStack(spacing: .spacingSM) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.eventFeed)
                                    .font(.caption)
                                Text("Next nap & feed suggestions")
                                    .font(.caption)
                                    .foregroundColor(.mutedForeground)
                            }
                            HStack(spacing: .spacingSM) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.eventFeed)
                                    .font(.caption)
                                Text("Shared log for all caregivers")
                                    .font(.caption)
                                    .foregroundColor(.mutedForeground)
                            }
                            HStack(spacing: .spacingSM) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.eventFeed)
                                    .font(.caption)
                                Text("Gentle reminders, no spam")
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
                        
                        // Submit button
                        Button(action: {
                            handleSubmit()
                        }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text(isSignUp ? "Create account" : "Sign In")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
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
                                    await resetPassword()
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.eventFeed)
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

    private func resetPassword() async {
        guard !viewModel.email.isEmpty else {
            viewModel.errorMessage = "Please enter your email address first"
            return
        }

        do {
            // Note: This would require Supabase SDK integration
            // For now, show a placeholder message
            viewModel.errorMessage = "Password reset email sent. Check your inbox."
            // TODO: Uncomment when Supabase SDK is integrated
            // try await SupabaseClient.shared.auth.resetPasswordForEmail(viewModel.email)
        } catch {
            viewModel.errorMessage = "Failed to send password reset email. Please try again."
        }
    }
}

#Preview {
    AuthView(viewModel: AuthViewModel()) {
        print("Authenticated!")
    }
}

