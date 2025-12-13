import Foundation
import Combine
import UserNotifications

/// Service managing the critical first 72 hours activation journey
///
/// Orchestrates push notifications, in-app guidance, and progressive unlocks
/// to ensure users experience maximum value in the first 3 days.
///
/// Journey phases:
/// - Day 0: Onboarding complete → First log (1 hour reminder) → Instant AHA
/// - Day 1: Daily summary → Partner invite → Pattern emergence
/// - Day 2: Progress tracking → Feature introduction → Prediction accuracy
/// - Day 3: Completion celebration → Weekly goals → Trial reminder
class FirstThreeDaysJourneyService: ObservableObject {
    static let shared = FirstThreeDaysJourneyService()

    @Published var currentDayMilestones: [DayMilestone] = []
    @Published var showDayTransitionCelebration = false
    @Published var journeyProgress: Double = 0.0 // 0.0 to 1.0

    enum DayMilestone: String, Codable {
        case day0_onboardingComplete
        case day0_firstLog
        case day0_instantAha
        case day1_dailySummary
        case day1_partnerInvite
        case day1_patternEmergence
        case day2_progressTracking
        case day2_featureIntro
        case day2_predictionAccuracy
        case day3_completionCelebration
        case day3_weeklyGoals
        case day3_trialReminder

        var title: String {
            switch self {
            case .day0_onboardingComplete: return "Welcome to Nestling!"
            case .day0_firstLog: return "First log complete! 🎉"
            case .day0_instantAha: return "Your first prediction"
            case .day1_dailySummary: return "Day 1 summary"
            case .day1_partnerInvite: return "Invite your partner"
            case .day1_patternEmergence: return "Patterns emerging"
            case .day2_progressTracking: return "Tracking progress"
            case .day2_featureIntro: return "New feature unlocked"
            case .day2_predictionAccuracy: return "Predictions improving"
            case .day3_completionCelebration: return "3 days complete! 🌟"
            case .day3_weeklyGoals: return "Set weekly goals"
            case .day3_trialReminder: return "Trial reminder"
            }
        }

        var description: String {
            switch self {
            case .day0_onboardingComplete: return "Let's start tracking your baby's day"
            case .day0_firstLog: return "Great job! Keep the momentum going"
            case .day0_instantAha: return "See when your baby might need a nap"
            case .day1_dailySummary: return "Review your first full day of data"
            case .day1_partnerInvite: return "Share tracking with your partner"
            case .day1_patternEmergence: return "Your baby shows sleep patterns"
            case .day2_progressTracking: return "You're building great habits"
            case .day2_featureIntro: return "Try cry analysis for fussy moments"
            case .day2_predictionAccuracy: return "Predictions are getting accurate"
            case .day3_completionCelebration: return "You've mastered the basics!"
            case .day3_weeklyGoals: return "Set goals for the week ahead"
            case .day3_trialReminder: return "Your trial ends soon"
            }
        }

        var day: Int {
            switch self {
            case .day0_onboardingComplete, .day0_firstLog, .day0_instantAha: return 0
            case .day1_dailySummary, .day1_partnerInvite, .day1_patternEmergence: return 1
            case .day2_progressTracking, .day2_featureIntro, .day2_predictionAccuracy: return 2
            case .day3_completionCelebration, .day3_weeklyGoals, .day3_trialReminder: return 3
            }
        }

        var shouldTriggerNotification: Bool {
            switch self {
            case .day0_firstLog, .day1_dailySummary, .day1_patternEmergence,
                 .day2_predictionAccuracy, .day3_trialReminder:
                return true
            default:
                return false
            }
        }

        var notificationTitle: String {
            switch self {
            case .day0_firstLog: return "Ready to log your first event?"
            case .day1_dailySummary: return "How was your first day?"
            case .day1_patternEmergence: return "Patterns are emerging!"
            case .day2_predictionAccuracy: return "Your predictions are improving"
            case .day3_trialReminder: return "Your trial is ending soon"
            default: return ""
            }
        }

        var notificationBody: String {
            switch self {
            case .day0_firstLog: return "Tap to quickly log a feed, sleep, or diaper change"
            case .day1_dailySummary: return "Check out your daily summary and see how you're doing"
            case .day1_patternEmergence: return "You've logged enough to see your baby's first patterns"
            case .day2_predictionAccuracy: return "Predictions are now within 30 minutes - that's helpful!"
            case .day3_trialReminder: return "Don't forget to upgrade to keep all your data and features"
            default: return ""
            }
        }
    }

    private let userDefaults = UserDefaults.standard
    private var onboardingCompleteDate: Date?
    private var cancellables = Set<AnyCancellable>()

    private init() {
        loadJourneyState()
        setupNotificationObservers()
    }

    // MARK: - Journey Management

    func startJourney(onboardingCompleteDate: Date = Date()) {
        self.onboardingCompleteDate = onboardingCompleteDate
        userDefaults.set(onboardingCompleteDate, forKey: "journey_start_date")

        // Mark initial milestone as complete
        completeMilestone(.day0_onboardingComplete)

        // Schedule initial notification (first log reminder)
        scheduleNotification(for: .day0_firstLog, at: onboardingCompleteDate.addingTimeInterval(60 * 60)) // 1 hour later

        // Analytics
        AnalyticsService.shared.track(event: "journey_started", properties: [
            "start_date": onboardingCompleteDate.ISO8601Format()
        ])
    }

