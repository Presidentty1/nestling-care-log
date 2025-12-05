import SwiftUI
import SafariServices

struct AuthView: View {
    @StateObject private var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    init(dataStore: DataStore) {
        _viewModel = StateObject(wrappedValue: AuthViewModel(dataStore: dataStore))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NuzzleTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: .spacing3XL) {
                        Spacer().frame(height: .spacing3XL)

                        // Header
                        VStack(spacing: .spacingLG) {
                            Text("Nuzzle")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.primary)

                            Text("Stop guessing naps and feeds...")
                                .font(.title2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, .spacingMD)

                        // Auth Form
                        VStack(spacing: .spacingLG) {
                            // Auth Mode Picker
                            Picker("", selection: $viewModel.authMode) {
                                Text("Sign In").tag(AuthMode.signIn)
                                Text("Sign Up").tag(AuthMode.signUp)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, .spacingMD)
                            .accessibilityLabel("Authentication mode")
                            .accessibilityHint("Switch between sign in and sign up")

                            // Form Fields
                            VStack(spacing: .spacingMD) {
                                if viewModel.authMode == .signUp {
                                    TextField("Name", text: $viewModel.name)
                                        .textFieldStyle(.roundedBorder)
                                        .textContentType(.name)
                                        .autocapitalization(.words)
                                        .padding(.horizontal, .spacingMD)
                                        .frame(height: 44)
                                        .accessibilityLabel("Name")
                                        .accessibilityHint("Enter your full name")
                                }

                                TextField("Email", text: $viewModel.email)
                                    .textFieldStyle(.roundedBorder)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .padding(.horizontal, .spacingMD)
                                    .frame(height: 44)
                                    .accessibilityLabel("Email address")
                                    .accessibilityHint("Enter your email address")

                                SecureField("Password", text: $viewModel.password)
                                    .textFieldStyle(.roundedBorder)
                                    .textContentType(viewModel.authMode == .signUp ? .newPassword : .password)
                                    .padding(.horizontal, .spacingMD)
                                    .frame(height: 44)
                                    .accessibilityLabel("Password")
                                    .accessibilityHint(viewModel.authMode == .signUp ? "Create a secure password" : "Enter your password")
                            }

                            // Error Message
                            if let errorMessage = viewModel.errorMessage {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.horizontal, .spacingMD)
                                    .multilineTextAlignment(.center)
                            }

                            // Primary Action Button
                            Button(action: {
                                Task {
                                    do {
                                        switch viewModel.authMode {
                                        case .signIn:
                                            try await viewModel.signIn()
                                            dismiss()
                                        case .signUp:
                                            try await viewModel.signUp()
                                            dismiss()
                                        }
                                    } catch {
                                        // Error is already handled in view model
                                    }
                                }
                            }) {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text(viewModel.primaryButtonTitle)
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(NuzzleTheme.primary)
                            .foregroundColor(.white)
                            .cornerRadius(.radiusMD)
                            .padding(.horizontal, .spacingMD)
                            .opacity(viewModel.primaryButtonDisabled ? 0.6 : 1.0)
                            .disabled(viewModel.primaryButtonDisabled)
                            .accessibilityLabel(viewModel.primaryButtonTitle)
                            .accessibilityHint(viewModel.authMode == .signIn ? "Sign in to your existing account" : "Create a new account")

                            // Forgot Password (placeholder for future)
                            if viewModel.authMode == .signIn {
                                Button("Forgot password?") {
                                    // NOTE: Forgot password flow not implemented for MVP - users can reset via email client
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, .spacingSM)
                                .accessibilityLabel("Forgot password")
                                .accessibilityHint("Reset your password if you've forgotten it")
                            }

                            // Continue Without Account
                            VStack(spacing: .spacingSM) {
                                Divider()
                                    .padding(.horizontal, .spacingMD)

                                Button(action: {
                                    Task {
                                        await viewModel.continueWithoutAccount()
                                        dismiss()
                                    }
                                }) {
                                    VStack(spacing: 4) {
                                        Text("Continue without account")
                                            .font(.body.weight(.medium))
                                            .foregroundColor(NuzzleTheme.textPrimary)
                                        Text("You can create an account later to sync with caregivers.")
                                            .font(.caption)
                                            .foregroundColor(NuzzleTheme.textSecondary)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 44)
                                .padding(.vertical, .spacingSM)
                                .background(NuzzleTheme.surface)
                                .cornerRadius(.radiusMD)
                                .padding(.horizontal, .spacingMD)
                                .disabled(viewModel.isLoading)
                                .accessibilityLabel("Continue without account")
                                .accessibilityHint("Use the app without creating an account, you can add one later for syncing")
                            }
                        }

                        Spacer()

                        // Legal Links
                        VStack(spacing: .spacingSM) {
                            Text("By continuing, you agree to our")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack(spacing: .spacingMD) {
                                Button(action: {
                                    openURL(AppConfig.termsOfServiceURL)
                                }) {
                                    Text("Terms")
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                        .underline()
                                }
                                .accessibilityLabel("Terms of service")
                                .accessibilityHint("Read our terms of service")

                                Text("and")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Button(action: {
                                    openURL(AppConfig.privacyPolicyURL)
                                }) {
                                    Text("Privacy Policy")
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                        .underline()
                                }
                                .accessibilityLabel("Privacy policy")
                                .accessibilityHint("Read our privacy policy")
                            }
                        }
                        .padding(.horizontal, .spacingMD)
                        .padding(.bottom, .spacing2XL)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }

    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            Logger.uiError("Invalid URL: \(urlString)")
            return
        }

        let safariViewController = SFSafariViewController(url: url)
        safariViewController.modalPresentationStyle = .pageSheet

        // Get the current window scene
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(safariViewController, animated: true)
        } else {
            Logger.uiError("Cannot present Safari view controller - no root view controller found")
        }
    }
}

#Preview {
    AuthView(dataStore: InMemoryDataStore())
        .environmentObject(AppEnvironment(dataStore: InMemoryDataStore()))
}
