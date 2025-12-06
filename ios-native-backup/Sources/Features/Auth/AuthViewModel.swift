import Foundation
import CloudKit
import Combine

enum AuthMode {
    case signIn
    case signUp
}

@MainActor
class AuthViewModel: ObservableObject {
    @Published var authMode: AuthMode = .signIn
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var name: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // CloudKit account status
    @Published var cloudKitAccountStatus: CKAccountStatus = .couldNotDetermine
    @Published var accountStatus: AccountStatus = .notSet

    private let dataStore: DataStore
    private var cancellables = Set<AnyCancellable>()

    init(dataStore: DataStore) {
        self.dataStore = dataStore
        checkAccountStatus()
        checkCloudKitAccountStatus()
    }

    // MARK: - Auth Actions

    func signIn() async throws {
        guard validateInputs() else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            // Authenticate with CloudKit
            try await CloudKitAuthService.shared.authenticate()

            // Update account status
            accountStatus = .signedIn
            saveAccountStatus(.signedIn, type: .cloudKit)

            // Analytics
            await Analytics.shared.log("auth_sign_in", parameters: [
                "method": "cloudkit",
                "account_type": AccountType.cloudKit.rawValue
            ])

        } catch let error as CloudKitAuthError {
            errorMessage = error.localizedDescription
            throw error
        } catch {
            errorMessage = "Sign in failed: \(error.localizedDescription)"
            throw error
        }
    }

    func signUp() async throws {
        guard validateInputs() else { return }
        guard !name.isEmpty else {
            errorMessage = "Name is required for sign up"
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // Get user record ID and create account
            let (status, userRecordID) = await CloudKitAuthService.shared.getAccountInfo()

            guard status == .available, let userRecordID = userRecordID else {
                throw CloudKitAuthError.noCloudKitAccount
            }

            try await CloudKitAuthService.shared.createAccount(userRecordID: userRecordID)

            // Update account status
            accountStatus = .signedIn
            saveAccountStatus(.signedIn, type: .cloudKit)

            // Analytics
            await Analytics.shared.log("auth_sign_up", parameters: [
                "method": "cloudkit",
                "account_type": AccountType.cloudKit.rawValue
            ])

        } catch let error as CloudKitAuthError {
            errorMessage = error.localizedDescription
            throw error
        } catch {
            errorMessage = "Sign up failed: \(error.localizedDescription)"
            throw error
        }
    }

    func continueWithoutAccount() async {
        isLoading = true
        defer { isLoading = false }

        // Create a local-only account
        accountStatus = .hasAccount
        saveAccountStatus(.hasAccount, type: .localOnly)

        // Analytics
        await Analytics.shared.log("auth_continue_without_account", parameters: [
            "account_type": AccountType.localOnly.rawValue
        ])
    }

    // MARK: - Validation

    private func validateInputs() -> Bool {
        guard !email.isEmpty else {
            errorMessage = "Email is required"
            return false
        }

        guard email.contains("@") && email.contains(".") else {
            errorMessage = "Please enter a valid email address"
            return false
        }

        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return false
        }

        errorMessage = nil
        return true
    }

    // MARK: - CloudKit Status

    private func checkCloudKitAccountStatus() {
        Task {
            let status = await CloudKitAuthService.shared.checkAccountStatus()
            await MainActor.run {
                self.cloudKitAccountStatus = status
            }
        }
    }

    private func checkAccountStatus() {
        let statusRaw = UserDefaults.standard.string(forKey: AppConfig.userDefaultsAccountStatusKey) ?? AccountStatus.notSet.rawValue
        accountStatus = AccountStatus(rawValue: statusRaw) ?? .notSet
    }

    private func saveAccountStatus(_ status: AccountStatus, type: AccountType) {
        UserDefaults.standard.set(status.rawValue, forKey: AppConfig.userDefaultsAccountStatusKey)
        UserDefaults.standard.set(type.rawValue, forKey: AppConfig.userDefaultsAccountTypeKey)
    }


    // MARK: - Computed Properties

    var primaryButtonTitle: String {
        switch authMode {
        case .signIn: return "Sign In"
        case .signUp: return "Sign Up"
        }
    }

    var primaryButtonDisabled: Bool {
        email.isEmpty || password.isEmpty || (authMode == .signUp && name.isEmpty) || isLoading
    }

    var canContinueWithoutAccount: Bool {
        // Allow continuing without account if CloudKit is available or we're in local-only mode
        cloudKitAccountStatus != .noAccount
    }
}
