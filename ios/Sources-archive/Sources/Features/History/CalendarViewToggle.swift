import SwiftUI

/// Toggle between dot calendar (free) and heatmap calendar (premium)
struct CalendarViewToggle: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var showHeatmap: Bool
    let isPro: Bool
    let onUpgrade: () -> Void
    
    var body: some View {
        HStack(spacing: .spacingMD) {
            // Dot view option
            CalendarViewOption(
                title: "Dots",
                icon: "circle.grid.3x3.fill",
                isSelected: !showHeatmap,
                action: {
                    showHeatmap = false
                    Haptics.light()
                }
            )
            
            // Heatmap option (Premium)
            ZStack(alignment: .topTrailing) {
                CalendarViewOption(
                    title: "Heatmap",
                    icon: "chart.bar.fill",
                    isSelected: showHeatmap,
                    action: {
                        if isPro {
                            showHeatmap = true
                            Haptics.light()
                        } else {
                            onUpgrade()
                            Haptics.warning()
                        }
                    }
                )
                
                // Pro badge
                if !isPro {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                        .padding(4)
                        .background(Color.adaptiveSurface(colorScheme))
                        .clipShape(Circle())
                        .offset(x: 4, y: -4)
                }
            }
        }
        .padding(.horizontal, .spacingMD)
    }
}

struct CalendarViewOption: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: .spacingXS) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? Color.adaptivePrimaryForeground(colorScheme) : Color.adaptiveTextSecondary(colorScheme))
                
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundColor(isSelected ? Color.adaptivePrimaryForeground(colorScheme) : Color.adaptiveTextSecondary(colorScheme))
            }
            .frame(maxWidth: .infinity)
            .padding(.spacingMD)
            .background(
                RoundedRectangle(cornerRadius: .radiusMD)
                    .fill(isSelected ? Color.adaptivePrimary(colorScheme) : Color.adaptiveSurface(colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: .radiusMD)
                    .stroke(isSelected ? Color.adaptivePrimary(colorScheme) : Color.adaptiveBorder(colorScheme), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack(spacing: .spacingMD) {
        // Free user (can't access heatmap)
        CalendarViewToggle(
            showHeatmap: .constant(false),
            isPro: false,
            onUpgrade: {
                print("Show upgrade prompt")
            }
        )
        
        // Pro user (can toggle)
        CalendarViewToggle(
            showHeatmap: .constant(true),
            isPro: true,
            onUpgrade: {}
        )
    }
    .padding()
}

