import SwiftUI
import UIKit

/// Service for generating beautiful shareable cards
/// Optimized for social media platforms
///
/// Dimensions:
/// - Instagram Stories: 1080x1920
/// - Instagram Feed: 1080x1080
/// - Twitter: 1200x675
///
/// Usage:
/// ```swift
/// let card = ContentShareService.shared.generateCard(
///     type: .milestone(.sevenDayStreak),
///     babyName: "Emma"
/// )
/// // Share card via UIActivityViewController
/// ```
@MainActor
class ContentShareService {
    static let shared = ContentShareService()
    
    private init() {}
    
    // MARK: - Card Generation
    
    /// Generate shareable card for social media
    func generateCard(
        type: ShareableContentType,
        babyName: String,
        customText: String? = nil,
        aspectRatio: CardAspectRatio = .square
    ) -> UIImage? {
        let size = aspectRatio.size
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Background gradient
            let gradient = getBackgroundGradient(for: type)
            let rect = CGRect(origin: .zero, size: size)
            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )
            
            // Add content based on type
            drawCardContent(
                in: rect,
                type: type,
                babyName: babyName,
                customText: customText,
                context: context
            )
            
            // Add subtle branding
            drawBranding(in: rect, context: context)
        }
    }
    
    // MARK: - Content Drawing
    
    private func drawCardContent(
        in rect: CGRect,
        type: ShareableContentType,
        babyName: String,
        customText: String?,
        context: UIGraphicsImageRendererContext
    ) {
        let mainText = customText ?? getMainText(for: type, babyName: babyName)
        let emoji = getEmoji(for: type)
        let stats = getStats(for: type)
        
        // Draw emoji
        let emojiRect = CGRect(
            x: rect.midX - 60,
            y: rect.height * 0.25,
            width: 120,
            height: 120
        )
        drawText(
            emoji,
            in: emojiRect,
            font: UIFont.systemFont(ofSize: 100),
            color: .white,
            alignment: .center
        )
        
        // Draw main text
        let textRect = CGRect(
            x: 40,
            y: rect.height * 0.45,
            width: rect.width - 80,
            height: 200
        )
        drawText(
            mainText,
            in: textRect,
            font: UIFont.systemFont(ofSize: 36, weight: .bold),
            color: .white,
            alignment: .center
        )
        
        // Draw stats (if available)
        if let stats = stats {
            let statsRect = CGRect(
                x: 40,
                y: rect.height * 0.65,
                width: rect.width - 80,
                height: 60
            )
            drawText(
                stats,
                in: statsRect,
                font: UIFont.systemFont(ofSize: 20, weight: .medium),
                color: UIColor.white.withAlphaComponent(0.8),
                alignment: .center
            )
        }
    }
    
    private func drawBranding(in rect: CGRect, context: UIGraphicsImageRendererContext) {
        // Subtle "Nuzzle" branding at bottom
        let brandingText = "via Nuzzle"
        let brandingRect = CGRect(
            x: 40,
            y: rect.height - 60,
            width: rect.width - 80,
            height: 40
        )
        drawText(
            brandingText,
            in: brandingRect,
            font: UIFont.systemFont(ofSize: 14, weight: .regular),
            color: UIColor.white.withAlphaComponent(0.6),
            alignment: .center
        )
    }
    
    private func drawText(
        _ text: String,
        in rect: CGRect,
        font: UIFont,
        color: UIColor,
        alignment: NSTextAlignment
    ) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ]
        
        text.draw(in: rect, withAttributes: attributes)
    }
    
    // MARK: - Content Helpers
    
    private func getMainText(for type: ShareableContentType, babyName: String) -> String {
        switch type {
        case .milestone(.firstLog):
            return "Started tracking \(babyName) today!"
        case .milestone(.tenLogs):
            return "10 logs with \(babyName)!\nWe've got this!"
        case .milestone(.sevenDayStreak):
            return "7 days of tracking\n\(babyName)! 🎉"
        case .milestone(.firstLongSleep):
            return "\(babyName) slept\n4+ hours!"
        case .milestone(.accuratePrediction):
            return "Nailed the prediction\nfor \(babyName)!"
        case .milestone(.partnerSync):
            return "Syncing with my\nco-parent! 💙"
        case .weekSummary(let logs):
            return "\(logs) events tracked\nthis week"
        case .personalBest(let type, let value):
            return "\(babyName)'s best\n\(type): \(value)!"
        }
    }
    
    private func getEmoji(for type: ShareableContentType) -> String {
        switch type {
        case .milestone(.firstLog): return "🎉"
        case .milestone(.tenLogs): return "💪"
        case .milestone(.sevenDayStreak): return "🔥"
        case .milestone(.firstLongSleep): return "😴"
        case .milestone(.accuratePrediction): return "🎯"
        case .milestone(.partnerSync): return "👨‍👩‍👧"
        case .weekSummary: return "📊"
        case .personalBest: return "🏆"
        }
    }
    
    private func getStats(for type: ShareableContentType) -> String? {
        switch type {
        case .milestone(.sevenDayStreak):
            return "Building habits, one day at a time"
        case .milestone(.firstLongSleep):
            return "They finally slept!"
        case .weekSummary(let logs):
            return "\(logs) moments captured"
        default:
            return nil
        }
    }
    
    private func getBackgroundGradient(for type: ShareableContentType) -> CGGradient {
        // Get gradient colors based on content type
        let colors: [UIColor]
        
        switch type {
        case .milestone(.firstLog), .milestone(.tenLogs):
            colors = [
                UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0),  // Blue
                UIColor(red: 0.3, green: 0.5, blue: 0.9, alpha: 1.0)
            ]
        case .milestone(.sevenDayStreak):
            colors = [
                UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0),  // Orange
                UIColor(red: 0.9, green: 0.4, blue: 0.2, alpha: 1.0)
            ]
        case .milestone(.firstLongSleep):
            colors = [
                UIColor(red: 0.4, green: 0.3, blue: 0.8, alpha: 1.0),  // Purple
                UIColor(red: 0.3, green: 0.2, blue: 0.6, alpha: 1.0)
            ]
        case .milestone(.accuratePrediction):
            colors = [
                UIColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 1.0),  // Green
                UIColor(red: 0.1, green: 0.6, blue: 0.3, alpha: 1.0)
            ]
        case .milestone(.partnerSync):
            colors = [
                UIColor(red: 0.8, green: 0.3, blue: 0.5, alpha: 1.0),  // Pink
                UIColor(red: 0.6, green: 0.2, blue: 0.4, alpha: 1.0)
            ]
        case .weekSummary, .personalBest:
            colors = [
                UIColor(red: 0.3, green: 0.7, blue: 0.9, alpha: 1.0),  // Teal
                UIColor(red: 0.2, green: 0.5, blue: 0.7, alpha: 1.0)
            ]
        }
        
        return CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors.map { $0.cgColor } as CFArray,
            locations: [0.0, 1.0]
        )!
    }
}