    func completeMilestone(_ milestone: DayMilestone) {
        var completedMilestones = getCompletedMilestones()
        if !completedMilestones.contains(milestone) {
            completedMilestones.insert(milestone)
            userDefaults.set(completedMilestones.map { $0.rawValue }, forKey: "completed_milestones")

            updateJourneyProgress()

            // Trigger next milestone notifications
            triggerNextMilestone(milestone)

            // Analytics
            AnalyticsService.shared.track(event: "journey_milestone_completed", properties: [
                "milestone": milestone.rawValue,
                "day": milestone.day,
                "journey_progress": journeyProgress
            ])
        }
    }

    func isMilestoneCompleted(_ milestone: DayMilestone) -> Bool {
        return getCompletedMilestones().contains(milestone)
    }

    func getCompletedMilestones() -> Set<DayMilestone> {
        let rawValues = userDefaults.array(forKey: "completed_milestones") as? [String] ?? []
        return Set(rawValues.compactMap { DayMilestone(rawValue: $0) })
    }

    func getMilestones(for day: Int) -> [DayMilestone] {
        return DayMilestone.allCases.filter { $0.day == day }
    }

    // MARK: - Progress Tracking

    private func updateJourneyProgress() {
        let completedCount = getCompletedMilestones().count
        let totalMilestones = DayMilestone.allCases.count
        journeyProgress = Double(completedCount) / Double(totalMilestones)
    }

    // MARK: - Notification Scheduling

    func scheduleNotification(for milestone: DayMilestone, at date: Date) {
        guard milestone.shouldTriggerNotification else { return }

        let content = UNMutableNotificationContent()
        content.title = milestone.notificationTitle
        content.body = milestone.notificationBody
        content.sound = .default
        content.categoryIdentifier = "JOURNEY_MILESTONE"

        // Add deep link for journey milestone
        content.userInfo = [
            "journey_milestone": milestone.rawValue,
            "deepLink": "nestling://journey/\(milestone.rawValue)"
        ]

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "journey_\(milestone.rawValue)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule journey notification: \(error)")
            } else {
                print("Scheduled journey notification for \(milestone.rawValue)")
            }
        }
    }

    // MARK: - Journey Flow Logic

    private func triggerNextMilestone(_ completedMilestone: DayMilestone) {
        switch completedMilestone {
        case .day0_onboardingComplete:
            // Schedule first log reminder for 1 hour later
            if let startDate = onboardingCompleteDate {
                scheduleNotification(for: .day0_firstLog, at: startDate.addingTimeInterval(60 * 60))
            }

        case .day0_firstLog:
            // Show instant AHA moment
            completeMilestone(.day0_instantAha)

            // Schedule day 1 summary for next morning (8 AM)
            if let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) {
                var components = Calendar.current.dateComponents([.year, .month, .day], from: tomorrow)
                components.hour = 8
                if let morningDate = Calendar.current.date(from: components) {
                    scheduleNotification(for: .day1_dailySummary, at: morningDate)
                }
            }

        case .day1_dailySummary:
            completeMilestone(.day1_partnerInvite)
            completeMilestone(.day1_patternEmergence)

            // Schedule pattern emergence notification for evening
            if let todayEvening = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) {
                if todayEvening > Date() { // Only if it's still today
                    scheduleNotification(for: .day1_patternEmergence, at: todayEvening)
                }
            }

        case .day2_progressTracking:
            completeMilestone(.day2_featureIntro)
            completeMilestone(.day2_predictionAccuracy)

            // Schedule prediction accuracy notification
            scheduleNotification(for: .day2_predictionAccuracy, at: Date().addingTimeInterval(2 * 60 * 60)) // 2 hours from now

        case .day3_completionCelebration:
            completeMilestone(.day3_weeklyGoals)
            completeMilestone(.day3_trialReminder)

            // Schedule trial reminder (if applicable)
            if let trialEndDate = getTrialEndDate() {
                scheduleNotification(for: .day3_trialReminder, at: trialEndDate.addingTimeInterval(-24 * 60 * 60)) // 1 day before
            }

        default:
            break
        }
    }

    // MARK: - State Management

    private func loadJourneyState() {
        if let startDate = userDefaults.object(forKey: "journey_start_date") as? Date {
            onboardingCompleteDate = startDate
            updateJourneyProgress()
        }
    }

    private func setupNotificationObservers() {
        // Observe when notifications are tapped to complete journey milestones
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleJourneyNotificationTap(_:)),
            name: NSNotification.Name("JourneyNotificationTapped"),
            object: nil
        )
    }

    @objc private func handleJourneyNotificationTap(_ notification: Notification) {
        if let milestoneRaw = notification.userInfo?["milestone"] as? String,
           let milestone = DayMilestone(rawValue: milestoneRaw) {
            completeMilestone(milestone)
        }
    }

    // MARK: - Trial Integration

    private func getTrialEndDate() -> Date? {
        // Integrate with ProSubscriptionService to get trial end date
        // For now, return nil (will be implemented when trial system is ready)
        return nil
    }

    // MARK: - Analytics

    func trackJourneyProgress() {
        AnalyticsService.shared.track(event: "journey_progress", properties: [
            "progress": journeyProgress,
            "completed_milestones": getCompletedMilestones().count,
            "current_day": currentDay(),
            "days_since_start": daysSinceJourneyStart()
        ])
    }

    private func currentDay() -> Int {
        guard let startDate = onboardingCompleteDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
    }

    private func daysSinceJourneyStart() -> Int {
        return currentDay()
    }
}
