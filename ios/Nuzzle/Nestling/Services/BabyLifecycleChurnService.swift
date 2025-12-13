import Foundation

/// Baby lifecycle churn management service
/// Research: Baby tracking apps face unique churn as baby grows
/// Usage naturally declines at 0-12 months
///
/// Strategy: Proactive engagement based on baby age
/// - 0-3 months: High engagement, build habit
/// - 4-6 months: Transition period, introduce new features
/// - 7-12 months: High churn risk, retention interventions
/// - 12+ months: Critical churn, "graduation" offers
@MainActor
class BabyLifecycleChurnService: ObservableObject {
    static let shared = BabyLifecycleChurnService()
    
    @Published var currentLifecycleStage: LifecycleStage?
    @Published var suggestedIntervention: ChurnIntervention?
    
    private init() {}
    
    // MARK: - Lifecycle Analysis
    
    /// Analyze baby's age and determine churn risk
    func analyzeLifecycle(for baby: Baby) -> LifecycleAnalysis {
        let ageInMonths = baby.ageInMonths
        
        let stage: LifecycleStage
        let churnRisk: ChurnRisk
        let reason: String
        let interventions: [ChurnIntervention]
        
        switch ageInMonths {
        case 0...3:
            stage = .newborn
            churnRisk = .low
            reason = "High need period - parents are engaged"
            interventions = [.featureDiscovery, .habitBuilding]
            
        case 4...6:
            stage = .infant
            churnRisk = .medium
            reason = "Sleep patterns stabilizing"
            interventions = [.growthMilestones, .feedingSchedules]
            
        case 7...12:
            stage = .baby
            churnRisk = .high
            reason = "Baby sleeps through the night now"
            interventions = [
                .toddlerFeatures,
                .pauseOffer,
                .mealPlanning,
                .milestoneTracking
            ]
            
        default:  // 12+ months
            stage = .toddler
            churnRisk = .critical
            reason = "Don't need baby tracking anymore"
            interventions = [
                .memoriesPlan,
                .digitalBabyBook,
                .graduation,
                .nextStageAppPartnership
            ]
        }
        
        return LifecycleAnalysis(
            stage: stage,
            churnRisk: churnRisk,
            reason: reason,
            recommendedInterventions: interventions
        )
    }
    
    // MARK: - Proactive Communication
    
    /// Get proactive message for current lifecycle stage
    func getProactiveMessage(for baby: Baby) -> LifecycleMessage? {
        let ageInMonths = baby.ageInMonths
        let analysis = analyzeLifecycle(for: baby)
        
        // Check if user has seen this message already
        let messageKey = "lifecycle_message_\(ageInMonths)mo"
        guard !UserDefaults.standard.bool(forKey: messageKey) else {
            return nil
        }
        
        let message: LifecycleMessage?
        
        switch analysis.stage {
        case .newborn:
            // No proactive message - focus on delivery
            message = nil
            
        case .infant:
            // 6-month milestone
            if ageInMonths == 6 {
                message = LifecycleMessage(
                    title: "\(baby.name) is 6 months old! 🎉",
                    body: """
                    Congrats on 6 months with \(baby.name)!
                    
                    Sleep patterns are probably stabilizing now. But tracking is still valuable for:
                    • Solid food introduction timing
                    • Growth milestone monitoring
                    • Pattern changes during teething
                    
                    Plus: Keep your complete 6-month history for the pediatrician.
                    """,
                    cta: "Continue Tracking",
                    alternativeAction: "Pause for now",
                    type: .educational
                )
            } else {
                message = nil
            }
            
        case .baby:
            // 9-month proactive retention
            if ageInMonths == 9 {
                message = LifecycleMessage(
                    title: "As \(baby.name) grows...",
                    body: """
                    \(baby.name)'s changing! Here's what to track now:
                    
                    • Solid food introduction and reactions
                    • New motor milestones (crawling, standing)
                    • Sleep regression patterns
                    • Teething symptoms and timing
                    
                    Your tracking history helps spot developmental patterns.
                    """,
                    cta: "See new features",
                    alternativeAction: nil,
                    type: .featureIntroduction
                )
            } else {
                message = nil
            }
            
        case .toddler:
            // 12-month graduation offer
            if ageInMonths == 12 {
                message = LifecycleMessage(
                    title: "\(baby.name) is 1 year old! 🎂",
                    body: """
                    What an amazing first year!
                    
                    You've tracked \(baby.name)'s entire journey. Want to keep these memories forever?
                    
                    Try our "Memories" plan:
                    • Beautiful digital baby book
                    • Photo storage
                    • Milestone highlights
                    • Just $2.99/month
                    """,
                    cta: "View Memories Plan",
                    alternativeAction: "Export my data",
                    type: .graduation
                )
            } else {
                message = nil
            }
        }
        
        // Mark message as seen
        if message != nil {
            UserDefaults.standard.set(true, forKey: messageKey)
        }
        
        return message
    }
    
    // MARK: - Churn Prevention Actions
    
