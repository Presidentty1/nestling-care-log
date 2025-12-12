import SwiftUI

struct TodayHeaderBar: View {
    let baby: Baby?
    let onDateTap: () -> Void
    
    var body: some View {
        HStack(spacing: .spacingMD) {
            // Baby avatar and info
            if let baby = baby {
                HStack(spacing: .spacingSM) {
                    // Avatar circle with initial
                    ZStack {
                        Circle()
                            .fill(Color.primary.opacity(0.1))
                            .frame(width: 40, height: 40)
                        
                        Text(baby.name.prefix(1).uppercased())
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    // Name and age
                    VStack(alignment: .leading, spacing: 2) {
                        Text(baby.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.foreground)
                        
                        Text(ageText(for: baby))
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.mutedForeground)
                    }
                }
            } else {
                // Placeholder for no baby
                HStack(spacing: .spacingSM) {
                    ZStack {
                        Circle()
                            .fill(Color.surface)
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "person.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.mutedForeground)
                    }
                    
                    Text("No baby selected")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.mutedForeground)
                }
            }
            
            Spacer()
            
            // Date selector pill button
            Button(action: onDateTap) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                    
                    Text(dateText())
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.foreground)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.surface)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.cardBorder, lineWidth: 1)
                )
            }
            .accessibilityLabel("Select date, currently showing \(dateText())")
        }
        .padding(.horizontal, .spacingLG)
        .padding(.vertical, .spacingMD)
        .background(Color.background)
    }
    
    private func ageText(for baby: Baby) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        let components = calendar.dateComponents([.year, .month, .weekOfMonth, .day], from: baby.dateOfBirth, to: now)
        
        if let years = components.year, years > 0 {
            return years == 1 ? "1 year" : "\(years) years"
        } else if let months = components.month, months > 0 {
            let weeks = components.weekOfMonth ?? 0
            if months == 0 && weeks > 0 {
                return weeks == 1 ? "1 week" : "\(weeks) weeks"
            }
            return months == 1 ? "1 month" : "\(months) months"
        } else if let weeks = components.weekOfMonth, weeks > 0 {
            return weeks == 1 ? "1 week" : "\(weeks) weeks"
        } else if let days = components.day, days >= 0 {
            return days == 1 ? "1 day" : "\(days) days"
        }
        
        return "newborn"
    }
    
    private func dateText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let dateString = formatter.string(from: Date())
        return "Today · \(dateString)"
    }
}

#Preview {
    VStack(spacing: 20) {
        TodayHeaderBar(
            baby: Baby(
                name: "Emma",
                dateOfBirth: Calendar.current.date(byAdding: .month, value: -3, to: Date())!,
                sex: .female
            ),
            onDateTap: {}
        )
        
        TodayHeaderBar(
            baby: Baby(
                name: "Lucas",
                dateOfBirth: Calendar.current.date(byAdding: .day, value: -14, to: Date())!,
                sex: .male
            ),
            onDateTap: {}
        )
        
        TodayHeaderBar(
            baby: nil,
            onDateTap: {}
        )
    }
    .background(Color.background)
}

