import SwiftUI

/// Detailed view for a single event with edit/delete options
struct EventDetailView: View {
    let event: Event
    let baby: Baby
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onClose: () -> Void
    
    @State private var showDeleteConfirm = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacingLG) {
                    // Event type header
                    HStack(spacing: .spacingMD) {
                        Circle()
                            .fill(eventColor.opacity(0.15))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: eventIcon)
                                    .font(.title)
                                    .foregroundColor(eventColor)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.type.displayName)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.foreground)
                            
                            Text(formatDateTime(event.startTime))
                                .font(.caption)
                                .foregroundColor(.mutedForeground)
                        }
                        
                        Spacer()
                    }
                    
                    // Details card
                    CardView(variant: .default) {
                        VStack(spacing: .spacingMD) {
                            // Type-specific details
                            detailsForEventType
                            
                            // Duration (if applicable)
                            if let endTime = event.endTime {
                                Divider()
                                detailRow(
                                    label: "Duration",
                                    value: formatDuration(from: event.startTime, to: endTime)
                                )
                            }
                            
                            // Note
                            if let note = event.note, !note.isEmpty {
                                Divider()
                                VStack(alignment: .leading, spacing: .spacingSM) {
                                    Text("Notes")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.mutedForeground)
                                    
                                    Text(note)
                                        .font(.body)
                                        .foregroundColor(.foreground)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.spacingMD)
                    }
                    
                    // Actions
                    VStack(spacing: .spacingSM) {
                        PrimaryButton("Edit", icon: "pencil") {
                            Haptics.light()
                            onEdit()
                        }
                        
                        DestructiveButton("Delete", icon: "trash") {
                            Haptics.warning()
                            showDeleteConfirm = true
                        }
                    }
                    .padding(.horizontal, .spacingMD)
                }
                .padding(.spacingLG)
            }
            .background(Color.background)
            .navigationTitle("Event Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onClose()
                    }
                }
            }
            .alert("Delete Event", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Haptics.success()
                    onDelete()
                    onClose()
                }
            } message: {
                Text("Are you sure you want to delete this \(event.type.displayName.lowercased()) event? This action cannot be undone.")
            }
        }
    }
    
    @ViewBuilder
    private var detailsForEventType: some View {
        switch event.type {
        case .feed:
            feedDetails
        case .sleep:
            sleepDetails
        case .diaper:
            diaperDetails
        case .tummyTime:
            tummyTimeDetails
        }
    }
    
    @ViewBuilder
    private var feedDetails: some View {
        if let subtype = event.subtype {
            detailRow(label: "Type", value: subtype.capitalized)
        }
        
        if let side = event.side {
            detailRow(label: "Side", value: side.capitalized)
        }
        
        if let amount = event.amount, let unit = event.unit {
            detailRow(label: "Amount", value: "\(Int(amount)) \(unit)")
        }
    }
    
    @ViewBuilder
    private var sleepDetails: some View {
        detailRow(label: "Start", value: formatTime(event.startTime))
        
        if let endTime = event.endTime {
            detailRow(label: "End", value: formatTime(endTime))
        } else {
            detailRow(label: "Status", value: "In progress")
        }
    }
    
    @ViewBuilder
    private var diaperDetails: some View {
        if let subtype = event.subtype {
            detailRow(label: "Type", value: subtype.capitalized)
        }
    }
    
    @ViewBuilder
    private var tummyTimeDetails: some View {
        if let duration = event.durationMinutes {
            detailRow(label: "Duration", value: "\(duration) minutes")
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
                .fontWeight(.medium)
                .foregroundColor(.foreground)
        }
    }
    
    private var eventColor: Color {
        switch event.type {
        case .feed: return .eventFeed
        case .sleep: return .eventSleep
        case .diaper: return .eventDiaper
        case .tummyTime: return .eventTummy
        }
    }
    
    private var eventIcon: String {
        switch event.type {
        case .feed: return "fork.knife"
        case .sleep: return "moon.zzz.fill"
        case .diaper: return "drop.fill"
        case .tummyTime: return "figure.cooldown"
        }
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(from start: Date, to end: Date) -> String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: start, to: end)
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

#Preview {
    EventDetailView(
        event: Event(
            id: UUID(),
            babyId: UUID(),
            type: .feed,
            subtype: "bottle",
            amount: 120,
            unit: "ml",
            side: nil,
            startTime: Date(),
            endTime: nil,
            durationMinutes: nil,
            note: "Fed well, seemed very hungry",
            createdAt: Date(),
            updatedAt: Date()
        ),
        baby: Baby(
            id: UUID(),
            name: "Test Baby",
            dateOfBirth: Date(),
            sex: "f",
            primaryFeedingStyle: "bottle",
            timezone: "America/Los_Angeles",
            createdAt: Date(),
            updatedAt: Date()
        ),
        onEdit: {},
        onDelete: {},
        onClose: {}
    )
}


