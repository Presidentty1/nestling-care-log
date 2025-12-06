import Foundation
import UIKit

/// Service for storing and managing photos attached to events
class PhotoStorageService {
    static let shared = PhotoStorageService()

    private let fileManager = FileManager.default
    private let photosDirectoryName = "event_photos"

    private var photosDirectory: URL? {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsDirectory.appendingPathComponent(photosDirectoryName)
    }

    private init() {
        createPhotosDirectoryIfNeeded()
    }

    /// Save images for an event and return their file URLs
    func savePhotos(_ images: [UIImage], for eventId: UUID) async throws -> [String] {
        guard let directory = photosDirectory else {
            throw PhotoStorageError.directoryNotFound
        }

        var savedUrls: [String] = []

        for (index, image) in images.enumerated() {
            let filename = "\(eventId.uuidString)_\(index).jpg"
            let fileURL = directory.appendingPathComponent(filename)

            // Compress image to reduce file size
            guard let imageData = compressImage(image, maxSizeMB: 0.5) else {
                continue
            }

            try imageData.write(to: fileURL)
            savedUrls.append(fileURL.path)
        }

        return savedUrls
    }

    /// Load photos for an event
    func loadPhotos(for eventId: UUID) -> [UIImage] {
        guard let directory = photosDirectory else { return [] }

        let eventPrefix = "\(eventId.uuidString)_"
        var images: [UIImage] = []

        do {
            let files = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            let photoFiles = files.filter { $0.lastPathComponent.hasPrefix(eventPrefix) }
                .sorted { $0.lastPathComponent < $1.lastPathComponent } // Sort by index

            for fileURL in photoFiles {
                if let imageData = try? Data(contentsOf: fileURL),
                   let image = UIImage(data: imageData) {
                    images.append(image)
                }
            }
        } catch {
            print("Error loading photos for event \(eventId): \(error)")
        }

        return images
    }

    /// Delete photos for an event
    func deletePhotos(for eventId: UUID) {
        guard let directory = photosDirectory else { return }

        let eventPrefix = "\(eventId.uuidString)_"

        do {
            let files = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            let photoFiles = files.filter { $0.lastPathComponent.hasPrefix(eventPrefix) }

            for fileURL in photoFiles {
                try fileManager.removeItem(at: fileURL)
            }
        } catch {
            print("Error deleting photos for event \(eventId): \(error)")
        }
    }

    /// Get total size of stored photos
    func getTotalPhotosSize() -> Int64 {
        guard let directory = photosDirectory else { return 0 }

        var totalSize: Int64 = 0

        do {
            let files = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            for fileURL in files {
                let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                totalSize += attributes[.size] as? Int64 ?? 0
            }
        } catch {
            print("Error calculating photos size: \(error)")
        }

        return totalSize
    }

    /// Clean up old photos if storage exceeds limit (100MB)
    func cleanupIfNeeded() {
        let maxSizeBytes: Int64 = 100 * 1024 * 1024 // 100MB
        let currentSize = getTotalPhotosSize()

        if currentSize > maxSizeBytes {
            // Delete oldest photos (simple cleanup - in production, might want more sophisticated logic)
            cleanupOldPhotos(targetSize: maxSizeBytes / 2)
        }
    }

    private func cleanupOldPhotos(targetSize: Int64) {
        guard let directory = photosDirectory else { return }

        do {
            let files = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            let sortedFiles = files.sorted { file1, file2 in
                let attr1 = try? fileManager.attributesOfItem(atPath: file1.path)
                let attr2 = try? fileManager.attributesOfItem(atPath: file2.path)
                let date1 = attr1?[.modificationDate] as? Date ?? Date.distantPast
                let date2 = attr2?[.modificationDate] as? Date ?? Date.distantPast
                return date1 < date2 // Oldest first
            }

            var deletedSize: Int64 = 0
            for fileURL in sortedFiles {
                if deletedSize >= targetSize { break }

                let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                let fileSize = attributes[.size] as? Int64 ?? 0

                try fileManager.removeItem(at: fileURL)
                deletedSize += fileSize
            }
        } catch {
            print("Error during photo cleanup: \(error)")
        }
    }

    private func createPhotosDirectoryIfNeeded() {
        guard let directory = photosDirectory else { return }

        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }

    private func compressImage(_ image: UIImage, maxSizeMB: Double) -> Data? {
        let maxSizeBytes = Int(maxSizeMB * 1024 * 1024)
        var compression: CGFloat = 1.0
        var imageData = image.jpegData(compressionQuality: compression)

        // Compress by quality first
        while let data = imageData, data.count > maxSizeBytes && compression > 0.1 {
            compression -= 0.1
            imageData = image.jpegData(compressionQuality: compression)
        }

        // If still too large, resize image
        if let data = imageData, data.count > maxSizeBytes {
            let scale = sqrt(Double(maxSizeBytes) / Double(data.count))
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            imageData = resizedImage?.jpegData(compressionQuality: 0.8)
        }

        return imageData
    }
}

enum PhotoStorageError: Error {
    case directoryNotFound
    case compressionFailed
}

