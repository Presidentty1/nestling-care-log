import Foundation

/// Service for generating doctor/caregiver export summaries
class DoctorExportService {
    static let shared = DoctorExportService()

    private init() {}

    // MARK: - Summary Generation

    /// Generate a human-readable summary for doctor/caregiver
    func generateSummary(for baby: Baby, events: [Event], dateRange: (start: Date, end: Date)) -> String {
        var summary = ""

        // Header
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        summary += "\(baby.name)\n"
        summary += "Age: \(calculateAgeString(for: baby, at: Date()))\n"
        summary += "Report Period: \(dateFormatter.string(from: dateRange.start)) - \(dateFormatter.string(from: dateRange.end))\n\n"

        // Daily summaries
        let dailySummaries = createDailySummaries(from: events, dateRange: dateRange)
        for dailySummary in dailySummaries.sorted(by: { $0.date < $1.date }) {
            summary += formatDailySummary(dailySummary)
            summary += "\n"
        }

        // Feed details
        let feedEvents = events.filter { $0.type == .feed }
        if !feedEvents.isEmpty {
            summary += "FEEDING DETAILS\n"
            summary += "---------------\n"
            for event in feedEvents.sorted(by: { $0.startTime < $1.startTime }) {
                let timeFormatter = DateFormatter()
                timeFormatter.dateStyle = .short
                timeFormatter.timeStyle = .short

                var feedLine = "\(timeFormatter.string(from: event.startTime)): "
                if let amount = event.amount, let unit = event.unit {
                    feedLine += "\(Int(amount)) \(unit)"
                } else {
                    feedLine += "Unknown amount"
                }
                if let subtype = event.subtype {
                    feedLine += " (\(subtype))"
                }
                summary += feedLine + "\n"
            }
            summary += "\n"
        }

        // Sleep details
        let sleepEvents = events.filter { $0.type == .sleep }
        if !sleepEvents.isEmpty {
            summary += "SLEEP DETAILS\n"
            summary += "-------------\n"
            for event in sleepEvents.sorted(by: { $0.startTime < $1.startTime }) {
                let timeFormatter = DateFormatter()
                timeFormatter.timeStyle = .short

                var sleepLine = "\(timeFormatter.string(from: event.startTime))"
                if let endTime = event.endTime {
                    sleepLine += " - \(timeFormatter.string(from: endTime))"
                    if let duration = event.durationMinutes {
                        let hours = duration / 60
                        let minutes = duration % 60
                        sleepLine += " (\(hours)h \(minutes)m)"
                    }
                }
                summary += sleepLine + "\n"
            }
            summary += "\n"
        }

        // Epic 8 AC4: Add footer
        return addFooter(to: summary)
    }

    /// Generate CSV data for export
    func generateCSV(for baby: Baby, events: [Event], dateRange: (start: Date, end: Date)) -> String {
        var csv = "Date,Time,Type,Details,Notes\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short

        for event in events.sorted(by: { $0.startTime < $1.startTime }) {
            let dateStr = dateFormatter.string(from: event.startTime)
            let timeStr = timeFormatter.string(from: event.startTime)

            var type = event.type.displayName
            var details = ""

            switch event.type {
            case .feed:
                if let amount = event.amount, let unit = event.unit {
                    details = "\(Int(amount)) \(unit)"
                    if let subtype = event.subtype {
                        details += " \(subtype)"
                    }
                }
            case .diaper:
                details = event.subtype ?? "diaper change"
            case .sleep:
                if let endTime = event.endTime, let duration = event.durationMinutes {
                    let endTimeStr = timeFormatter.string(from: endTime)
                    details = "until \(endTimeStr) (\(duration)m)"
                } else {
                    details = "started"
                }
            case .tummyTime:
                if let duration = event.durationMinutes {
                    details = "\(duration) minutes"
                } else {
                    details = "tummy time"
                }
            }

            let notes = event.note ?? ""
            csv += "\(dateStr),\(timeStr),\(type),\(details),\(notes)\n"
        }

        return csv
    }

    // MARK: - Helper Methods

    private func calculateAgeString(for baby: Baby, at date: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: baby.dateOfBirth, to: date)

        var ageParts: [String] = []

        if let years = components.year, years > 0 {
            ageParts.append("\(years) year\(years == 1 ? "" : "s")")
        }

