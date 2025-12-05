import SwiftUI

struct TimelineRow: View {
    let event: Event
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onDuplicate: (() -> Void)?
    @State private var showDeleteConfirmation = false
    @Environment(\.colorScheme) private var colorScheme
    
    init(event: Event, onEdit: @escaping () -> Void, onDelete: @escaping () -> Void, onDuplicate: (() -> Void)? = nil) {
        self.event = event
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onDuplicate = onDuplicate
    }
    
    var body: some View {
        HStack(spacing: .spacingMD) {
            // Icon
            Image(systemName: event.type.iconName)
                .foregroundColor(colorForEventType(event.type))
                .frame(width: 32, height: 32)
                .accessibilityHidden(true)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(event.type.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(Color.adaptiveForeground(colorScheme))
                    .lineLimit(nil)

                Text(formatEventDetails(event))
                    .font(.caption)
                    .foregroundColor(Color.adaptiveMutedForeground(colorScheme))
                    .lineLimit(nil)
            }
            
            Spacer()
            
            // Time
            Text(formatTime(event.startTime))
                .font(.caption)
                .foregroundColor(Color.adaptiveMutedForeground(colorScheme))
            
            // Menu
            Menu {
                Button(action: {
                    Haptics.medium()
                    onEdit()
                }) {
                    Label("Edit", systemImage: "pencil")
                }
                
                if let onDuplicate = onDuplicate {
                    Button(action: {
                        Haptics.light()
                        onDuplicate()
                    }) {
                        Label("Duplicate", systemImage: "doc.on.doc")
                    }
                }
                
                Button(action: {
                    Haptics.light()
                    copySummaryToPasteboard()
                }) {
                    Label("Copy Summary", systemImage: "doc.on.clipboard")
                }
                
                Button(role: .destructive, action: {
                    Haptics.heavy()
                    showDeleteConfirmation = true
                }) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(Color.adaptiveMutedForeground(colorScheme))
                    .padding(8)
            }
            .accessibilityLabel("More options for \(event.type.displayName)")
        }
        .padding(.spacingMD)
        .background(Color.adaptiveSurface(colorScheme))
        .cornerRadius(.radiusMD)
        .contextMenu {
            Button(action: {
                Haptics.medium()
                onEdit()
            }) {
                Label("Edit", systemImage: "pencil")
            }
            
            if let onDuplicate = onDuplicate {
                Button(action: {
                    Haptics.light()
                    onDuplicate()
                }) {
                    Label("Duplicate", systemImage: "doc.on.doc")
                }
            }
            
            Button(action: {
                Haptics.light()
                copySummaryToPasteboard()
            }) {
                Label("Copy Summary", systemImage: "doc.on.clipboard")
            }
            
            Button(role: .destructive, action: {
                Haptics.heavy()
                showDeleteConfirmation = true
            }) {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: {
                Haptics.heavy()
                showDeleteConfirmation = true
            }) {
                Label("Delete", systemImage: "trash")
            }
            
            Button(action: {
                Haptics.medium()
                onEdit()
            }) {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.primary)
        }
        .motionTransition(.opacity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Swipe right for edit and delete actions")
        .accessibilityActions {
            Button("Edit") {
                Haptics.medium()
                onEdit()
            }
            Button("Delete") {
                Haptics.heavy()
                showDeleteConfirmation = true
            }
        }
        .alert("Delete Event?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive, action: onDelete)
        } message: {
            Text("This will permanently delete this \(event.type.displayName.lowercased()) event.")
        }
    }
    
    private func colorForEventType(_ type: EventType) -> Color {
        switch type {
        case .feed: return .eventFeed
        case .diaper: return .eventDiaper
        case .sleep: return .eventSleep
        case .tummyTime: return .eventTummy
        }
    }
    
    private func formatEventDetails(_ event: Event) -> String {
        switch event.type {
        case .feed:
            if let amount = event.amount, let unit = event.unit {
                return "\(Int(amount)) \(unit)"
            }
            return event.subtype?.capitalized ?? ""
        case .diaper:
            return event.subtype?.capitalized ?? ""
        case .sleep:
            if let duration = event.durationMinutes {
                return "\(duration) min"
            }
            return event.subtype ?? ""
        case .tummyTime:
            if let duration = event.durationMinutes {
                return "\(duration) min"
            }
            return ""
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        // Show "Just now" for events within the last minute
        if interval < 60 {
            return "Just now"
        }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private var accessibilityLabel: String {
        var label = "\(event.type.displayName) event"
        if let details = formatEventDetails(event) as String? {
            label += ", \(details)"
        }
        label += ", at \(formatTime(event.startTime))"
        return label
    }
    
    /// Copy event summary to pasteboard (e.g., "Feed · 120 ml · 8:24 pm")
    private func copySummaryToPasteboard() {
        let timeString = formatTime(event.startTime)
        let details = formatEventDetails(event)
        let summary = "\(event.type.displayName) · \(details) · \(timeString)"
        
        UIPasteboard.general.string = summary
        Haptics.success()
    }
}

#Preview {
    VStack(spacing: 8) {
        TimelineRow(
            event: Event.mockFeed(babyId: UUID()),
            onEdit: {},
            onDelete: {}
        )
        TimelineRow(
            event: Event.mockSleep(babyId: UUID()),
            onEdit: {},
            onDelete: {}
        )
    }
    .padding()
}

