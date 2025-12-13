import Foundation

/// Helper for localization support and string management
/// Prepares the app for international expansion
struct LocalizationHelper {
    /// Get localized string with fallback to English
    static func localizedString(_ key: String, tableName: String? = nil, bundle: Bundle = .main, value: String = "", comment: String = "") -> String {
        // For now, return the key as-is (English)
        // In production, this would use NSLocalizedString
        return key

        // Future implementation:
        // return NSLocalizedString(key, tableName: tableName, bundle: bundle, value: value, comment: comment)
    }

    /// Get localized string with format arguments
    static func localizedString(_ key: String, _ args: CVarArg...) -> String {
        let format = localizedString(key)
        return String(format: format, arguments: args)
    }

    /// Check if localization is available for current language
    static var isLocalizationAvailable: Bool {
        // For now, assume only English is available
        // In future, check if current locale has translations
        return true
    }

    /// Current app language
    static var currentLanguage: String {
        return Locale.current.language.languageCode?.identifier ?? "en"
    }

    /// Supported languages
    static var supportedLanguages: [String] {
        // For now, only English
        // Future: return ["en", "es", "fr", "de"]
        return ["en"]
    }
}

// MARK: - String Extensions

extension String {
    /// Localized version of the string
    var localized: String {
        return LocalizationHelper.localizedString(self)
    }

    /// Localized version with format arguments
    func localized(_ args: CVarArg...) -> String {
        return LocalizationHelper.localizedString(self, args)
    }
}

// MARK: - Common Localized Keys

extension LocalizationHelper {
    // Error messages
    static let errorGenericTitle = "Something went wrong"
    static let errorGenericMessage = "We couldn't complete that action. Please try again."
    static let errorNetworkTitle = "Connection issue"
    static let errorNetworkMessage = "Please check your internet connection and try again."

    // Success messages
    static let savedMessage = "Saved!"
    static let deletedMessage = "Removed"

    // Common actions
    static let cancel = "Cancel"
    static let ok = "OK"
    static let retry = "Retry"
    static let save = "Save"
    static let delete = "Delete"

    // Time-related
    static func timeAgo(hours: Int) -> String {
        if hours == 1 {
            return "1 hour ago"
        } else {
            return "\(hours) hours ago"
        }
    }

    static func timeFromNow(hours: Int) -> String {
        if hours == 1 {
            return "in 1 hour"
        } else {
            return "in \(hours) hours"
        }
    }
}