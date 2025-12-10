import Foundation
import PDFKit

/// Service for generating PDF reports for pediatrician visits
/// Premium feature - requires Pro subscription
@MainActor
class DoctorReportService {
    static let shared = DoctorReportService()
    
    private init() {}
    
    /// Generate a comprehensive doctor report PDF
    /// - Parameters:
    ///   - baby: Baby profile
    ///   - events: Events to include in report
    ///   - growthRecords: Growth measurements (if available)
    ///   - dateRange: Report date range
    /// - Returns: PDF data
    func generateReport(
        baby: Baby,
        events: [Event],
        growthRecords: [GrowthRecord] = [],
        dateRange: (start: Date, end: Date)
    ) async -> Data? {
        // Create PDF document
        let pdfMetadata = [
            kCGPDFContextTitle: "Baby Health Summary - \(baby.name)",
            kCGPDFContextAuthor: "Nuzzle Baby Tracker",
            kCGPDFContextCreator: "Nuzzle"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetadata as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = 40
            let leftMargin: CGFloat = 40
            let rightMargin: CGFloat = 572
            
            // Header
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.label
            ]
            let title = "Baby Health Summary"
            title.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: titleAttributes)
            yPosition += 35
            
            // Generated date
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.secondaryLabel
            ]
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let generatedText = "Generated: \(dateFormatter.string(from: Date()))"
            generatedText.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: subtitleAttributes)
            yPosition += 30
            
            // Baby Information Section
            yPosition = drawSection(
                context: context,
                title: "Baby Information",
                yPosition: yPosition,
                leftMargin: leftMargin,
                content: {
                    [
                        "Name: \(baby.name)",
                        "Date of Birth: \(dateFormatter.string(from: baby.dateOfBirth))",
                        "Age: \(baby.ageInMonths) months",
                        "Report Period: \(dateFormatter.string(from: dateRange.start)) - \(dateFormatter.string(from: dateRange.end))"
                    ]
                }
            )
            yPosition += 20
            
            // Activity Summary
            let feedCount = events.filter { $0.type == .feed }.count
            let sleepEvents = events.filter { $0.type == .sleep && $0.endTime != nil }
            let diaperCount = events.filter { $0.type == .diaper }.count
            let totalSleepMinutes = sleepEvents.reduce(0) { total, event in
                guard let endTime = event.endTime else { return total }
                let duration = endTime.timeIntervalSince(event.startTime) / 60
                return total + Int(duration)
            }
            let totalSleepHours = Double(totalSleepMinutes) / 60.0
            
            yPosition = drawSection(
                context: context,
                title: "Activity Summary",
                yPosition: yPosition,
                leftMargin: leftMargin,
                content: {
                    [
                        "Total Feeds: \(feedCount)",
                        "Average per Day: \(String(format: "%.1f", Double(feedCount) / max(1, daysBetween(dateRange.start, dateRange.end))))",
                        "",
                        "Total Sleep Sessions: \(sleepEvents.count)",
                        "Total Sleep Time: \(String(format: "%.1f", totalSleepHours)) hours",
                        "Average per Day: \(String(format: "%.1f", totalSleepHours / max(1, Double(daysBetween(dateRange.start, dateRange.end))))) hours",
                        "",
                        "Total Diaper Changes: \(diaperCount)",
                        "Average per Day: \(String(format: "%.1f", Double(diaperCount) / max(1, daysBetween(dateRange.start, dateRange.end))))"
                    ]
                }
            )
            yPosition += 20
            
            // Feeding Analysis
            let feedsWithAmount = events.filter { $0.type == .feed && $0.amount != nil && $0.amount! > 0 }
            if !feedsWithAmount.isEmpty {
                let totalAmount = feedsWithAmount.reduce(0.0) { $0 + ($1.amount ?? 0) }
                let avgAmount = totalAmount / Double(feedsWithAmount.count)
                
                yPosition = drawSection(
                    context: context,
                    title: "Feeding Details",
                    yPosition: yPosition,
                    leftMargin: leftMargin,
                    content: {
                        [
                            "Feeds with Amount: \(feedsWithAmount.count)",
                            "Total Amount: \(Int(totalAmount)) \(feedsWithAmount.first?.unit ?? "ml")",
                            "Average Amount: \(Int(avgAmount)) \(feedsWithAmount.first?.unit ?? "ml")"
                        ]
                    }
                )
                yPosition += 20
            }
            
            // Growth Records (if available)
            if !growthRecords.isEmpty {
                let latest = growthRecords.first!
                yPosition = drawSection(
                    context: context,
                    title: "Recent Growth",
                    yPosition: yPosition,
                    leftMargin: leftMargin,
                    content: {
                        var items: [String] = ["Latest measurement (Date: \(dateFormatter.string(from: latest.recordedAt))):"]
                        if let weight = latest.weight {
                            items.append("  Weight: \(String(format: "%.1f", weight)) kg")
                        }
                        if let length = latest.length {
                            items.append("  Length: \(String(format: "%.1f", length)) cm")
                        }
                        if let head = latest.headCircumference {
                            items.append("  Head: \(String(format: "%.1f", head)) cm")
                        }
                        return items
                    }
                )
                yPosition += 20
            }
            
            // Notes section
            if yPosition > 650 {
                context.beginPage()
                yPosition = 40
            }
            
            yPosition = drawSection(
                context: context,
                title: "Notes & Questions",
                yPosition: yPosition,
                leftMargin: leftMargin,
                content: { ["(Space for pediatrician to write notes)"] }
            )
            
            // Footer
            let footerText = "Generated by Nuzzle Baby Tracker"
            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 8),
                .foregroundColor: UIColor.tertiaryLabel
            ]
            footerText.draw(at: CGPoint(x: leftMargin, y: 760), withAttributes: footerAttributes)
        }
        
        return data
    }
    
    // MARK: - Helper Methods
    
    private func drawSection(
        context: UIGraphicsPDFRendererContext,
        title: String,
        yPosition: CGFloat,
        leftMargin: CGFloat,
        content: () -> [String]
    ) -> CGFloat {
        var y = yPosition
        
        // Section title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: UIColor.label
        ]
        title.draw(at: CGPoint(x: leftMargin, y: y), withAttributes: titleAttributes)
        y += 22
        
        // Section content
        let contentAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.label
        ]
        
        for line in content() {
            line.draw(at: CGPoint(x: leftMargin, y: y), withAttributes: contentAttributes)
            y += line.isEmpty ? 8 : 18
        }
        
        return y
    }
    
    private func daysBetween(_ start: Date, _ end: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: start, to: end)
        return max(1, components.day ?? 1)
    }
}

/// Growth record model (placeholder - to be replaced with actual model)
struct GrowthRecord {
    let recordedAt: Date
    let weight: Double?
    let length: Double?
    let headCircumference: Double?
}

extension Baby {
    var ageInMonths: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: dateOfBirth, to: Date())
        return components.month ?? 0
    }
}

