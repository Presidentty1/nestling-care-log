import SwiftUI
import LocalAuthentication

struct PrivacySettingsView: View {
    @StateObject private var privacyManager = PrivacyManager.shared
    @State private var showFaceIDAlert = false
    @State private var isAuthenticating = false
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfUse = false
    
    var body: some View {
        Form {
            Section("App Privacy") {
                Toggle("Blur app in app switcher", isOn: $privacyManager.isAppPrivacyEnabled)
                    .onChange(of: privacyManager.isAppPrivacyEnabled) { _, _ in
                        privacyManager.saveSettings()
                    }
                
                Text("When enabled, the app will be blurred when viewed in the app switcher to protect your privacy.")
                    .font(.caption)
                    .foregroundColor(.mutedForeground)
            }
            
            Section("Authentication") {
                if AuthenticationManager.shared.isBiometricsAvailable() {
                    Toggle("Require Face ID / Touch ID", isOn: $privacyManager.isFaceIDEnabled)
                        .onChange(of: privacyManager.isFaceIDEnabled) { _, newValue in
                            if newValue {
                                authenticateAndEnable()
                            } else {
                                privacyManager.saveSettings()
                            }
                        }
                } else {
                    HStack {
                        Text("Biometrics Unavailable")
                            .foregroundColor(.mutedForeground)
                        Spacer()
                        Text("Not available on this device")
                            .font(.caption)
                            .foregroundColor(.mutedForeground)
                    }
                }
            }
            
            Section("Caregiver Mode") {
                Toggle("Enable Caregiver Mode", isOn: $privacyManager.isCaregiverModeEnabled)
                    .onChange(of: privacyManager.isCaregiverModeEnabled) { _, _ in
                        privacyManager.saveSettings()
                    }
                
                Text("Simplified interface with larger touch targets and fewer options for easier use.")
                    .font(.caption)
                    .foregroundColor(.mutedForeground)
            }

            Section("Data & Storage") {
                Label("Storage", systemImage: "lock.doc")
                Text("Logs are stored locally and synced via iCloud when enabled. AI features only send short text context when you consent; cry audio stays on-device and is deleted after analysis.")
                    .font(.caption)
                    .foregroundColor(.mutedForeground)
                Label("Retention", systemImage: "clock.arrow.circlepath")
                Text("Audio recordings are deleted after analysis. Data deletion from Settings removes local and cloud copies where applicable.")
                    .font(.caption)
                    .foregroundColor(.mutedForeground)
            }
            
            Section("Policies") {
                Button("Privacy Policy") {
                    showPrivacyPolicy = true
                }
                .foregroundColor(.primary)

                Button("Terms of Use") {
                    showTermsOfUse = true
                }
                .foregroundColor(.primary)
            }
        }
        .navigationTitle("Privacy & Security")
        .alert("Authentication Required", isPresented: $showFaceIDAlert) {
            Button("OK") { }
        } message: {
            Text("Please authenticate to enable Face ID protection.")
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            LegalDocumentView(documentType: .privacyPolicy)
        }
        .sheet(isPresented: $showTermsOfUse) {
            LegalDocumentView(documentType: .termsOfUse)
        }
    }
    
    private func authenticateAndEnable() {
        isAuthenticating = true
        Task {
            let success = await AuthenticationManager.shared.authenticate(reason: "Enable Face ID protection for Nestling")
            await MainActor.run {
                isAuthenticating = false
                if success {
                    privacyManager.saveSettings()
                } else {
                    privacyManager.isFaceIDEnabled = false
                    showFaceIDAlert = true
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PrivacySettingsView()
    }
}

