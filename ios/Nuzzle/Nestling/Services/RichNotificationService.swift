import Foundation
import UserNotifications
import SwiftUI
import UIKit

/// Service for creating rich notifications with attachments, images, and enhanced content
final class RichNotificationService {
    static let shared = RichNotificationService()
    
    private let center = UNUserNotificationCenter.current()
    private let fileManager = FileManager.default
    
    private init() {}
    
    // MARK: - Attachment Creation
    
    /// Create a notification attachment from a local image
    func createAttachment(
        from image: UIImage,
        identifier: String = UUID().uuidString
    ) -> UNNotificationAttachment? {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            logger.debug("Failed to create JPEG data from image")
            return nil
        }
        
        let temporaryDirectory = fileManager.temporaryDirectory
        let fileURL = temporaryDirectory.appendingPathComponent("\(identifier).jpg")
        
        do {
            try data.write(to: fileURL)
            let attachment = try UNNotificationAttachment(
                identifier: identifier,
                url: fileURL,
                options: [UNNotificationAttachmentOptionsTypeHintKey: "public.jpeg"]
            )
            return attachment
        } catch {
            logger.debug("Failed to create notification attachment: \(error)")
            return nil
        }
    }
    
    /// Create a notification attachment from a SwiftUI view (rendered to image)
    @MainActor
    func createAttachment<Content: View>(
        from view: Content,
        size: CGSize = CGSize(width: 1280, height: 800),
        identifier: String = UUID().uuidString
    ) -> UNNotificationAttachment? {
        let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height))
        renderer.scale = 2.0 // Retina
        
        guard let uiImage = renderer.uiImage else {
            logger.debug("Failed to render SwiftUI view to image")
            return nil
        }
        
        return createAttachment(from: uiImage, identifier: identifier)
    }
    
    // MARK: - Rich Notifications
    
    /// Schedule a milestone celebration notification with visual attachment
    @MainActor
    func scheduleMilestoneNotification(
        title: String,
        body: String,
        babyName: String,
        milestoneType: MilestoneType,
        deliveryTime: Date? = nil
    ) {
        guard PolishFeatureFlags.shared.richNotificationsEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "MILESTONE"
        content.userInfo = [
            "deepLink": "nestling://open/home",
            "milestone_type": milestoneType.rawValue
        ]
        
        // Create visual badge for milestone
        if let attachment = createMilestoneBadgeAttachment(type: milestoneType, babyName: babyName) {
            content.attachments = [attachment]
        }
        
        let trigger: UNNotificationTrigger
        if let deliveryTime = deliveryTime {
            let interval = max(1, deliveryTime.timeIntervalSinceNow)
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        } else {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        }
        
        let request = UNNotificationRequest(
            identifier: "milestone_\(milestoneType.rawValue)_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                logger.debug("Failed to schedule milestone notification: \(error)")
            }
        }
    }
    
    /// Schedule a weekly summary notification with chart attachment
    @MainActor
    func scheduleWeeklySummaryNotification(
        babyName: String,
        weekNumber: Int,
        sleepData: WeeklyDataSummary,
        feedData: WeeklyDataSummary,
        deliveryTime: Date? = nil
    ) {
        guard PolishFeatureFlags.shared.richNotificationsEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Week \(weekNumber) with \(babyName) 📊"
        
        // Build summary body
        let sleepTrend = sleepData.trend >= 0 ? "↑" : "↓"
        let feedTrend = feedData.trend >= 0 ? "↑" : "↓"
        content.body = "Sleep: \(String(format: "%.1f", sleepData.average))h avg \(sleepTrend) | Feeds: \(String(format: "%.0f", feedData.average))/day \(feedTrend)"
        
        content.sound = .default
        content.categoryIdentifier = "WEEKLY_RECAP"
        content.userInfo = [
            "deepLink": "nestling://open/history",
            "week_number": weekNumber
        ]
        
        // Create mini chart attachment
        let chartView = WeeklyMiniChartView(
            sleepData: sleepData.dailyValues,
            feedData: feedData.dailyValues,
            babyName: babyName,
            weekNumber: weekNumber
        )
        
        if let attachment = createAttachment(from: chartView, size: CGSize(width: 1024, height: 512)) {
            content.attachments = [attachment]
        }
        
        // Calculate next Sunday at 7 PM if no delivery time specified
        let trigger: UNNotificationTrigger
        if let deliveryTime = deliveryTime {
            let interval = max(1, deliveryTime.timeIntervalSinceNow)
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        } else {
            let calendar = Calendar.current
            let now = Date()
            let nextSunday = calendar.nextDate(
                after: now,
                matching: DateComponents(weekday: 1),
                matchingPolicy: .nextTimePreservingSmallerComponents
            ) ?? now
            let sundayEvening = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: nextSunday) ?? now
            
            let components = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: sundayEvening
            )
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        }
        
        let request = UNNotificationRequest(
            identifier: "weekly_summary_week_\(weekNumber)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                logger.debug("Failed to schedule weekly summary notification: \(error)")
            }
        }
    }
    
    /// Schedule a pattern discovery notification
    func schedulePatternDiscoveryNotification(
        patternType: PatternType,
        babyName: String,
        insight: String
    ) {
        guard PolishFeatureFlags.shared.richNotificationsEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Pattern discovered! 🔍"
        content.body = "\(babyName)'s \(patternType.displayName): \(insight)"
        content.sound = .default
        content.categoryIdentifier = "PATTERN_DISCOVERY"
        content.userInfo = [
            "deepLink": "nestling://open/predictions",
            "pattern_type": patternType.rawValue
        ]
        
        // Use pattern-specific emoji badge
        content.badge = patternType.badgeEmoji
        
        let request = UNNotificationRequest(
            identifier: "pattern_\(patternType.rawValue)_\(UUID().uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        center.add(request) { error in
            if let error = error {
                logger.debug("Failed to schedule pattern discovery notification: \(error)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    @MainActor
    private func createMilestoneBadgeAttachment(type: MilestoneType, babyName: String) -> UNNotificationAttachment? {
        let badgeView = MilestoneBadgeView(type: type, babyName: babyName)
        return createAttachment(from: badgeView, size: CGSize(width: 200, height: 200))
    }
    
    // MARK: - Types
    
    enum MilestoneType: String {
        case firstWeek = "first_week"
        case firstMonth = "first_month"
        case streak7 = "streak_7"
        case streak30 = "streak_30"
        case logs100 = "logs_100"
        case logs500 = "logs_500"
        case patternEmerging = "pattern_emerging"
        
        var emoji: String {
            switch self {
            case .firstWeek: return "🎉"
            case .firstMonth: return "🌟"
            case .streak7: return "🔥"
            case .streak30: return "💪"
            case .logs100: return "💯"
            case .logs500: return "🏆"
            case .patternEmerging: return "✨"
            }
        }
    }
    
    enum PatternType: String {
        case sleep = "sleep"
        case feed = "feed"
        case diaper = "diaper"
        case napTiming = "nap_timing"
        
        var displayName: String {
            switch self {
            case .sleep: return "sleep pattern"
            case .feed: return "feeding rhythm"
            case .diaper: return "diaper pattern"
            case .napTiming: return "nap timing"
            }
        }
        
        var badgeEmoji: NSNumber {
            switch self {
            case .sleep: return 1
            case .feed: return 2
            case .diaper: return 3
            case .napTiming: return 4
            }
        }
    }
    
    struct WeeklyDataSummary {
        let average: Double
        let trend: Double // Positive = improving, negative = declining
        let dailyValues: [Double] // 7 values for each day
    }
}

// MARK: - Notification Badge Views

private struct MilestoneBadgeView: View {
    let type: RichNotificationService.MilestoneType
    let babyName: String
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.primary.opacity(0.8), Color.primary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 4) {
                Text(type.emoji)
                    .font(.system(size: 48))
                
                Text(milestoneLabel)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var milestoneLabel: String {
        switch type {
        case .firstWeek: return "1 Week!"
        case .firstMonth: return "1 Month!"
        case .streak7: return "7 Days"
        case .streak30: return "30 Days"
        case .logs100: return "100 Logs"
        case .logs500: return "500 Logs"
        case .patternEmerging: return "Pattern!"
        }
    }
}

private struct WeeklyMiniChartView: View {
    let sleepData: [Double]
    let feedData: [Double]
    let babyName: String
    let weekNumber: Int
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Week \(weekNumber)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.foreground)
                
                Spacer()
                
                Text(babyName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.mutedForeground)
            }
            .padding(.horizontal)
            
            // Charts
            HStack(spacing: 24) {
                // Sleep chart
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "moon.fill")
                            .foregroundColor(.eventSleep)
                        Text("Sleep")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    
                    MiniBarChart(data: sleepData, color: .eventSleep)
                }
                
                // Feeds chart  
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "drop.fill")
                            .foregroundColor(.eventFeed)
                        Text("Feeds")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    
                    MiniBarChart(data: feedData, color: .eventFeed)
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color.background)
    }
}

private struct MiniBarChart: View {
    let data: [Double]
    let color: Color
    
    private var maxValue: Double {
        data.max() ?? 1
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: 24, height: max(8, CGFloat(value / maxValue) * 60))
            }
        }
        .frame(height: 60)
    }
}

// MARK: - Extended Deep Link Routes

extension DeepLinkRoute {
    /// Returns a human-readable description for accessibility
    var accessibilityDescription: String {
        switch self {
        case .logFeed(let amount, _):
            if let amount = amount {
                return "Log a feed of \(Int(amount)) ounces"
            }
            return "Log a feed"
        case .logDiaper(let type):
            if let type = type {
                return "Log a \(type) diaper"
            }
            return "Log a diaper change"
        case .logTummy:
            return "Log tummy time"
        case .sleepStart:
            return "Start tracking sleep"
        case .sleepStop:
            return "Stop tracking sleep"
        case .openHome:
            return "Open the home screen"
        case .openPredictions:
            return "View predictions and patterns"
        case .openHistory:
            return "View activity history"
        case .openSettings:
            return "Open settings"
        case .unknown:
            return "Open the app"
        }
    }
}
