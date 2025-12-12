import XCTest
@testable import Nestling

final class DataExportServiceTests: XCTestCase {
    var exportService: DataExportService!
    var mockDataStore: MockDataStore!

    override func setUp() {
        super.setUp()
        mockDataStore = MockDataStore()
        exportService = DataExportService(dataStore: mockDataStore)
    }

    override func tearDown() {
        exportService = nil
        mockDataStore = nil
        super.tearDown()
    }

    func testExportFormats() {
        // Test that both CSV and JSON formats are supported
        XCTAssertEqual(DataExportService.ExportFormat.csv.fileExtension, "csv")
        XCTAssertEqual(DataExportService.ExportFormat.json.fileExtension, "json")
        XCTAssertEqual(DataExportService.ExportFormat.csv.mimeType, "text/csv")
        XCTAssertEqual(DataExportService.ExportFormat.json.mimeType, "application/json")
    }

    func testDateRangeOptions() {
        // Test date range options
        let lastWeek = DateRangeOption.lastWeek
        let lastMonth = DateRangeOption.lastMonth
        let allTime = DateRangeOption.allTime

        XCTAssertNotNil(lastWeek.dateRange)
        XCTAssertNotNil(lastMonth.dateRange)
        XCTAssertNil(allTime.dateRange)
    }

    func testExportWithNoData() async {
        // Given
        let baby = Baby(name: "Test Baby", dateOfBirth: Date())

        // When/Then
        do {
            _ = try await exportService.exportData(for: baby, format: .csv)
            XCTFail("Expected export to fail with no data")
        } catch DataExportService.ExportError.noData {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testFilenameGeneration() {
        // Given
        let baby = Baby(name: "Test Baby", dateOfBirth: Date())
        let dateRange = DateRange(start: Date(), end: Date())

        // When
        let csvFilename = generateFilename(for: baby, format: .csv, dateRange: dateRange)
        let jsonFilename = generateFilename(for: baby, format: .json, dateRange: dateRange)

        // Then
        XCTAssertTrue(csvFilename.contains("Test_Baby"))
        XCTAssertTrue(csvFilename.hasSuffix(".csv"))
        XCTAssertTrue(jsonFilename.hasSuffix(".json"))
    }

    // Helper method (would need to be made testable in the actual service)
    private func generateFilename(for baby: Baby, format: DataExportService.ExportFormat, dateRange: DateRange?) -> String {
        let babyName = baby.name.replacingOccurrences(of: " ", with: "_")
        var filename = "Nestling_\(babyName)"

        if let range = dateRange {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let startDate = dateFormatter.string(from: range.start)
            let endDate = dateFormatter.string(from: range.end)
            filename += "_\(startDate)_to_\(endDate)"
        }

        filename += ".\(format.fileExtension)"
        return filename
    }
}





