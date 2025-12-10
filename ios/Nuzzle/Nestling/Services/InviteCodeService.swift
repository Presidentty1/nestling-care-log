import Foundation

/// Service for managing caregiver invite codes
/// For now, uses local storage. In production, this would sync with backend.
class InviteCodeService {
    static let shared = InviteCodeService()
    
    private let userDefaults = UserDefaults.standard
    private let inviteCodeKeyPrefix = "invite_code_"
    private let sharedBabyKeyPrefix = "shared_baby_"
    
    private init() {}
    
    /// Store an invite code for a baby
    func storeInviteCode(_ code: String, for babyId: UUID) {
        userDefaults.set(code, forKey: "\(inviteCodeKeyPrefix)\(babyId.uuidString)")
    }
    
    /// Get invite code for a baby
    func getInviteCode(for babyId: UUID) -> String? {
        return userDefaults.string(forKey: "\(inviteCodeKeyPrefix)\(babyId.uuidString)")
    }
    
    /// Validate and accept an invite code
    /// Returns the baby ID if code is valid, nil otherwise
    func acceptInviteCode(_ code: String) -> UUID? {
        // Search for baby with this invite code
        // In production, this would query a backend
        // For now, search local storage
        let allKeys = userDefaults.dictionaryRepresentation().keys
        for key in allKeys {
            if key.hasPrefix(inviteCodeKeyPrefix) {
                if let storedCode = userDefaults.string(forKey: key), storedCode == code {
                    // Extract baby ID from key
                    let babyIdString = String(key.dropFirst(inviteCodeKeyPrefix.count))
                    if let babyId = UUID(uuidString: babyIdString) {
                        // Store that this user has access to this baby
                        var sharedBabies = getSharedBabyIds()
                        if !sharedBabies.contains(babyId) {
                            sharedBabies.append(babyId)
                            userDefaults.set(sharedBabies.map { $0.uuidString }, forKey: "shared_baby_ids")
                        }
                        return babyId
                    }
                }
            }
        }
        return nil
    }
    
    /// Get list of baby IDs this user has access to via invites
    func getSharedBabyIds() -> [UUID] {
        guard let babyIdStrings = userDefaults.array(forKey: "shared_baby_ids") as? [String] else {
            return []
        }
        return babyIdStrings.compactMap { UUID(uuidString: $0) }
    }
    
    /// Check if user has access to a baby via invite
    func hasAccessToBaby(_ babyId: UUID) -> Bool {
        return getSharedBabyIds().contains(babyId)
    }
}






