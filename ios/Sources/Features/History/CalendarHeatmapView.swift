import SwiftUI

/// Premium calendar heatmap showing activity intensity
/// Darker colors = more events logged that day
/// Part of Premium subscription features
struct CalendarHeatmapView: View {
    @Environment(\.colorScheme) private var colorScheme
    let selectedDate: Date
    let eventsByDate: [Date: DayEventSummary]
    let onDateSelected: (Date) -> Void
    let onMonthChanged: (Date) -> Void
    @Binding var currentMonth: Date
    
    private let calendar = Calendar.current
    private let weekdaySymbols = Calendar.current.shortWeekdaySymbols
    
    // Calculate max events for intensity scaling
    private var maxEventsInMonth: Int {
        eventsByDate.values.map { $0.totalCount }.max() ?? 1
    }
    
    // Calculate the days to display for the month
    private var monthDays: [Date?] {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)),
              let monthRange = calendar.range(of: .day, in: .month, for: currentMonth) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        
        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                days.append(date)
            }
        }
        
        return days
    }
    
    var body: some View {
        VStack(spacing: .spacingMD) {
            // Month navigation header
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(Color.adaptivePrimary(colorScheme))
                        .frame(width: 44, height: 44)
                }
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text(monthYearString)
                        .font(.title3.bold())
                        .foregroundColor(Color.adaptiveForeground(colorScheme))
                    
                    // Premium badge
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                        Text("PREMIUM HEATMAP")
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                    }
                }
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(canGoToNextMonth ? Color.adaptivePrimary(colorScheme) : Color.adaptiveTextTertiary(colorScheme))
                        .frame(width: 44, height: 44)
                }
                .disabled(!canGoToNextMonth)
            }
            .padding(.horizontal, .spacingMD)
            
            // Today button + legend
            HStack {
                Button(action: jumpToToday) {
                    HStack(spacing: .spacingXS) {
                        Image(systemName: "calendar.circle.fill")
                            .font(.caption)
                        Text("Today")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundColor(Color.adaptivePrimary(colorScheme))
                    .padding(.horizontal, .spacingSM)
                    .padding(.vertical, .spacingXS)
                    .background(Color.adaptivePrimary(colorScheme).opacity(0.1))
                    .cornerRadius(.radiusSM)
                }
                
                Spacer()
                
                // Intensity legend
                HStack(spacing: 4) {
                    Text("Less")
                        .font(.caption2)
                        .foregroundColor(Color.adaptiveTextTertiary(colorScheme))
                    
                    ForEach(0..<5) { intensity in
                        Rectangle()
                            .fill(heatmapColor(for: CGFloat(intensity) / 4.0))
                            .frame(width: 12, height: 12)
                            .cornerRadius(2)
                    }
                    
                    Text("More")
                        .font(.caption2)
                        .foregroundColor(Color.adaptiveTextTertiary(colorScheme))
                }
            }
            .padding(.horizontal, .spacingMD)
            
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, .spacingMD)
            
            // Calendar heatmap grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(monthDays.indices, id: \.self) { index in
                    if let date = monthDays[index] {
                        CalendarHeatmapCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            isFuture: date > Date(),
                            eventSummary: eventsByDate[normalizeDate(date)],
                            maxEvents: maxEventsInMonth,
                            onTap: {
                                onDateSelected(date)
                                Haptics.light()
                            }
                        )
                    } else {
                        // Empty cell for padding
                        Color.clear
                            .frame(height: 60)
                    }
                }
            }
            .padding(.horizontal, .spacingMD)
        }
        .padding(.vertical, .spacingMD)
        .background(Color.adaptiveSurface(colorScheme))
        .cornerRadius(.radiusMD)
    }
    
    // MARK: - Computed Properties
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    private var canGoToNextMonth: Bool {
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) else {
            return false
        }
        return nextMonth <= Date()
    }
    
    // MARK: - Heatmap Colors
    
    private func heatmapColor(for intensity: CGFloat) -> Color {
        // Gradient from light to dark primary color
        return Color.adaptivePrimary(colorScheme).opacity(0.2 + (intensity * 0.8))
    }
    
    // MARK: - Actions
    
    private func previousMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newMonth
            onMonthChanged(newMonth)
            Haptics.light()
        }
    }
    
    private func nextMonth() {
        guard canGoToNextMonth else { return }
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newMonth
            onMonthChanged(newMonth)
            Haptics.light()
        }
    }
    
    private func jumpToToday() {
        let today = Date()
        currentMonth = today
        onDateSelected(today)
        onMonthChanged(today)
        Haptics.medium()
    }
    
    private func normalizeDate(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }
}

