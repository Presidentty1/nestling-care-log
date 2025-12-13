import Foundation

/// Referral program service for tracking invites and rewards
///
/// Stage A (Month 1): Attribution + emotional framing only
/// - Track referral links and invite acceptance
/// - Lightweight rewards (badges, templates) - no billing dependencies
/// - Focus on validating referral behavior before adding monetary incentives
///
/// Stage B (Month 2+): Add subscription-linked rewards if desired
class ReferralProgramService {
    static let shared = ReferralProgramService()

    private let userDefaults = UserDefaults.standard

    // MARK: - Referral Link Generation

    /// Generate a unique referral link for the current user
    func generateReferralLink(for userId: String) -> URL? {
        let baseURL = "https://nestling.app/referral"
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "ref", value: userId),
            URLQueryItem(name: "source", value: "ios")
        ]
        return components?.url
    }

    /// Generate a short referral code for easier sharing
    func generateReferralCode(for userId: String) -> String {
        // Create a short, readable code from user ID hash
        let hash = abs(userId.hashValue)
        let adjectives = ["Happy", "Sleepy", "Cuddly", "Tiny", "Sweet"]
        let nouns = ["Panda", "Owl", "Star", "Moon", "Cloud"]

        let adjectiveIndex = hash % adjectives.count
        let nounIndex = (hash / adjectives.count) % nouns.count

        return "\(adjectives[adjectiveIndex])\(nouns[nounIndex])"
    }

    // MARK: - Invite Tracking

    /// Track when a referral link is shared
    func trackLinkShared(channel: String, referralCode: String) {
        let event: [String: Any] = [
            "channel": channel,
            "referral_code": referralCode,
            "timestamp": Date().timeIntervalSince1970
        ]

        var sharedLinks = getSharedLinks()
        sharedLinks.append(event)

        // Keep only last 100 shares to prevent unbounded growth
        if sharedLinks.count > 100 {
            sharedLinks = Array(sharedLinks.suffix(100))
        }

        userDefaults.set(sharedLinks, forKey: "shared_referral_links")
        AnalyticsService.shared.logReferralLinkShared(channel: channel)
    }

    /// Track when someone accepts an invite via referral link
    func trackInviteAccepted(referralCode: String) {
        // In a real app, this would validate the referral code and credit the referrer
        // For now, just track the acceptance
        AnalyticsService.shared.logReferralInviteAccepted(referralCode: referralCode)

        // Store for potential future reward claiming
        var acceptedInvites = getAcceptedInvites()
        acceptedInvites.insert(referralCode)

        userDefaults.set(Array(acceptedInvites), forKey: "accepted_referral_invites")
    }

    /// Track when a referred user completes their first log
    func trackRefereeActivated(referralCode: String) {
        AnalyticsService.shared.logReferralRefereeActivated(referralCode: referralCode)

        // Mark as activated
        var activatedReferees = getActivatedReferees()
        activatedReferees.insert(referralCode)

        userDefaults.set(Array(activatedReferees), forKey: "activated_referral_referees")

        // TODO: In Stage B, trigger reward delivery here
    }

    // MARK: - Rewards (Stage A - Lightweight)

    /// Get available rewards for the current user
    func getAvailableRewards() -> [ReferralReward] {
        var rewards: [ReferralReward] = []

        let activatedCount = getActivatedReferees().count

        // Badge rewards
        if activatedCount >= 1 {
            rewards.append(.helperBadge)
        }
        if activatedCount >= 3 {
            rewards.append(.superHelperBadge)
        }
        if activatedCount >= 5 {
            rewards.append(.heroBadge)
        }

        // Template unlocks
        if activatedCount >= 2 {
            rewards.append(.extraMilestoneTemplates)
        }

        return rewards
    }

    /// Check if user has earned a specific reward
    func hasReward(_ reward: ReferralReward) -> Bool {
        return getAvailableRewards().contains(reward)
    }

    // MARK: - Analytics

    private func getSharedLinks() -> [[String: Any]] {
        return userDefaults.array(forKey: "shared_referral_links") as? [[String: Any]] ?? []
    }

    private func getAcceptedInvites() -> Set<String> {
        let array = userDefaults.array(forKey: "accepted_referral_invites") as? [String] ?? []
        return Set(array)
    }

    private func getActivatedReferees() -> Set<String> {
        let array = userDefaults.array(forKey: "activated_referral_referees") as? [String] ?? []
        return Set(array)
    }

    // MARK: - Copy/Labels

    func getReferralHeadline() -> String {
        return "Know another exhausted parent?"
    }

    func getReferralSubheadline() -> String {
        return "Share Nestling so they can track once and get calmer nights sooner."
    }

    func getReferralBenefit() -> String {
        return "You'll unlock a badge when they start logging."
    }

    func getShareText(babyName: String? = nil) -> String {
        let nameText = babyName.map { " for \($0)" } ?? ""
        return "Check out Nestling - it's helped me track my baby's sleep\(nameText)! 📱 https://nestling.app"
    }
}

/// Available referral rewards (Stage A - lightweight, no billing)
enum ReferralReward: String, Codable {
    case helperBadge = "helper_badge"
    case superHelperBadge = "super_helper_badge"
    case heroBadge = "hero_badge"
    case extraMilestoneTemplates = "extra_milestone_templates"

    var title: String {
        switch self {
        case .helperBadge: return "Helper Badge"
        case .superHelperBadge: return "Super Helper Badge"
        case .heroBadge: return "Hero Badge"
        case .extraMilestoneTemplates: return "Extra Templates"
        }
    }

    var description: String {
        switch self {
        case .helperBadge: return "For helping one parent get better sleep"
        case .superHelperBadge: return "For helping three parents"
        case .heroBadge: return "For helping five parents - you're a legend!"
        case .extraMilestoneTemplates: return "Unlock additional milestone card designs"
        }
    }

    var icon: String {
        switch self {
        case .helperBadge: return "star.fill"
        case .superHelperBadge: return "star.circle.fill"
        case .heroBadge: return "crown.fill"
        case .extraMilestoneTemplates: return "paintbrush.fill"
        }
    }
}