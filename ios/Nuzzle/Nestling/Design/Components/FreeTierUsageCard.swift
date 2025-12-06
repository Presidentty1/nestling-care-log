import SwiftUI

/// Card showing free tier usage with upgrade CTA
struct FreeTierUsageCard: View {
    let used: Int
    let limit: Int
    let featureName: String
    let onUpgrade: () -> Void
    
    private var remaining: Int {
        max(0, limit - used)
    }
    
    private var progress: Double {
        limit > 0 ? Double(used) / Double(limit) : 0
    }
    
    private var isLimitReached: Bool {
        used >= limit
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: .spacingMD) {
            HStack {
                Image(systemName: isLimitReached ? "exclamationmark.circle.fill" : "info.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(isLimitReached ? .destructive : .primary)
                
                Text(isLimitReached ? "Daily limit reached" : "Free tier")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.foreground)
                
                Spacer()
                
                Button(action: onUpgrade) {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 12))
                        Text("Upgrade")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, .spacingMD)
                    .padding(.vertical, .spacingSM)
                    .background(
                        LinearGradient(
                            colors: [Color.primary, Color.primary.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(.radiusMD)
                }
            }
            
            // Progress bar
            VStack(alignment: .leading, spacing: .spacingXS) {
                HStack {
                    Text("\(used) of \(limit) \(featureName)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.mutedForeground)
                    
                    Spacer()
                    
                    if !isLimitReached {
                        Text("\(remaining) left")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)
                    } else {
                        Text("Upgrade for unlimited")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.mutedForeground.opacity(0.15))
                            .frame(height: 8)
                        
                        // Progress fill
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: isLimitReached 
                                        ? [Color.destructive, Color.destructive.opacity(0.8)]
                                        : [Color.primary, Color.primary.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * min(progress, 1.0), height: 8)
                            .animation(.easeInOut(duration: 0.3), value: progress)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(.spacingMD)
        .background(isLimitReached ? Color.destructive.opacity(0.05) : Color.surface)
        .cornerRadius(.radiusLG)
        .overlay(
            RoundedRectangle(cornerRadius: .radiusLG)
                .stroke(isLimitReached ? Color.destructive.opacity(0.3) : Color.cardBorder, lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: .spacingMD) {
        FreeTierUsageCard(used: 1, limit: 3, featureName: "predictions today", onUpgrade: {})
        FreeTierUsageCard(used: 3, limit: 3, featureName: "predictions today", onUpgrade: {})
    }
    .padding()
    .background(Color.background)
}