// MARK: - Models

enum ShareableContentType {
    case milestone(CelebrationMilestone)
    case weekSummary(logCount: Int)
    case personalBest(eventType: String, value: String)
}

enum CelebrationMilestone: String {
    case firstLog
    case tenLogs
    case sevenDayStreak
    case firstLongSleep
    case accuratePrediction
    case partnerSync
}

enum CardAspectRatio {
    case instagramStory   // 9:16 (1080x1920)
    case square          // 1:1 (1080x1080)
    case twitter         // 16:9 (1200x675)
    
    var size: CGSize {
        switch self {
        case .instagramStory:
            return CGSize(width: 1080, height: 1920)
        case .square:
            return CGSize(width: 1080, height: 1080)
        case .twitter:
            return CGSize(width: 1200, height: 675)
        }
    }
}

// MARK: - Share Sheet Helper

extension ContentShareService {
    /// Present share sheet for generated card
    func shareCard(
        type: ShareableContentType,
        babyName: String,
        from viewController: UIViewController
    ) {
        guard let image = generateCard(type: type, babyName: babyName) else {
            logger.error("[Share] Failed to generate card")
            return
        }
        
        let text = getShareText(for: type, babyName: babyName)
        let items: [Any] = [text, image]
        
        let activityVC = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        
        // Track share
        Task {
            await Analytics.shared.logCelebrationShared(
                type: "\(type)",
                platform: "system_sheet"
            )
        }
        
        viewController.present(activityVC, animated: true)
    }
    
    private func getShareText(for type: ShareableContentType, babyName: String) -> String {
        switch type {
        case .milestone(.sevenDayStreak):
            return "7 days of tracking \(babyName)! Nuzzle helps me stay organized 📱"
        case .milestone(.firstLongSleep):
            return "\(babyName) just slept 4+ hours! 😴 Tracking with Nuzzle"
        case .weekSummary(let logs):
            return "Tracked \(logs) events this week with Nuzzle 📊"
        default:
            return "Tracking \(babyName) with Nuzzle 💙"
        }
    }
}

private let logger = LoggerFactory.create(category: "ContentShare")
