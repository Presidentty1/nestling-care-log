import SwiftUI
import UIKit

struct ExportDataView: View {
    @EnvironmentObject var environment: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedFormat: DataExportService.ExportFormat = .csv
    @State private var selectedRange: DateRangeOption = .allTime
    @State private var selectedBaby: Baby?
    @State private var isExporting = false
    @State private var exportProgress: Double = 0.0
    @State private var exportStatus = ""
    @State private var showError = false
    @State private var errorMessage = ""

    private let exportService: DataExportService

    init() {
        let dataStore = DataStoreSelector.create()
        self.exportService = DataExportService(dataStore: dataStore)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacingXL) {
                    // Baby Selection
                    if environment.babies.count > 1 {
                        VStack(alignment: .leading, spacing: .spacingMD) {
                            Text("Select Baby")
                                .font(.headline)
                                .foregroundColor(Color.adaptiveForeground(colorScheme))

                            Picker("Baby", selection: $selectedBaby) {
                                ForEach(environment.babies, id: \.id) { baby in
                                    Text(baby.name).tag(baby as Baby?)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(.horizontal, .spacingMD)
                    }

                    // Export Format
                    VStack(alignment: .leading, spacing: .spacingMD) {
                        Text("Export Format")
                            .font(.headline)
                            .foregroundColor(Color.adaptiveForeground(colorScheme))

                        Picker("Format", selection: $selectedFormat) {
                            Text("CSV").tag(DataExportService.ExportFormat.csv)
                            Text("PDF").tag(DataExportService.ExportFormat.pdf)
                            Text("JSON").tag(DataExportService.ExportFormat.json)
                        }
                        .pickerStyle(.segmented)

                        Text(formatDescription(for: selectedFormat))
                            .font(.caption)
                            .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                            .padding(.top, .spacingXS)
                    }
                    .padding(.horizontal, .spacingMD)

                    // Date Range
                    VStack(alignment: .leading, spacing: .spacingMD) {
                        Text("Date Range")
                            .font(.headline)
                            .foregroundColor(Color.adaptiveForeground(colorScheme))

                        Picker("Range", selection: $selectedRange) {
                            Text("All Time").tag(DateRangeOption.allTime)
                            Text("Last Week").tag(DateRangeOption.lastWeek)
                            Text("Last Month").tag(DateRangeOption.lastMonth)
                            Text("Last 3 Months").tag(DateRangeOption.last3Months)
                            Text("Last 6 Months").tag(DateRangeOption.last6Months)
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal, .spacingMD)

                    // Export Progress
                    if isExporting {
                        VStack(spacing: .spacingMD) {
                            ProgressView(value: exportProgress)
                                .progressViewStyle(.linear)

                            Text(exportStatus)
                                .font(.caption)
                                .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                        }
                        .padding(.horizontal, .spacingMD)
                    }

                    // Export Button
                    PrimaryButton(
                        isExporting ? "Exporting..." : "Export Data",
                        icon: "square.and.arrow.up",
                        isLoading: isExporting
                    ) {
                        Task {
                            await performExport()
                        }
                    }
                    .disabled(isExporting || (environment.babies.count > 1 && selectedBaby == nil))
                    .padding(.horizontal, .spacingMD)

                    // Info Section
                    VStack(alignment: .leading, spacing: .spacingMD) {
                        Text("About Data Export")
                            .font(.headline)
                            .foregroundColor(Color.adaptiveForeground(colorScheme))

                        VStack(alignment: .leading, spacing: .spacingSM) {
                            InfoRow(icon: "checkmark.circle.fill", text: "Includes all feed, sleep, diaper, and activity logs")
                            InfoRow(icon: "checkmark.circle.fill", text: "CSV format is optimized for doctors and spreadsheets")
                            InfoRow(icon: "checkmark.circle.fill", text: "JSON format preserves all data and metadata")
                            InfoRow(icon: "lock.fill", text: "Files are not uploaded - only saved locally")
                        }
                    }
                    .padding(.spacingMD)
                    .background(Color.adaptiveSurface(colorScheme))
                    .cornerRadius(.radiusMD)
                    .padding(.horizontal, .spacingMD)

                    Spacer()
                }
                .padding(.vertical, .spacing2XL)
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                }
            }
            .alert("Export Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                // Auto-select first baby if only one exists
                if environment.babies.count == 1 {
                    selectedBaby = environment.babies.first
                }
            }
        }
    }

    private func formatDescription(for format: DataExportService.ExportFormat) -> String {
        switch format {
        case .csv:
            return "Best for spreadsheets and data analysis. Includes date, time, event type, duration, and amounts in an easy-to-read format."
        case .pdf:
            return "Professional report for pediatrician visits. Includes activity summary, feeding analysis, growth records, and space for doctor notes. Premium feature."
        case .json:
            return "Complete export with all metadata. Best for backing up data or importing into other Nestling installations."
        }
    }

    private func performExport() async {
        guard let baby = selectedBaby ?? environment.babies.first else { return }

        isExporting = true
        exportProgress = 0.0
        exportStatus = "Preparing export..."

        do {
            // Simulate progress for user feedback
            exportProgress = 0.2
            exportStatus = "Gathering data..."

            let dateRange = selectedRange.dateRange

            exportProgress = 0.5
            exportStatus = "Generating file..."

            let exportURL = try await exportService.exportData(for: baby, format: selectedFormat, dateRange: dateRange)

            exportProgress = 0.8
            exportStatus = "Preparing to share..."

            // Get the root view controller for sharing
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {

                try await exportService.shareExportedFile(url: exportURL, from: rootViewController)
            }

            exportProgress = 1.0
            exportStatus = "Export complete!"

            // Dismiss after a short delay
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            dismiss()

        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }

        isExporting = false
    }
}

struct InfoRow: View {
    let icon: String
    let text: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: .spacingSM) {
            Image(systemName: icon)
                .foregroundColor(icon == "checkmark.circle.fill" ? .green : Color.adaptiveTextSecondary(colorScheme))
                .frame(width: 16)

            Text(text)
                .font(.body)
                .foregroundColor(Color.adaptiveForeground(colorScheme))
        }
    }
}

enum DateRangeOption {
    case allTime
    case lastWeek
    case lastMonth
    case last3Months
    case last6Months

    var dateRange: DateRange? {
        switch self {
        case .allTime: return nil
        case .lastWeek: return .lastWeek()
        case .lastMonth: return .lastMonth()
        case .last3Months: return .last3Months()
        case .last6Months: return .last6Months()
        }
    }
}