/// Individual heatmap cell showing activity intensity
struct CalendarHeatmapCell: View {
    @Environment(\.colorScheme) private var colorScheme
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isFuture: Bool
    let eventSummary: DayEventSummary?
    let maxEvents: Int
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    // Calculate intensity (0.0 to 1.0)
    private var intensity: CGFloat {
        guard let summary = eventSummary, maxEvents > 0 else {
            return 0
        }
        return CGFloat(summary.totalCount) / CGFloat(maxEvents)
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Heatmap background
                RoundedRectangle(cornerRadius: .radiusSM)
                    .fill(heatmapBackgroundColor)
                
                // Day number
                Text("\(calendar.component(.day, from: date))")
                    .font(.body.weight(isSelected || isToday ? .bold : .regular))
                    .foregroundColor(dayTextColor)
                
                // Selected/Today indicator
                if isSelected || isToday {
                    RoundedRectangle(cornerRadius: .radiusSM)
                        .stroke(isSelected ? Color.adaptivePrimaryForeground(colorScheme) : Color.adaptivePrimary(colorScheme), lineWidth: isSelected ? 3 : 2)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isFuture)
    }
    
    // MARK: - Colors
    
    private var heatmapBackgroundColor: Color {
        if isFuture {
            return Color.adaptiveSurface(colorScheme).opacity(0.3)
        }
        
        if eventSummary == nil || intensity == 0 {
            return Color.adaptiveSurface(colorScheme)
        }
        
        // Apply heatmap intensity
        return Color.adaptivePrimary(colorScheme).opacity(0.15 + (intensity * 0.75))
    }
    
    private var dayTextColor: Color {
        if isFuture {
            return Color.adaptiveTextTertiary(colorScheme)
        }
        
        // Use contrasting color for high-intensity days
        if intensity > 0.6 {
            return Color.adaptivePrimaryForeground(colorScheme)
        }
        
        if isToday {
            return Color.adaptivePrimary(colorScheme)
        }
        
        return Color.adaptiveForeground(colorScheme)
    }
}

#Preview {
    @Previewable @State var selectedDate = Date()
    @Previewable @State var currentMonth = Date()
    
    let today = Date()
    let calendar = Calendar.current
    
    // Create sample event data with varying intensities
    var eventsByDate: [Date: DayEventSummary] = [:]
    for dayOffset in -25...0 {
        if let date = calendar.date(byAdding: .day, value: dayOffset, to: today) {
            let normalizedDate = calendar.startOfDay(for: date)
            // Vary intensity for visualization
            let multiplier = dayOffset % 3 == 0 ? 2 : 1
            eventsByDate[normalizedDate] = DayEventSummary(
                date: normalizedDate,
                feedCount: Int.random(in: 0...4) * multiplier,
                sleepCount: Int.random(in: 0...3) * multiplier,
                diaperCount: Int.random(in: 0...5) * multiplier,
                tummyTimeCount: Int.random(in: 0...1)
            )
        }
    }
    
    return CalendarHeatmapView(
        selectedDate: selectedDate,
        eventsByDate: eventsByDate,
        onDateSelected: { date in
            selectedDate = date
        },
        onMonthChanged: { month in
            print("Month changed to \(month)")
        },
        currentMonth: $currentMonth
    )
    .padding()
}

