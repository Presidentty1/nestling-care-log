import SwiftUI

/// Monthly calendar grid view with event indicators
/// Shows a full month with colored dots indicating which days have events
struct MonthlyCalendarView: View {
    @Binding var selectedDate: Date
    let eventCountsByDate: [Date: EventDayCounts]
    let onDateSelected: (Date) -> Void
    
    @State private var displayedMonth: Date = Date()
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        VStack(spacing: .spacingMD) {
            // Month/Year Header with Navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                }
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text(monthYearString)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.foreground)
                }
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(canGoForward ? .primary : .mutedForeground.opacity(0.3))
                        .frame(width: 44, height: 44)
                }
                .disabled(!canGoForward)
            }
            .padding(.horizontal, .spacingSM)
            
            // Today button
            Button(action: jumpToToday) {
                Text("Today")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .padding(.horizontal, .spacingMD)
                    .padding(.vertical, .spacingXS)
                    .background(Color.primary.opacity(0.1))
                    .cornerRadius(.radiusSM)
            }
            .opacity(isDisplayingCurrentMonth ? 0.5 : 1.0)
            .disabled(isDisplayingCurrentMonth)
            
            // Day of week headers
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.mutedForeground)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, .spacingSM)
            
            // Calendar Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(daysInMonth, id: \.self) { date in
                    if let date = date {
                        CalendarDayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            eventCounts: eventCountsByDate[normalizedDate(date)],
                            onTap: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedDate = date
                                }
                                onDateSelected(date)
                                Haptics.selection()
                            }
                        )
                    } else {
                        // Empty cell for padding
                        Color.clear
                            .frame(height: 52)
                    }
                }
            }
        }
        .padding(.spacingMD)
        .background(Color.surface)
        .cornerRadius(.radiusLG)
    }
    
    // MARK: - Computed Properties
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }
    
    private var isDisplayingCurrentMonth: Bool {
        calendar.isDate(displayedMonth, equalTo: Date(), toGranularity: .month)
    }
    
    private var canGoForward: Bool {
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
        return nextMonth <= Date()
    }
    
    private var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday else {
            return []
        }
        
        var days: [Date?] = []
        
        // Add leading empty cells
        let leadingEmptyCells = firstWeekday - 1
        days.append(contentsOf: Array(repeating: nil, count: leadingEmptyCells))
        
        // Add days of month
        var currentDate = monthInterval.start
        while currentDate < monthInterval.end {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return days
    }
    
    // MARK: - Actions
    
    private func previousMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) {
            withAnimation(.easeInOut(duration: 0.2)) {
                displayedMonth = newMonth
            }
        }
    }
    
    private func nextMonth() {
        if canGoForward, let newMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) {
            withAnimation(.easeInOut(duration: 0.2)) {
                displayedMonth = newMonth
            }
        }
    }
    
    private func jumpToToday() {
        withAnimation(.easeInOut(duration: 0.2)) {
            displayedMonth = Date()
            selectedDate = Date()
            onDateSelected(Date())
        }
    }
    
    private func normalizedDate(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }
}

// MARK: - Calendar Day Cell
struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let eventCounts: EventDayCounts?
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private var isFutureDate: Bool {
        date > Date()
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(dayNumber)
                    .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                    .foregroundColor(dayTextColor)
                
                // Event indicator dots
                if let counts = eventCounts, counts.hasEvents {
                    HStack(spacing: 2) {
                        if counts.feeds > 0 {
                            Circle()
                                .fill(Color.eventFeed)
                                .frame(width: 4, height: 4)
                        }
                        if counts.sleep > 0 {
                            Circle()
                                .fill(Color.eventSleep)
                                .frame(width: 4, height: 4)
                        }
                        if counts.diapers > 0 {
                            Circle()
                                .fill(Color.eventDiaper)
                                .frame(width: 4, height: 4)
                        }
                    }
                    .frame(height: 6)
                } else {
                    // Spacer to maintain consistent height
                    Color.clear.frame(height: 6)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(backgroundForCell)
            .cornerRadius(.radiusSM)
            .overlay(
                RoundedRectangle(cornerRadius: .radiusSM)
                    .stroke(borderColor, lineWidth: isSelected ? 2 : 0)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isFutureDate)
    }
    
    private var dayTextColor: Color {
        if isFutureDate {
            return .mutedForeground.opacity(0.3)
        } else if isSelected {
            return .white
        } else if isToday {
            return .primary
        } else {
            return .foreground
        }
    }
    
    private var backgroundForCell: Color {
        if isSelected {
            return .primary
        } else if isToday {
            return .primary.opacity(0.1)
        } else {
            return .clear
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return .primary
        } else if isToday {
            return .primary.opacity(0.5)
        } else {
            return .clear
        }
    }
}

// Extension to add convenience methods to EventDayCounts
extension EventDayCounts {
    var hasEvents: Bool {
        feeds > 0 || sleep > 0 || diapers > 0 || tummyTime > 0
    }
    
    var totalCount: Int {
        feeds + sleep + diapers + tummyTime
    }
}

#Preview {
    let today = Date()
    let calendar = Calendar.current
    
    // Sample event counts
    var eventCounts: [Date: EventDayCounts] = [:]
    var todayCounts = EventDayCounts()
    todayCounts.feeds = 3
    todayCounts.sleep = 2
    todayCounts.diapers = 4
    todayCounts.tummyTime = 1
    eventCounts[calendar.startOfDay(for: today)] = todayCounts
    
    if let yesterday = calendar.date(byAdding: .day, value: -1, to: today) {
        var yesterdayCounts = EventDayCounts()
        yesterdayCounts.feeds = 5
        yesterdayCounts.sleep = 1
        yesterdayCounts.diapers = 3
        eventCounts[calendar.startOfDay(for: yesterday)] = yesterdayCounts
    }
    
    return MonthlyCalendarView(
        selectedDate: .constant(today),
        eventCountsByDate: eventCounts,
        onDateSelected: { _ in }
    )
    .padding()
    .background(Color.background)
}
