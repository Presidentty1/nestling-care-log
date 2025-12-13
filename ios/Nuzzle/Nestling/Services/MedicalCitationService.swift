import Foundation

/// Service for providing medical citations and evidence-based backing for app features
///
/// All citations are sourced from American Academy of Pediatrics (AAP) guidelines
/// and other reputable pediatric sources. Citations include stable URLs and
/// last-reviewed dates for accuracy.
///
/// Usage:
/// ```swift
/// let citation = MedicalCitationService.shared.citation(for: .napPrediction)
/// // Returns: AAP wake window guidelines citation
/// ```
class MedicalCitationService {
    static let shared = MedicalCitationService()

    enum Feature {
        case napPrediction
        case wakeWindow
        case sleepDuration
        case feedSpacing
        case diaperFrequency
        case milestoneTracking
    }

    struct MedicalCitation {
        let source: String
        let title: String
        let url: String
        let summary: String
        let lastReviewed: Date

        var displayText: String {
            return "\(source): \(title)"
        }

        var shortSummary: String {
            return summary
        }
    }

    private init() {}

    /// Get citation for a specific feature
    func citation(for feature: Feature) -> MedicalCitation {
        switch feature {
        case .napPrediction, .wakeWindow:
            return wakeWindowCitation
        case .sleepDuration:
            return sleepDurationCitation
        case .feedSpacing:
            return feedSpacingCitation
        case .diaperFrequency:
            return diaperFrequencyCitation
        case .milestoneTracking:
            return milestoneTrackingCitation
        }
    }

    /// Get all available citations
    func allCitations() -> [MedicalCitation] {
        return [
            wakeWindowCitation,
            sleepDurationCitation,
            feedSpacingCitation,
            diaperFrequencyCitation,
            milestoneTrackingCitation
        ]
    }

    // MARK: - Citations Database

    /// Wake window and nap prediction citation
    private let wakeWindowCitation = MedicalCitation(
        source: "American Academy of Pediatrics",
        title: "Sleep Duration and Wake Windows",
        url: "https://www.aap.org/en/patient-care/sleep/",
        summary: "Age-appropriate wake windows prevent overtiredness and improve sleep quality. Newborns need 45-60 minute wake windows, increasing gradually with age.",
        lastReviewed: Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 15))!
    )

    /// Sleep duration guidelines citation
    private let sleepDurationCitation = MedicalCitation(
        source: "American Academy of Pediatrics",
        title: "Recommended Sleep Duration by Age",
        url: "https://www.aap.org/en/patient-care/sleep/",
        summary: "Newborns need 14-17 hours daily, decreasing gradually. Consistent sleep patterns support brain development and emotional regulation.",
        lastReviewed: Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 15))!
    )

    /// Feed spacing and hunger cues citation
    private let feedSpacingCitation = MedicalCitation(
        source: "American Academy of Pediatrics",
        title: "Infant Feeding Guidelines",
        url: "https://www.aap.org/en/patient-care/healthy-growth-and-nutrition/",
        summary: "Responsive feeding based on hunger cues supports healthy growth. Feed spacing increases naturally as babies develop.",
        lastReviewed: Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 15))!
    )

    /// Diaper frequency and hydration citation
    private let diaperFrequencyCitation = MedicalCitation(
        source: "American Academy of Pediatrics",
        title: "Infant Hydration and Elimination",
        url: "https://www.aap.org/en/patient-care/healthy-growth-and-nutrition/",
        summary: "Newborns typically have 6-8 wet diapers daily. Monitoring diaper patterns helps detect dehydration early.",
        lastReviewed: Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 15))!
    )

    /// Milestone tracking citation
    private let milestoneTrackingCitation = MedicalCitation(
        source: "Centers for Disease Control and Prevention (CDC)",
        title: "Developmental Milestones",
        url: "https://www.cdc.gov/ncbddd/actearly/milestones/index.html",
        summary: "Tracking developmental milestones helps identify potential delays early. Regular monitoring supports optimal development.",
        lastReviewed: Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 15))!
    )

    // MARK: - Citation Formatting

    /// Format citation for display in tooltips
    func formatForTooltip(_ citation: MedicalCitation) -> String {
        return """
        \(citation.source)
        \(citation.summary)

        Source: \(citation.url)
        Last reviewed: \(citation.lastReviewed.formatted(date: .abbreviated, time: .omitted))
        """
    }

    /// Format citation for compact display (badges, etc.)
    func formatForBadge(_ citation: MedicalCitation) -> String {
        return citation.source
    }

    /// Get disclaimer text for all medical content
    func medicalDisclaimer() -> String {
        return "Not medical advice. Consult your pediatrician for personalized guidance."
    }

    // MARK: - Analytics

    func trackCitationViewed(feature: Feature, context: String) {
        let citation = self.citation(for: feature)
        AnalyticsService.shared.track(event: "medical_citation_viewed", properties: [
            "feature": String(describing: feature),
            "context": context,
            "source": citation.source,
            "url": citation.url
        ])
    }

    func trackCitationTooltipShown(feature: Feature) {
        AnalyticsService.shared.track(event: "medical_citation_tooltip_shown", properties: [
            "feature": String(describing: feature)
        ])
    }
}