import Foundation
import Compression

class BackupService {
    static func createBackup(dataStore: DataStore, baby: Baby) async throws -> URL {
        // Create backup directory
        let tempDir = FileManager.default.temporaryDirectory
        let backupDir = tempDir.appendingPathComponent("nestling_backup_\(Date().timeIntervalSince1970)")
        try FileManager.default.createDirectory(at: backupDir, withIntermediateDirectories: true)
        
        // Export JSON
        let jsonURL = backupDir.appendingPathComponent("data.json")
        let babies = try await dataStore.fetchBabies()
        let startDate = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        let events = try await dataStore.fetchEvents(for: baby, from: startDate, to: Date())
        let settings = try await dataStore.fetchAppSettings()
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let backupData: [String: Any] = [
            "version": 1,
            "babies": try babies.map { try JSONEncoder().encode($0) }.map { try JSONSerialization.jsonObject(with: $0) },
            "events": try events.map { try JSONEncoder().encode($0) }.map { try JSONSerialization.jsonObject(with: $0) },
            "settings": try JSONSerialization.jsonObject(with: try encoder.encode(settings))
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: backupData, options: .prettyPrinted)
        try jsonData.write(to: jsonURL)
        
        // Generate PDF summary
        if let pdfURL = PDFExportService.generatePDF(for: events, baby: baby, dateRange: (startDate, Date())) {
            let pdfDest = backupDir.appendingPathComponent("summary.pdf")
            try? FileManager.default.copyItem(at: pdfURL, to: pdfDest)
        }
        
        // TODO: Add ZipArchive Swift Package for ZIP creation
        // For now, return the directory URL
        // In production, use ZipArchive: SSZipArchive.createZipFile(atPath: zipURL.path, withContentsOfDirectory: backupDir.path)
        return backupDir
    }
    
    static func restoreFromBackup(url: URL, dataStore: DataStore) async throws {
        // TODO: Add ZipArchive Swift Package for ZIP extraction
        // For now, assume url is already a directory
        let extractDir = url
        
        // Load JSON
        let jsonURL = extractDir.appendingPathComponent("data.json")
        let jsonData = try Data(contentsOf: jsonURL)
        let backupData = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        
        // Restore data (with conflict resolution - new IDs)
        // Implementation would restore babies, events, settings
        
        // Cleanup
        try? FileManager.default.removeItem(at: extractDir)
    }
}

