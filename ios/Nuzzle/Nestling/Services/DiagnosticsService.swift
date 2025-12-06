import Foundation
import UIKit

/// Generates diagnostics bundle for support
@MainActor
class DiagnosticsService {
    static let shared = DiagnosticsService()
    
    private init() {}
    
    /// Generate diagnostics bundle (JSON + metadata)
    func generateDiagnostics(dataStore: DataStore) async throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let bundleName = "nestling_diagnostics_\(Date().timeIntervalSince1970).zip"
        _ = tempDir.appendingPathComponent(bundleName)
        
        // Create temporary directory for bundle contents
        let contentsDir = tempDir.appendingPathComponent("diagnostics_contents")
        try? FileManager.default.createDirectory(at: contentsDir, withIntermediateDirectories: true)
        
        // 1. App Info
        let appInfo = generateAppInfo()
        let appInfoURL = contentsDir.appendingPathComponent("app_info.json")
        let appInfoData = try JSONSerialization.data(withJSONObject: appInfo, options: .prettyPrinted)
        try appInfoData.write(to: appInfoURL)
        
        // 2. Device Info
        let deviceInfo = generateDeviceInfo()
        let deviceInfoURL = contentsDir.appendingPathComponent("device_info.json")
        let deviceInfoData = try JSONSerialization.data(withJSONObject: deviceInfo, options: .prettyPrinted)
        try deviceInfoData.write(to: deviceInfoURL)
        
        // 3. Settings Snapshot
        do {
            let settings = try await dataStore.fetchAppSettings()
            let settingsURL = contentsDir.appendingPathComponent("settings.json")
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            try encoder.encode(settings).write(to: settingsURL)
        } catch {
            // Log error but continue
            print("Failed to export settings: \(error)")
        }
        
        // 4. Data Summary (no PII)
        let summary = await generateDataSummary(dataStore: dataStore)
        let summaryURL = contentsDir.appendingPathComponent("data_summary.json")
        let summaryData = try JSONSerialization.data(withJSONObject: summary, options: .prettyPrinted)
        try summaryData.write(to: summaryURL)
        
        // 5. Create ZIP
        // TODO: Add ZipArchive Swift Package for ZIP creation
        // For now, return the directory URL instead of ZIP
        // In production, use ZipArchive: SSZipArchive.createZipFile(atPath: bundleURL.path, withContentsOfDirectory: contentsDir.path)
        
        // Return directory URL for now (ZIP creation disabled)
        return contentsDir
    }
    
    private func generateAppInfo() -> [String: Any] {
        let info = Bundle.main.infoDictionary ?? [:]
        return [
            "app_version": info["CFBundleShortVersionString"] as? String ?? "Unknown",
            "build_number": info["CFBundleVersion"] as? String ?? "Unknown",
            "bundle_id": Bundle.main.bundleIdentifier ?? "Unknown",
            "generated_at": ISO8601DateFormatter().string(from: Date()),
            "locale": Locale.current.identifier,
            "timezone": TimeZone.current.identifier
        ]
    }
    
    private func generateDeviceInfo() -> [String: Any] {
        let device = UIDevice.current
        return [
            "model": device.model,
            "system_name": device.systemName,
            "system_version": device.systemVersion,
            "screen_width": UIScreen.main.bounds.width,
            "screen_height": UIScreen.main.bounds.height,
            "scale": UIScreen.main.scale,
            "accessibility_reduce_motion": UIAccessibility.isReduceMotionEnabled,
            "accessibility_reduce_transparency": UIAccessibility.isReduceTransparencyEnabled,
            "accessibility_increase_contrast": UIAccessibility.isDarkerSystemColorsEnabled
        ]
    }
    
    private func generateDataSummary(dataStore: DataStore) async -> [String: Any] {
        do {
            let babies = try await dataStore.fetchBabies()
            var eventCounts: [String: Int] = [:]
            var totalEvents = 0
            
            for baby in babies {
                let today = Date()
                let weekAgo = today.addingTimeInterval(-7 * 24 * 3600)
                let events = try? await dataStore.fetchEvents(for: baby, from: weekAgo, to: today)
                
                if let events = events {
                    totalEvents += events.count
                    for event in events {
                        eventCounts[event.type.rawValue, default: 0] += 1
                    }
                }
            }
            
            var hasActiveSleep = false
            for baby in babies {
                if let _ = try? await dataStore.getActiveSleep(for: baby) {
                    hasActiveSleep = true
                    break
                }
            }
            
            return [
                "baby_count": babies.count,
                "total_events_last_7_days": totalEvents,
                "event_counts": eventCounts,
                "has_active_sleep": hasActiveSleep
            ]
        } catch {
            return ["error": "Failed to generate summary: \(error.localizedDescription)"]
        }
    }
    
}

