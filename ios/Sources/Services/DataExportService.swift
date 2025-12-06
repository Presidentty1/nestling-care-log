import Foundation
import UIKit

/// Service for exporting baby data in various formats (CSV, JSON)
/// Provides doctor-friendly CSV format and complete JSON export
@MainActor
class DataExportService {
    enum ExportFormat {
        case csv
        case pdf
        case json

        var fileExtension: String {
            switch self {
            case .csv: return "csv"
            case .pdf: return "pdf"
            case .json: return "json"
            }
        }

        var mimeType: String {
            switch self {
            case .csv: return "text/csv"
            case .pdf: return "application/pdf"
            case .json: return "application/json"
            }
        }
    }

    enum ExportError: LocalizedError {
        case noData
        case exportFailed(String)
        case shareFailed

        var errorDescription: String? {
            switch self {
            case .noData:
                return "No data available to export"
            case .exportFailed(let reason):
                return "Export failed: \(reason)"
            case .shareFailed:
                return "Unable to share exported file"
            }
        }
    }

    private let dataStore: DataStore

    init(dataStore: DataStore) {
        self.dataStore = dataStore
    }

    /// Export all data for a baby in the specified format
    func exportData(for baby: Baby, format: ExportFormat, dateRange: DateRange? = nil) async throws -> URL {
        let events = try await fetchEvents(for: baby, dateRange: dateRange)

        guard !events.isEmpty else {
            throw ExportError.noData
        }

        let filename = generateFilename(for: baby, format: format, dateRange: dateRange)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        switch format {
        case .csv:
            try await exportToCSV(events: events, baby: baby, to: tempURL)
        case .pdf:
            try await exportToPDF(events: events, baby: baby, dateRange: dateRange, to: tempURL)
        case .json:
            try await exportToJSON(events: events, baby: baby, to: tempURL)
        }

        return tempURL
    }

    /// Share exported file using system share sheet
    func shareExportedFile(url: URL, from viewController: UIViewController) async throws {
        await MainActor.run {
            let activityVC = UIActivityViewController(
                activityItems: [url],
                applicationActivities: nil
            )

            // For iPad compatibility
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = viewController.view
                popover.sourceRect = CGRect(x: viewController.view.bounds.midX,
                                          y: viewController.view.bounds.midY,
                                          width: 0, height: 0)
            }

            viewController.present(activityVC, animated: true)
        }
    }

    // MARK: - Private Methods

    private func fetchEvents(for baby: Baby, dateRange: DateRange?) async throws -> [Event] {
        if let range = dateRange {
            return try await dataStore.fetchEvents(for: baby, from: range.start, to: range.end)
        } else {
            // Export all events
            return try await dataStore.fetchEvents(for: baby, from: Date.distantPast, to: Date.distantFuture)
        }
    }

    private func generateFilename(for baby: Baby, format: ExportFormat, dateRange: DateRange?) -> String {
        let babyName = baby.name.replacingOccurrences(of: " ", with: "_")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        var filename = "Nestling_\(babyName)"

        if let range = dateRange {
            let startDate = dateFormatter.string(from: range.start)
            let endDate = dateFormatter.string(from: range.end)
            filename += "_\(startDate)_to_\(endDate)"
        }

        filename += ".\(format.fileExtension)"
        return filename
    }

    private func exportToCSV(events: [Event], baby: Baby, to url: URL) async throws {
        var csvContent = ""

        // CSV Header (doctor-friendly format)
        csvContent += "Date,Time,Event Type,Duration (minutes),Amount,Unit,Subtype,Notes\n"

        // Sort events by date/time
        let sortedEvents = events.sorted { $0.startTime < $1.startTime }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        for event in sortedEvents {
            let date = dateFormatter.string(from: event.startTime)
            let time = timeFormatter.string(from: event.startTime)
            let type = event.type.rawValue.capitalized
            let duration = event.durationMinutes?.description ?? ""
            let amount = event.amount?.description ?? ""
            let unit = event.unit ?? ""
            let subtype = event.subtype ?? ""
            let notes = event.note?.replacingOccurrences(of: ",", with: ";").replacingOccurrences(of: "\"", with: "'") ?? ""

            // Escape fields containing commas or quotes
            let escapedNotes = notes.contains(",") ? "\"\(notes)\"" : notes

            csvContent += "\(date),\(time),\(type),\(duration),\(amount),\(unit),\(subtype),\(escapedNotes)\n"
        }

        try csvContent.write(to: url, atomically: true, encoding: .utf8)
    }

    private func exportToJSON(events: [Event], baby: Baby, to url: URL) async throws {
        let exportData: [String: Any] = [
            "exportInfo": [
                "version": "1.0",
                "exportDate": Date().ISO8601Format(),
                "app": "Nestling",
                "baby": [
                    "id": baby.id.uuidString,
                    "name": baby.name,
                    "dateOfBirth": baby.dateOfBirth.ISO8601Format(),
                    "sex": baby.sex?.rawValue ?? NSNull(),
                    "timezone": baby.timezone,
                    "primaryFeedingStyle": baby.primaryFeedingStyle?.rawValue ?? NSNull()
                ]
            ],
            "events": events.map { event in
                [
                    "id": event.id.uuidString,
                    "babyId": event.babyId.uuidString,
                    "type": event.type.rawValue,
                    "subtype": event.subtype ?? NSNull(),
                    "startTime": event.startTime.ISO8601Format(),
                    "endTime": event.endTime?.ISO8601Format() ?? NSNull(),
                    "amount": event.amount ?? NSNull(),
                    "unit": event.unit ?? NSNull(),
                    "side": event.side ?? NSNull(),
                    "note": event.note ?? NSNull(),
                    "createdAt": event.createdAt.ISO8601Format(),
                    "updatedAt": event.updatedAt.ISO8601Format()
                ]
            }
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
        try jsonData.write(to: url)
    }
    
    private func exportToPDF(events: [Event], baby: Baby, dateRange: DateRange?, to url: URL) async throws {
        // Use DoctorReportService to generate PDF
        let start = dateRange?.start ?? events.map { $0.startTime }.min() ?? Date()
        let end = dateRange?.end ?? Date()
        
        guard let pdfData = await DoctorReportService.shared.generateReport(
            baby: baby,
            events: events,
            growthRecords: [], // TODO: Fetch growth records when GrowthTracker is implemented
            dateRange: (start, end)
        ) else {
            throw ExportError.exportFailed("Failed to generate PDF")
        }
        
        try pdfData.write(to: url)
    }
}

// MARK: - Supporting Types

struct DateRange {
    let start: Date
    let end: Date

    static func lastWeek() -> DateRange {
        let calendar = Calendar.current
        let end = Date()
        let start = calendar.date(byAdding: .day, value: -7, to: end)!
        return DateRange(start: start, end: end)
    }

    static func lastMonth() -> DateRange {
        let calendar = Calendar.current
        let end = Date()
        let start = calendar.date(byAdding: .month, value: -1, to: end)!
        return DateRange(start: start, end: end)
    }

    static func last3Months() -> DateRange {
        let calendar = Calendar.current
        let end = Date()
        let start = calendar.date(byAdding: .month, value: -3, to: end)!
        return DateRange(start: start, end: end)
    }

    static func last6Months() -> DateRange {
        let calendar = Calendar.current
        let end = Date()
        let start = calendar.date(byAdding: .month, value: -6, to: end)!
        return DateRange(start: start, end: end)
    }
}