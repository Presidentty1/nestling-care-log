import Foundation

/// Service for formatting insights and patterns for sharing to mom groups
///
/// Creates authentic, helpful content optimized for:
/// - WhatsApp groups
/// - Facebook parenting groups
/// - Instagram stories/captions
/// - SMS/text message threads
///
/// Focus: "Here's what I learned about my baby's sleep..."
class ShareFormattingService {
    static let shared = ShareFormattingService()

    private init() {}

    // MARK: - Mom Group Sharing

    /// Format a sleep pattern insight for mom groups
    func formatSleepPatternForMomGroup(
        pattern: String,
        confidence: Double,
        babyName: String? = nil
    ) -> String {
        let nameText = babyName.map { "'s" } ?? " baby's"
        let confidenceEmoji = confidence >= 0.8 ? "🎯" : confidence >= 0.6 ? "📊" : "💡"

        return """
        \(confidenceEmoji) Sleep pattern I noticed:

        \(pattern)

        \(babyName.map { "From tracking \($0)'s sleep" } ?? "From tracking my baby's sleep") with Nestling app 📱

        #BabySleep #ParentingTips
        """
    }

    /// Format a feeding pattern insight for mom groups
    func formatFeedingPatternForMomGroup(
        pattern: String,
        babyName: String? = nil
    ) -> String {
        let nameText = babyName.map { "'s" } ?? " baby's"

        return """
        💡 Feeding tip I learned:

        \(pattern)

        \(babyName.map { "From tracking \($0)'s feeds" } ?? "From tracking my baby's feeds") with Nestling app 🍼

        #BabyFeeding #ParentingTips
        """
    }

    /// Format a nap prediction insight for mom groups
    func formatNapPredictionForMomGroup(
        prediction: String,
        accuracy: String? = nil,
        babyName: String? = nil
    ) -> String {
        let accuracyText = accuracy.map { " (\($0) accuracy)" } ?? ""
        let nameText = babyName.map { "'s" } ?? " baby's"

        return """
        😴 Nap prediction that worked:

        \(prediction)\(accuracyText)

        \(babyName.map { "From Nestling's predictions for \($0)" } ?? "From Nestling app predictions") 📱

        #BabyNaps #ParentingHacks
        """
    }

    /// Format a general parenting insight for mom groups
    func formatGeneralInsightForMomGroup(
        insight: String,
        category: String,
        babyName: String? = nil
    ) -> String {
        let emoji = categoryEmoji(for: category)
        let nameText = babyName.map { "'s" } ?? " baby's"

        return """
        \(emoji) Parenting insight:

        \(insight)

        \(babyName.map { "From tracking \($0)\(nameText) \(category.lowercased())" } ?? "From tracking my baby's \(category.lowercased())") with Nestling app 📱

        #ParentingTips #Baby\((category.capitalized))
        """
    }

    /// Format a milestone achievement for mom groups
    func formatMilestoneForMomGroup(
        milestone: String,
        achievement: String,
        babyName: String? = nil
    ) -> String {
        let nameText = babyName.map { " for \(babyName!)" } ?? ""

        return """
        🎉 Milestone reached\(nameText)!

        \(achievement)

        Tracking progress with Nestling app 📱

        #BabyMilestones #ParentingJourney
        """
    }

    // MARK: - Social Media Formats

    /// Format for Instagram caption (more visual, hashtags focused)
    func formatForInstagram(
        insight: String,
        category: String,
        babyName: String? = nil
    ) -> String {
        let emoji = categoryEmoji(for: category)
        let nameText = babyName.map { "'s" } ?? " baby's"

        return """
        \(emoji) \(insight)

        \(babyName.map { "From tracking \($0)\(nameText) \(category.lowercased())" } ?? "From tracking my baby's \(category.lowercased())") ✨

        #NestlingApp #BabyTracker #Parenting #Baby\(category.capitalized) #NewMom #NewDad #ParentingLife #BabyDevelopment #SleepTraining #FeedingJourney
        """
    }

    /// Format for Twitter/thread (concise, conversational)
    func formatForTwitter(
        insight: String,
        category: String,
        babyName: String? = nil
    ) -> String {
        let emoji = categoryEmoji(for: category)

        return """
        \(emoji) Baby \(category.lowercased()) insight I learned:

        \(insight)

        Tracking with @Nestling app has been a game changer! 📱 #ParentingTips
        """
    }

    // MARK: - Helper Methods

    private func categoryEmoji(for category: String) -> String {
        switch category.lowercased() {
        case "sleep", "nap":
            return "😴"
        case "feed", "feeding":
            return "🍼"
        case "diaper":
            return "🧷"
        case "cry", "crying":
            return "😢"
        case "growth", "milestone":
            return "📏"
        default:
            return "💡"
        }
    }

    /// Get the appropriate sharing format for a given context
    func getFormattedShare(
        insight: String,
        category: String,
        platform: SharePlatform = .momGroup,
        babyName: String? = nil
    ) -> String {
        switch platform {
        case .momGroup:
            return formatGeneralInsightForMomGroup(
                insight: insight,
                category: category,
                babyName: babyName
            )
        case .instagram:
            return formatForInstagram(
                insight: insight,
                category: category,
                babyName: babyName
            )
        case .twitter:
            return formatForTwitter(
                insight: insight,
                category: category,
                babyName: babyName
            )
        }
    }

    enum SharePlatform {
        case momGroup  // WhatsApp/Facebook groups
        case instagram // Instagram posts/stories
        case twitter   // Twitter threads
    }
}