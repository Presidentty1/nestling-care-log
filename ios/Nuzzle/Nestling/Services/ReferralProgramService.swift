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

    // MARK: - Rewards (Full Implementation)
    // Research: Dollar credit most effective (53% of programs use it)
    // Double-sided rewards essential for 3-4x higher LTV

    /// Get available rewards for the current user
    func getAvailableRewards() -> [ReferralReward] {
        var rewards: [ReferralReward] = []

        let activatedCount = getSuccessfulReferrals()

        // Monetary rewards (per successful referral who converts)
        if activatedCount >= 1 {
            // Referrer gets $10 credit per successful referral
            let creditAmount = activatedCount * 10
            rewards.append(.subscriptionCredit(amount: creditAmount))
        }

        // Milestone rewards
        if activatedCount >= 3 {
            rewards.append(.oneMonthFree)
        }
        if activatedCount >= 5 {
            rewards.append(.betaFeatureAccess)
        }
        if activatedCount >= 10 {
            rewards.append(.lifetimeDiscount)
        }

        // Badge rewards (emotional incentive)
        if activatedCount >= 1 {
            rewards.append(.helperBadge)
        }
        if activatedCount >= 3 {
            rewards.append(.superHelperBadge)
        }
        if activatedCount >= 5 {
            rewards.append(.heroBadge)
        }

        return rewards
    }

    /// Check if user has earned a specific reward
    func hasReward(_ reward: ReferralReward) -> Bool {
        return getAvailableRewards().contains(reward)
    }
    
    /// Get number of successful referrals (friend converted to paid)
    private func getSuccessfulReferrals() -> Int {
        // This would check against backend/StoreKit
        // For now, count activated referees as proxy
        return getActivatedReferees().count
    }
    
    /// Get friend reward details (what new users get)
    func getFriendReward() -> FriendReward {
        return FriendReward(
            discountPercentage: 30,
            extendedTrialDays: 14,  // vs standard 7-day
            expirationDays: 30
        )
    }
    
    /// Apply friend reward when new user signs up via referral
    func applyFriendReward(referralCode: String) async {
        // 1. Extend trial from 7 to 14 days
        // 2. Apply 30% discount to first payment
        
        logger.info("[Referral] Applying friend reward: 30% off + 14-day trial")
        
        // Track reward application
        Task {
            await Analytics.shared.log("referral_friend_reward_applied", parameters: [
                "referral_code": referralCode,
                "discount": 30,
                "extended_trial_days": 14
            ])
        }
    }
    
    /// Check if referrer should be rewarded (friend converted to paid)
    func checkAndAwardReferrerReward(referralCode: String) async {
        // When a referred friend converts to paid subscriber:
        // Award $10 credit to referrer
        
        logger.info("[Referral] Awarding $10 credit to referrer")
        
        // Track reward
        Task {
            await Analytics.shared.log("referral_reward_earned", parameters: [
                "referral_code": referralCode,
                "reward_type": "credit",
                "reward_amount": 10
            ])
        }
        
        // Apply credit to referrer's account
        // This would integrate with subscription service
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

/// Available referral rewards
enum ReferralReward: String, Codable, Equatable {
    // Monetary rewards
    case subscriptionCredit(amount: Int)
    case oneMonthFree = "one_month_free"
    case lifetimeDiscount = "lifetime_discount"
    case betaFeatureAccess = "beta_feature_access"
    
    // Emotional rewards
    case helperBadge = "helper_badge"
    case superHelperBadge = "super_helper_badge"
    case heroBadge = "hero_badge"

    var title: String {
        switch self {
        case .subscriptionCredit(let amount):
            return "$\(amount) Credit"
        case .oneMonthFree:
            return "1 Month Free"
        case .lifetimeDiscount:
            return "Lifetime 20% Discount"
        case .betaFeatureAccess:
            return "Beta Feature Access"
        case .helperBadge:
            return "Helper Badge"
        case .superHelperBadge:
            return "Super Helper Badge"
        case .heroBadge:
            return "Hero Badge"
        }
    }

    var description: String {
        switch self {
        case .subscriptionCredit(let amount):
            return "$\(amount) toward your subscription"
        case .oneMonthFree:
            return "One free month for 3 successful referrals"
        case .lifetimeDiscount:
            return "20% off forever for 10 successful referrals"
        case .betaFeatureAccess:
            return "Early access to new features"
        case .helperBadge:
            return "For helping one parent get better sleep"
        case .superHelperBadge:
            return "For helping three parents"
        case .heroBadge:
            return "For helping five parents - you're a legend!"
        }
    }

    var icon: String {
        switch self {
        case .subscriptionCredit:
            return "dollarsign.circle.fill"
        case .oneMonthFree:
            return "gift.fill"
        case .lifetimeDiscount:
            return "infinity.circle.fill"
        case .betaFeatureAccess:
            return "flask.fill"
        case .helperBadge:
            return "star.fill"
        case .superHelperBadge:
            return "star.circle.fill"
        case .heroBadge:
            return "crown.fill"
        }
    }
    
    static func == (lhs: ReferralReward, rhs: ReferralReward) -> Bool {
        switch (lhs, rhs) {
        case (.subscriptionCredit(let amt1), .subscriptionCredit(let amt2)):
            return amt1 == amt2
        case (.oneMonthFree, .oneMonthFree),
             (.lifetimeDiscount, .lifetimeDiscount),
             (.betaFeatureAccess, .betaFeatureAccess),
             (.helperBadge, .helperBadge),
             (.superHelperBadge, .superHelperBadge),
             (.heroBadge, .heroBadge):
            return true
        default:
            return false
        }
    }
}

/// Friend reward structure (what new users get)
struct FriendReward {
    let discountPercentage: Int     // 30% off first payment
    let extendedTrialDays: Int      // 14 days vs standard 7
    let expirationDays: Int         // Valid for 30 days
    
    var displayText: String {
        "\(discountPercentage)% off + \(extendedTrialDays)-day trial"
    }
}

/// Incentive structure per research
struct ReferralIncentives {
    // REFERRER rewards
    static let referrerCreditPerConversion = 10  // $10 per converted friend
    static let maxCreditsPerMonth = 5            // Cap to prevent abuse
    
    // FRIEND rewards
    static let friendDiscountPercentage = 30     // 30% off first payment
    static let friendExtendedTrialDays = 14      // vs 7-day standard
    
    // MILESTONE rewards
    static let milestoneRewards: [(referrals: Int, reward: ReferralReward)] = [
        (3, .oneMonthFree),
        (5, .betaFeatureAccess),
        (10, .lifetimeDiscount)
    ]
}

private let logger = LoggerFactory.create(category: "ReferralProgram")
