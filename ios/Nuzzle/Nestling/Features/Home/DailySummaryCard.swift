import SwiftUI

struct DailySummaryCard: View {
    let summary: DaySummary
    let isCollapsedByDefault: Bool
    var onTileTapped: ((EventTypeFilter) -> Void)?

    @State private var isCollapsed: Bool
    
    init(summary: DaySummary, isCollapsedByDefault: Bool = false, onTileTapped: ((EventTypeFilter) -> Void)? = nil) {
        self.summary = summary
        self.isCollapsedByDefault = isCollapsedByDefault
        self.onTileTapped = onTileTapped
        _isCollapsed = State(initialValue: isCollapsedByDefault)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: .spacingSM) {
            HStack {
                Label("Today", systemImage: "chart.bar.fill")
                    .font(.headline)
                    .foregroundColor(.foreground)
                Spacer()
                Button(action: toggle) {
                    Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                        .background(Color.surface.opacity(0.9))
                        .cornerRadius(.radiusSM)
                        .overlay(
                            RoundedRectangle(cornerRadius: .radiusSM)
                                .stroke(Color.cardBorder, lineWidth: 1)
                        )
                }
                .accessibilityLabel(isCollapsed ? "Expand daily summary" : "Collapse daily summary")
            }
            
            if !isCollapsed {
                HStack(spacing: .spacingMD) {
                    summaryTile(title: "Feeds", value: "\(summary.feedCount)", icon: "drop.fill", color: .eventFeed, filter: .feeds)
                    summaryTile(title: "Diapers", value: "\(summary.diaperCount)", icon: "drop.circle.fill", color: .eventDiaper, filter: .diapers)
                    summaryTile(title: "Sleep", value: summary.sleepDisplay, icon: "moon.fill", color: .eventSleep, filter: .sleep)
                    summaryTile(title: "Tummy", value: "\(summary.tummyTimeCount)", icon: "figure.child", color: .eventTummy, filter: .tummy)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.spacingMD)
        .background(Color.surface)
        .cornerRadius(.radiusLG)
        .overlay(
            RoundedRectangle(cornerRadius: .radiusLG)
                .stroke(Color.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Daily summary of logged events")
    }
    
    private func summaryTile(title: String, value: String, icon: String, color: Color, filter: EventTypeFilter) -> some View {
        Button(action: {
            onTileTapped?(filter)
            Haptics.selection()
            AnalyticsService.shared.trackSummaryFilterApplied(filter: filter.rawValue)
        }) {
            VStack(alignment: .leading, spacing: .spacingXS) {
                HStack(spacing: .spacingXS) {
                    Image(systemName: icon)
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(color)
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.mutedForeground)
                }
                Text(value)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.foreground)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.spacingSM)
            .background(Color.elevated)
            .cornerRadius(.radiusMD)
            .overlay(
                RoundedRectangle(cornerRadius: .radiusMD)
                    .stroke(Color.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Filter by \(title.lowercased()): \(value) events")
        .accessibilityHint("Tap to view only \(title.lowercased()) events in timeline")
    }
    
    private func toggle() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
            isCollapsed.toggle()
        }
        Haptics.selection()
    }
}