        if let months = components.month, months > 0 {
            ageParts.append("\(months) month\(months == 1 ? "" : "s")")
        }

        if let days = components.day, days > 0 && ageParts.isEmpty {
            ageParts.append("\(days) day\(days == 1 ? "" : "s")")
        }

        return ageParts.joined(separator: ", ") + " old"
    }

    private func createDailySummaries(from events: [Event], dateRange: (start: Date, end: Date)) -> [DailySummary] {
        let calendar = Calendar.current
        var summaries: [Date: DailySummary] = [:]

        // Create entries for each day in range
        var currentDate = dateRange.start.startOfDay
        while currentDate <= dateRange.end {
            summaries[currentDate] = DailySummary(date: currentDate, feedCount: 0, diaperCount: 0, sleepMinutes: 0, tummyTimeCount: 0)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate.addingTimeInterval(86400)
        }

        // Populate with actual data
        for event in events {
            let eventDate = event.startTime.startOfDay
            if let summary = summaries[eventDate] {
                switch event.type {
                case .feed:
                    summaries[eventDate] = DailySummary(
                        date: summary.date,
                        feedCount: summary.feedCount + 1,
                        diaperCount: summary.diaperCount,
                        sleepMinutes: summary.sleepMinutes,
                        tummyTimeCount: summary.tummyTimeCount
                    )
                case .diaper:
                    summaries[eventDate] = DailySummary(
                        date: summary.date,
                        feedCount: summary.feedCount,
                        diaperCount: summary.diaperCount + 1,
                        sleepMinutes: summary.sleepMinutes,
                        tummyTimeCount: summary.tummyTimeCount
                    )
                case .sleep:
                    let additionalMinutes = event.durationMinutes ?? 0
                    summaries[eventDate] = DailySummary(
                        date: summary.date,
                        feedCount: summary.feedCount,
                        diaperCount: summary.diaperCount,
                        sleepMinutes: summary.sleepMinutes + additionalMinutes,
                        tummyTimeCount: summary.tummyTimeCount
                    )
                case .tummyTime:
                    summaries[eventDate] = DailySummary(
                        date: summary.date,
                        feedCount: summary.feedCount,
                        diaperCount: summary.diaperCount,
                        sleepMinutes: summary.sleepMinutes,
                        tummyTimeCount: summary.tummyTimeCount + 1
                    )
                }
            }
        }

        return Array(summaries.values)
    }

    private func formatDailySummary(_ summary: DailySummary) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dateStr = dateFormatter.string(from: summary.date)

        var lines = ["\(dateStr):"]

        if summary.feedCount > 0 {
            lines.append("  Feeds: \(summary.feedCount)")
        }

        if summary.diaperCount > 0 {
            lines.append("  Diapers: \(summary.diaperCount)")
        }

        if summary.sleepMinutes > 0 {
            let hours = summary.sleepMinutes / 60
            let minutes = summary.sleepMinutes % 60
            if hours > 0 {
                lines.append("  Sleep: \(hours)h \(minutes)m")
            } else {
                lines.append("  Sleep: \(minutes)m")
            }
        }

        if summary.tummyTimeCount > 0 {
            lines.append("  Tummy time: \(summary.tummyTimeCount)")
        }

        return lines.joined(separator: "\n")
    }
    
    /// Add footer to summary (Epic 8 AC4)
    private func addFooter(to summary: String) -> String {
        return summary + "\n\n---\nGenerated with Nuzzle – AI newborn sleep & feed co‑pilot."
    }

    // MARK: - File Export

    /// Create a temporary file with the summary
    func createSummaryFile(summary: String, baby: Baby) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "nestling_summary_\(baby.name.replacingOccurrences(of: " ", with: "_"))_\(Date().timeIntervalSince1970).txt"
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try summary.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            Logger.dataError("Failed to write summary file: \(error.localizedDescription)")
            return nil
        }
    }

    /// Create a temporary CSV file
    func createCSVFile(csv: String, baby: Baby) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "nestling_data_\(baby.name.replacingOccurrences(of: " ", with: "_"))_\(Date().timeIntervalSince1970).csv"
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            Logger.dataError("Failed to write CSV file: \(error.localizedDescription)")
            return nil
        }
    }
}

private struct DailySummary {
    let date: Date
    let feedCount: Int
    let diaperCount: Int
    let sleepMinutes: Int
    let tummyTimeCount: Int
}

