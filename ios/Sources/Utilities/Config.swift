import Foundation
import UIKit

/// App configuration constants
struct AppConfig {
    // Legal URLs - must match App Store Connect metadata exactly
    static let termsOfServiceURL = "https://nestling.care/terms-of-service"
    static let privacyPolicyURL = "https://nestling.care/privacy-policy"
    static let supportURL = "https://nestling.care/support"

    /// Validate URL before opening to prevent crashes
    static func validateAndOpenURL(_ urlString: String, fallbackURLString: String? = nil) {
        guard let url = URL(string: urlString) else {
            Logger.uiError("Invalid URL: \(urlString)")
            if let fallback = fallbackURLString, let fallbackURL = URL(string: fallback) {
                Logger.ui("Using fallback URL: \(fallback)")
                UIApplication.shared.open(fallbackURL)
            }
            return
        }

        // Check if URL can be opened
        guard UIApplication.shared.canOpenURL(url) else {
            Logger.uiError("Cannot open URL: \(urlString)")
            if let fallback = fallbackURLString, let fallbackURL = URL(string: fallback) {
                Logger.ui("Trying fallback URL: \(fallback)")
                UIApplication.shared.open(fallbackURL)
            }
            return
        }

        UIApplication.shared.open(url) { success in
            if !success {
                Logger.uiError("Failed to open URL: \(urlString)")
            }
        }
    }

    // Auth-related configuration
    static let maxLoginAttempts = 5

    // CloudKit container identifier (for future CloudKit auth)
    static let cloudKitContainerIdentifier = "iCloud.com.nestling.Nestling"

    // Account status keys for UserDefaults
    static let userDefaultsAccountStatusKey = "accountStatus"
    static let userDefaultsAccountTypeKey = "accountType"
    static let userDefaultsCaregiverModeKey = "isCaregiverMode"
}

// Account types for the app
enum AccountType: String, Codable {
    case localOnly = "local_only"
    case cloudKit = "cloudkit"
}

// Account status
enum AccountStatus: String, Codable {
    case notSet = "not_set"
    case hasAccount = "has_account"
    case signedIn = "signed_in"
}

