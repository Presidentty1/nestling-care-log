import SwiftUI
import UIKit

struct TimelineRow: View {
    let event: Event
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onDuplicate: (() -> Void)?
    @Binding var showToast: ToastMessage?
    @State private var showDeleteConfirmation = false

    init(event: Event, onEdit: @escaping () -> Void, onDelete: @escaping () -> Void, onDuplicate: (() -> Void)? = nil, showToast: Binding<ToastMessage?>? = nil) {
        self.event = event
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onDuplicate = onDuplicate
        self._showToast = showToast ?? .constant(nil)
    }
    
    var body: some View {
        HStack(spacing: .spacingMD) {
            // Color indicator bar - BOLDER for better scanning
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            colorForEventType(event.type),
                            colorForEventType(event.type).opacity(0.7)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 6)
                .cornerRadius(3)
            
            // Icon with background circle
            ZStack {
                Circle()
                    .fill(colorForEventType(event.type).opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: event.type.iconName)
                    .foregroundColor(colorForEventType(event.type))
                    .font(.system(size: 16, weight: .medium))
            }
            .accessibilityHidden(true)
            
            // Content with improved typography hierarchy
            VStack(alignment: .leading, spacing: 4) {
                Text(event.type.displayName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.foreground)
                    .lineLimit(nil)
                
                Text(formatEventDetails(event))
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.mutedForeground)
                    .lineLimit(nil)
                
                if let attribution = attributionText() {
                    Text(attribution)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.mutedForeground.opacity(0.9))
                }
            }

            // Photo thumbnails (if any)
            if let photoUrls = event.photoUrls, !photoUrls.isEmpty {
                let photos = PhotoStorageService.shared.loadPhotos(for: event.id)
                if !photos.isEmpty {
                    HStack(spacing: 2) {
                        ForEach(photos.prefix(2), id: \.self) { photo in
                            Image(uiImage: photo)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 24, height: 24)
                                .cornerRadius(4)
                                .clipped()
                        }
                        if photos.count > 2 {
                            Text("+\(photos.count - 2)")
                                .font(.caption2)
                                .foregroundColor(.mutedForeground)
                                .frame(width: 24, height: 24)
                                .background(Color.surface)
                                .cornerRadius(4)
                        }
                    }
                }
            }

            Spacer()

            // Time with lighter color
            Text(formatRelativeTime(event.startTime))
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.mutedForeground.opacity(0.7))
            
            // Menu
            Menu {
                Button(action: {
                    Haptics.light()
                    if let onDuplicate = onDuplicate {
                        onDuplicate()
                    }
                }) {
                    Label("Log Again", systemImage: "arrow.clockwise")
                }
                
                Button(action: {
                    Haptics.medium()
                    onEdit()
                }) {
                    Label("Edit", systemImage: "pencil")
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
                    .foregroundColor(.mutedForeground)
                    .padding(8)
            }
            .accessibilityLabel("More options for \(event.type.displayName)")
        }
        .padding(.spacingMD)
        .background(Color.surface)
        .cornerRadius(.radiusMD)
        .overlay(
            RoundedRectangle(cornerRadius: .radiusMD)
                .stroke(Color.cardBorder, lineWidth: 1)
        )
        // UX-06: Make entire row tappable to edit (not just menu button)
        .contentShape(Rectangle())
        .onTapGesture {
            Haptics.light()
            onEdit()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                deleteWithUndo()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                Haptics.light()
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.primary)

            if let onDuplicate = onDuplicate {
                Button {
                    Haptics.light()
                    onDuplicate()
                } label: {
                    Label("Log Again", systemImage: "arrow.clockwise")
                }
                .tint(.secondary)
            }
        }
        .contextMenu {
            Button(action: {
                Haptics.light()
                if let onDuplicate = onDuplicate {
                    onDuplicate()
                }
            }) {
                Label("Log Again", systemImage: "arrow.clockwise")
            }
            
            Button(action: {
                Haptics.medium()
                onEdit()
            }) {
                Label("Edit", systemImage: "pencil")
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
        case .cry: return .eventCry
        }
    }
    
    private func formatEventDetails(_ event: Event) -> String {
        switch event.type {
        case .feed:
            if let amount = event.amount, let unit = event.unit {
                // Amounts are stored in ml internally
                // Validate amount is reasonable (prevent display of corrupted data)
                let maxML = AppConstants.maximumFeedAmountML
                if amount > maxML * 10 {
                    // Likely corrupted data - show generic message
                    return event.subtype?.capitalized ?? "Feed"
                }
                
                let displayAmount: Double
                let displayUnit: String
                
                if unit == "oz" {
                    // User entered oz, but amount is stored in ml - convert back to oz for display
                    displayAmount = amount / AppConstants.mlPerOz
                    displayUnit = "oz"
                    
                    // Clamp to reasonable oz values
                    let clampedAmount = min(displayAmount, AppConstants.maximumFeedAmountOZ)
                    
                    // Format appropriately
                    if clampedAmount >= 10 {
                        return "\(Int(clampedAmount)) \(displayUnit)"
                    } else if clampedAmount >= 1 {
                        return String(format: "%.1f \(displayUnit)", clampedAmount)
                    } else {
                        return String(format: "%.2f \(displayUnit)", clampedAmount)
                    }
                } else {
                    // User entered ml, amount is already in ml
                    displayAmount = amount
                    displayUnit = "ml"
                    
                    // Clamp to reasonable ml values
                    let clampedAmount = min(displayAmount, maxML)
                    
                    // Format appropriately
                    if clampedAmount >= 100 {
                        return "\(Int(clampedAmount)) \(displayUnit)"
                    } else if clampedAmount >= 10 {
                        return String(format: "%.1f \(displayUnit)", clampedAmount)
                    } else {
                        return String(format: "%.2f \(displayUnit)", clampedAmount)
                    }
                }
            }
            return event.subtype?.capitalized ?? ""
        case .diaper:
            return event.subtype?.capitalized ?? ""
        case .sleep:
            if let duration = event.durationMinutes {
                if duration < 1 {
                    return "Just now" // Don't show "0 min" for instant sleeps
                }
                return "\(duration) min"
            }
            return event.subtype ?? ""
        case .tummyTime:
            if let duration = event.durationMinutes {
                return "\(duration) min"
            }
            return ""
        case .cry:
            if let duration = event.durationMinutes, duration > 0 {
                return "\(duration) sec"
            }
            return "Cry logged"
        }
    }
    
    private func attributionText() -> String? {
        guard let createdBy = event.createdBy else {
            return nil
        }
        
        if let currentIdString = UserDefaults.standard.string(forKey: "current_user_id"),
           let currentId = UUID(uuidString: currentIdString),
           currentId == createdBy {
            return "Logged by you"
        }
        
        return "Logged by caregiver"
    }
    
    private func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private var accessibilityLabel: String {
        var label = "\(event.type.displayName)"
        
        // Add type-specific details
        switch event.type {
        case .feed:
            if let amount = event.amount, let unit = event.unit {
                let displayAmount: Double
                let displayUnit: String
                if unit == "oz" {
                    displayAmount = amount / AppConstants.mlPerOz
                    displayUnit = "ounces"
                } else {
                    displayAmount = amount
                    displayUnit = "milliliters"
                }
                // Clamp to reasonable values
                let maxML = AppConstants.maximumFeedAmountML
                let maxOZ = AppConstants.maximumFeedAmountOZ
                let clampedAmount = min(displayAmount, unit == "oz" ? maxOZ : maxML)
                label += ", \(Int(clampedAmount)) \(displayUnit)"
            }
        case .diaper:
            if let subtype = event.subtype {
                label += ", \(subtype)"
            }
        case .sleep:
            if let duration = event.durationMinutes {
                if duration < 1 {
                    label += ", logged just now"
                } else {
                    label += ", \(duration) minutes"
                }
            }
        case .tummyTime:
            if let duration = event.durationMinutes {
                label += ", \(duration) minutes"
            }
        case .cry:
            if let duration = event.durationMinutes {
                label += ", \(duration) seconds"
            }
        }
        
        let timeAgo = DateUtils.formatRelativeTime(event.startTime)
        label += ", logged \(timeAgo)"
        
        return label
    }

    private func deleteWithUndo() {
        guard PolishFeatureFlags.shared.swipeActionsEnabled else {
            // Fallback to regular delete if feature flag is disabled
            onDelete()
            return
        }

        Haptics.heavy()
        // The undo functionality is handled by the HomeViewModel's deleteEvent method
        // which integrates with UndoManager
        onDelete()
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

