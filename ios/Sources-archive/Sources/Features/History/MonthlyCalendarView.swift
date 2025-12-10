import SwiftUI

/// Full monthly calendar grid with event indicators
/// Replaces the limited 7-day DayStrip for better navigation
struct MonthlyCalendarView: View {
    @Environment(\.colorScheme) private var colorScheme
    let selectedDate: Date
    let eventsByDate: [Date: DayEventSummary]
    let onDateSelected: (Date) -> Void
    let onMonthChanged: (Date) -> Void
    @Binding var currentMonth: Date
    
    private let calendar = Calendar.current
    private let weekdaySymbols = Calendar.current.shortWeekdaySymbols
    
    // Calculate the days to display for the month
    private var monthDays: [Date?] {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)),
              let monthRange = calendar.range(of: .day, in: .month, for: currentMonth) else {
            return []
        }
        
        // Get the first day of the month
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        
        // Add leading empty days (to align with Sunday)
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        
        // Add all days of the month
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
                
                Text(monthYearString)
                    .font(.title3.bold())
                    .foregroundColor(Color.adaptiveForeground(colorScheme))
                
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
            
            // Today button
            HStack {
                Spacer()
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
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(monthDays.indices, id: \.self) { index in
                    if let date = monthDays[index] {
                        CalendarDayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            isFuture: date > Date(),
                            eventSummary: eventsByDate[normalizeDate(date)],
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
    
    /// Normalize date to midnight for dictionary lookup
    private func normalizeDate(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }
}

/// Individual day cell in the calendar
struct CalendarDayCell: View {
    @Environment(\.colorScheme) private var colorScheme
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isFuture: Bool
    let eventSummary: DayEventSummary?
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                // Day number
                Text("\(calendar.component(.day, from: date))")
                    .font(.body.weight(isSelected || isToday ? .bold : .regular))
                    .foregroundColor(dayTextColor)
                
                // Event indicator dots
                if let summary = eventSummary, !isFuture {
                    HStack(spacing: 2) {
                        if summary.feedCount > 0 {
                            Circle()
                                .fill(Color.eventFeed)
                                .frame(width: 4, height: 4)
                        }
                        if summary.sleepCount > 0 {
                            Circle()
                                .fill(Color.eventSleep)
                                .frame(width: 4, height: 4)
                        }
                        if summary.diaperCount > 0 {
                            Circle()
                                .fill(Color.eventDiaper)
                                .frame(width: 4, height: 4)
                        }
                    }
                    .frame(height: 6)
                } else {
                    Spacer()
                        .frame(height: 6)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(dayBackgroundColor)
            .cornerRadius(.radiusSM)
            .overlay(
                RoundedRectangle(cornerRadius: .radiusSM)
                    .stroke(dayBorderColor, lineWidth: isSelected ? 2 : (isToday ? 1 : 0))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isFuture)
    }
    
    // MARK: - Colors
    
    private var dayTextColor: Color {
        if isFuture {
            return Color.adaptiveTextTertiary(colorScheme)
        }
        if isSelected {
            return Color.adaptivePrimaryForeground(colorScheme)
        }
        if isToday {
            return Color.adaptivePrimary(colorScheme)
        }
        return Color.adaptiveForeground(colorScheme)
    }
    
    private var dayBackgroundColor: Color {
        if isFuture {
            return Color.adaptiveSurface(colorScheme).opacity(0.3)
        }
        if isSelected {
            return Color.adaptivePrimary(colorScheme)
        }
        return Color.adaptiveSurface(colorScheme)
    }
    
    private var dayBorderColor: Color {
        if isSelected {
            return Color.adaptivePrimary(colorScheme)
        }
        if isToday {
            return Color.adaptivePrimary(colorScheme).opacity(0.5)
        }
        return Color.clear
    }
}

/// Summary of events for a specific day (for calendar display)
struct DayEventSummary: Equatable {
    let date: Date
    let feedCount: Int
    let sleepCount: Int
    let diaperCount: Int
    let tummyTimeCount: Int
    
    var totalCount: Int {
        feedCount + sleepCount + diaperCount + tummyTimeCount
    }
    
    var hasEvents: Bool {
        totalCount > 0
    }
}

#Preview {
    @Previewable @State var selectedDate = Date()
    @Previewable @State var currentMonth = Date()
    
    let today = Date()
    let calendar = Calendar.current
    
    // Create sample event data
    var eventsByDate: [Date: DayEventSummary] = [:]
    for dayOffset in -10...0 {
        if let date = calendar.date(byAdding: .day, value: dayOffset, to: today) {
            let normalizedDate = calendar.startOfDay(for: date)
            eventsByDate[normalizedDate] = DayEventSummary(
                date: normalizedDate,
                feedCount: Int.random(in: 0...8),
                sleepCount: Int.random(in: 0...5),
                diaperCount: Int.random(in: 0...10),
                tummyTimeCount: Int.random(in: 0...2)
            )
        }
    }
    
    return MonthlyCalendarView(
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