    /// Execute intervention for high-risk users
    func executeIntervention(_ intervention: ChurnIntervention, for baby: Baby) async {
        switch intervention {
        case .featureDiscovery:
            // Show feature discovery cards
            await sendFeatureDiscoveryEmail(baby: baby)
            
        case .habitBuilding:
            // Encourage consistent tracking
            logger.info("[Lifecycle] Encouraging habit building")
            
        case .growthMilestones:
            // Highlight milestone tracking features
            await sendGrowthMilestoneEmail(baby: baby)
            
        case .feedingSchedules:
            // Introduce feeding schedule insights
            logger.info("[Lifecycle] Introducing feeding schedules")
            
        case .toddlerFeatures:
            // Show toddler-relevant features
            await sendToddlerFeaturesEmail(baby: baby)
            
        case .pauseOffer:
            // Offer subscription pause
            logger.info("[Lifecycle] Offering subscription pause")
            
        case .mealPlanning:
            // Introduce meal planning features
            logger.info("[Lifecycle] Introducing meal planning")
            
        case .milestoneTracking:
            // Highlight milestone tracking
            logger.info("[Lifecycle] Highlighting milestone tracking")
            
        case .memoriesPlan:
            // Offer memories/photo storage plan
            await offerMemoriesPlan(baby: baby)
            
        case .digitalBabyBook:
            // Generate and offer digital baby book
            await generateDigitalBabyBook(baby: baby)
            
        case .graduation:
            // Graduation ceremony with export
            await graduationCeremony(baby: baby)
            
        case .nextStageAppPartnership:
            // Partner with toddler apps
            logger.info("[Lifecycle] Suggesting next-stage apps")
        }
        
        // Track intervention
        await Analytics.shared.log("lifecycle_intervention_executed", parameters: [
            "intervention": intervention.rawValue,
            "baby_age_months": baby.ageInMonths
        ])
    }
    
    // MARK: - Email Communications
    
    private func sendFeatureDiscoveryEmail(baby: Baby) async {
        logger.info("[Lifecycle] Would send feature discovery email for \(baby.name)")
        // Would integrate with email service
    }
    
    private func sendGrowthMilestoneEmail(baby: Baby) async {
        logger.info("[Lifecycle] Would send growth milestone email for \(baby.name)")
    }
    
    private func sendToddlerFeaturesEmail(baby: Baby) async {
        logger.info("[Lifecycle] Would send toddler features email for \(baby.name)")
    }
    
    private func offerMemoriesPlan(baby: Baby) async {
        logger.info("[Lifecycle] Would offer memories plan for \(baby.name)")
    }
    
    private func generateDigitalBabyBook(baby: Baby) async {
        logger.info("[Lifecycle] Would generate digital baby book for \(baby.name)")
    }
    
    private func graduationCeremony(baby: Baby) async {
        logger.info("[Lifecycle] Would show graduation ceremony for \(baby.name)")
    }
}

// MARK: - Models

enum LifecycleStage: String {
    case newborn  // 0-3 months
    case infant   // 4-6 months
    case baby     // 7-12 months
    case toddler  // 12+ months
    
    var displayName: String {
        rawValue.capitalized
    }
}

enum ChurnRisk: String {
    case low
    case medium
    case high
    case critical
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "orange"
        case .critical: return "red"
        }
    }
}

enum ChurnIntervention: String, CaseIterable {
    case featureDiscovery = "feature_discovery"
    case habitBuilding = "habit_building"
    case growthMilestones = "growth_milestones"
    case feedingSchedules = "feeding_schedules"
    case toddlerFeatures = "toddler_features"
    case pauseOffer = "pause_offer"
    case mealPlanning = "meal_planning"
    case milestoneTracking = "milestone_tracking"
    case memoriesPlan = "memories_plan"
    case digitalBabyBook = "digital_baby_book"
    case graduation = "graduation"
    case nextStageAppPartnership = "next_stage_app"
    
    var displayName: String {
        switch self {
        case .featureDiscovery: return "Feature Discovery"
        case .habitBuilding: return "Habit Building"
        case .growthMilestones: return "Growth Milestones"
        case .feedingSchedules: return "Feeding Schedules"
        case .toddlerFeatures: return "Toddler Features"
        case .pauseOffer: return "Pause Subscription"
        case .mealPlanning: return "Meal Planning"
        case .milestoneTracking: return "Milestone Tracking"
        case .memoriesPlan: return "Memories Plan"
        case .digitalBabyBook: return "Digital Baby Book"
        case .graduation: return "Graduation Ceremony"
        case .nextStageAppPartnership: return "Next Stage App"
        }
    }
}

struct LifecycleAnalysis {
    let stage: LifecycleStage
    let churnRisk: ChurnRisk
    let reason: String
    let recommendedInterventions: [ChurnIntervention]
}

struct LifecycleMessage {
    let title: String
    let body: String
    let cta: String
    let alternativeAction: String?
    let type: MessageType
    
    enum MessageType {
        case educational
        case featureIntroduction
        case graduation
        case retention
    }
}

private let logger = LoggerFactory.create(category: "LifecycleChurn")
