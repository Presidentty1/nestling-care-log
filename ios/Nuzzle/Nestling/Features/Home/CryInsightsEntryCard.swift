import SwiftUI

struct CryInsightsEntryCard: View {
    let isPro: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: .spacingMD) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.eventSleep.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "waveform")
                        .foregroundColor(.eventSleep)
                        .font(.title3)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: .spacingXS) {
                        Text("Not sure what the cry means?")
                            .font(.subheadline)
                            .foregroundColor(.foreground)
                        
                        if !isPro {
                            Text("Pro")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.primary)
                                .cornerRadius(8)
                        }
                    }
                    
                    Text("Try Cry Insights (Beta)")
                        .font(.caption)
                        .foregroundColor(.mutedForeground)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.mutedForeground)
            }
            .padding(.spacingMD)
            .background(Color.surface)
            .cornerRadius(.radiusMD)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack(spacing: .spacingMD) {
        CryInsightsEntryCard(isPro: false, onTap: {})
        CryInsightsEntryCard(isPro: true, onTap: {})
    }
    .padding()
    .background(Color.background)
}

