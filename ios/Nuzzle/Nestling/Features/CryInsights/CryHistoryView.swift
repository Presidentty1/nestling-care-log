import SwiftUI

/// View displaying history of recorded cries
struct CryHistoryView: View {
    @EnvironmentObject var environment: AppEnvironment
    @State private var cryLogs: [CryLog] = []
    @State private var isLoading = true
    @State private var selectedLog: CryLog?
    @State private var showDeleteConfirm = false
    @State private var logToDelete: CryLog?
    
    var body: some View {
        Group {
            if isLoading {
                LoadingStateView(message: "Loading cry history...")
            } else if cryLogs.isEmpty {
                EmptyStateView(
                    icon: "waveform",
                    title: "No cry logs yet",
                    message: "Start recording to track crying episodes and get AI-powered insights"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: .spacingMD) {
                        ForEach(cryLogs) { log in
                            cryLogRow(log)
                        }
                    }
                    .padding(.spacingMD)
                }
            }
        }
        .navigationTitle("Cry History")
        .background(Color.background)
        .task {
            await loadCryLogs()
        }
        .sheet(item: $selectedLog) { log in
            cryLogDetailSheet(log)
        }
        .alert("Delete Cry Log", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let log = logToDelete {
                    deleteCryLog(log)
                }
            }
        } message: {
            Text("Are you sure you want to delete this cry log? This action cannot be undone.")
        }
    }
    
    @ViewBuilder
    private func cryLogRow(_ log: CryLog) -> some View {
        CardView(variant: .default) {
            HStack(spacing: .spacingMD) {
                // Icon
                Circle()
                    .fill(categoryColor(log.category).opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: log.category.icon)
                            .foregroundColor(categoryColor(log.category))
                    )
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(log.category.displayName)
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.foreground)
                        
                        if let confidence = log.confidence {
                            Text("\(Int(confidence * 100))%")
                                .font(.caption2)
                                .foregroundColor(.mutedForeground)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.mutedForeground.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(formatDate(log.startTime))
                        .font(.caption)
                        .foregroundColor(.mutedForeground)
                    
                    if let duration = log.durationSeconds {
                        Text("Duration: \(formatDuration(duration))")
                            .font(.caption)
                            .foregroundColor(.mutedForeground)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.mutedForeground)
            }
            .padding(.spacingMD)
            .contentShape(Rectangle())
        }
        .onTapGesture {
            selectedLog = log
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                logToDelete = log
                showDeleteConfirm = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(log.category.displayName) cry. Recorded \(formatDate(log.startTime))")
        .accessibilityHint("Tap for details, swipe left to delete")
    }
    
    @ViewBuilder
    private func cryLogDetailSheet(_ log: CryLog) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: .spacingLG) {
                    // Category
                    HStack(spacing: .spacingMD) {
                        Circle()
                            .fill(categoryColor(log.category).opacity(0.15))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: log.category.icon)
                                    .font(.title)
                                    .foregroundColor(categoryColor(log.category))
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(log.category.displayName)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.foreground)
                            
                            if let confidence = log.confidence {
                                Text("\(ConfidenceLevel.from(value: confidence).displayName) confidence (\(Int(confidence * 100))%)")
                                    .font(.caption)
                                    .foregroundColor(.mutedForeground)
                            }
                        }
                    }
                    
                    // Details
                    VStack(alignment: .leading, spacing: .spacingSM) {
                        detailRow(label: "Recorded", value: formatDate(log.startTime))
                        
                        if let duration = log.durationSeconds {
                            detailRow(label: "Duration", value: formatDuration(duration))
                        }
                        
                        if let resolvedBy = log.resolvedBy {
                            detailRow(label: "Resolved by", value: resolvedBy)
                        }
                    }
                    
                    // Note
                    if let note = log.note, !note.isEmpty {
                        VStack(alignment: .leading, spacing: .spacingSM) {
                            Text("Notes")
                                .font(.headline)
                                .foregroundColor(.foreground)
                            
                            Text(note)
                                .font(.body)
                                .foregroundColor(.mutedForeground)
                                .padding(.spacingSM)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.surface)
                                .cornerRadius(.radiusSM)
                        }
                    }
                    
                    // Medical disclaimer
                    MedicalDisclaimer(
                        message: "Cry analysis provides general guidance only. It is not a substitute for medical advice. Contact your pediatrician if you have concerns."
                    )
                }
                .padding(.spacingLG)
            }
            .background(Color.background)
            .navigationTitle("Cry Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        selectedLog = nil
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(.mutedForeground)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .foregroundColor(.foreground)
        }
        .padding(.spacingSM)
        .background(Color.surface)
        .cornerRadius(.radiusSM)
    }
    
    private func categoryColor(_ category: CryCategory) -> Color {
        switch category {
        case .hungry: return .eventFeed
        case .tired: return .eventSleep
        case .discomfort: return .warning
        case .pain: return .destructive
        case .unsure: return .mutedForeground
        }
    }
    
    @ViewBuilder
    private func confidenceBars(confidence: Double) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<3) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index < Int(confidence * 3) ? categoryColor(result.category) : Color.mutedForeground.opacity(0.2))
                    .frame(width: 12, height: 4)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        
        if minutes > 0 {
            return "\(minutes)m \(remainingSeconds)s"
        } else {
            return "\(remainingSeconds)s"
        }
    }
    
    private func loadCryLogs() async {
        guard let baby = environment.currentBaby else { return }
        
        do {
            let logs = try await environment.dataStore.fetchCryLogs(for: baby)
            await MainActor.run {
                self.cryLogs = logs
                self.isLoading = false
            }
        } catch {
            Logger.dataError("Failed to load cry logs: \(error.localizedDescription)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    private func deleteCryLog(_ log: CryLog) {
        Task {
            do {
                try await environment.dataStore.deleteCryLog(log)
                await loadCryLogs()
                Haptics.success()
            } catch {
                Logger.dataError("Failed to delete cry log: \(error.localizedDescription)")
                // Show error toast
            }
        }
    }
}

/// Cry log model
struct CryLog: Identifiable, Codable {
    let id: UUID
    let babyId: UUID
    let startTime: Date
    let endTime: Date?
    let category: CryCategory
    let confidence: Double?
    let resolvedBy: String?
    let note: String?
    let createdAt: Date
    let updatedAt: Date
    
    var durationSeconds: Int? {
        guard let endTime = endTime else { return nil }
        return Int(endTime.timeIntervalSince(startTime))
    }
}

#Preview {
    NavigationStack {
        CryHistoryView()
            .environmentObject(AppEnvironment(dataStore: InMemoryDataStore()))
    }
}






