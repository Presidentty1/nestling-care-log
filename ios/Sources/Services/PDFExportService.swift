import Foundation
import SwiftUI
import PDFKit

class PDFExportService {
    static func generatePDF(for events: [Event], baby: Baby, dateRange: (start: Date, end: Date)) -> URL? {
        let pdfMetaData = [
            kCGPDFContextCreator: "Nestling",
            kCGPDFContextAuthor: "Nestling Baby Tracker",
            kCGPDFContextTitle: "Baby Care Log - \(baby.name)"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "nestling_report_\(Date().timeIntervalSince1970).pdf"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try renderer.writePDF(to: fileURL) { context in
                context.beginPage()
                
                var yPosition: CGFloat = 72
                
                // Title
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 24),
                    .foregroundColor: UIColor.label
                ]
                let title = NSAttributedString(string: "Baby Care Log", attributes: titleAttributes)
                title.draw(at: CGPoint(x: 72, y: yPosition))
                yPosition += 40
                
                // Baby name and date range
                let infoAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor.secondaryLabel
                ]
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                let infoText = "\(baby.name) • \(dateFormatter.string(from: dateRange.start)) - \(dateFormatter.string(from: dateRange.end))"
                let info = NSAttributedString(string: infoText, attributes: infoAttributes)
                info.draw(at: CGPoint(x: 72, y: yPosition))
                yPosition += 60
                
                // Events
                let eventAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.label
                ]
                
                for event in events {
                    if yPosition > pageHeight - 100 {
                        context.beginPage()
                        yPosition = 72
                    }
                    
                    let timeFormatter = DateFormatter()
                    timeFormatter.timeStyle = .short
                    let timeString = timeFormatter.string(from: event.startTime)
                    
                    var eventText = "\(timeString) - \(event.type.displayName)"
                    if let subtype = event.subtype {
                        eventText += " (\(subtype))"
                    }
                    if let amount = event.amount, let unit = event.unit {
                        eventText += " • \(amount) \(unit)"
                    }
                    if let note = event.note {
                        eventText += "\n  \(note)"
                    }
                    
                    let eventAttr = NSAttributedString(string: eventText, attributes: eventAttributes)
                    let textRect = CGRect(x: 72, y: yPosition, width: pageWidth - 144, height: 50)
                    eventAttr.draw(in: textRect)
                    yPosition += 60
                }
                
                // Epic 8 AC4: Footer with branding
                let footerAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10),
                    .foregroundColor: UIColor.secondaryLabel
                ]
                let footerText = "Generated with Nuzzle – AI newborn sleep & feed co‑pilot."
                let footer = NSAttributedString(string: footerText, attributes: footerAttributes)
                let footerRect = CGRect(x: 72, y: pageHeight - 40, width: pageWidth - 144, height: 20)
                footer.draw(in: footerRect)
            }
            
            return fileURL
        } catch {
            Logger.dataError("Failed to generate PDF: \(error.localizedDescription)")
            return nil
        }
    }
}


