import SwiftUI

struct FeatureTooltipView: View {
    let config: FeatureTooltip
    let onDismiss: () -> Void
    
    init(config: FeatureTooltip, onDismiss: @escaping () -> Void) {
        self.config = config
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: .spacingMD) {
            ZStack {
                Circle()
                    .fill(Color.primary.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: config.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: .spacingXS) {
                Text(config.title)
                    .font(.headline)
                    .foregroundColor(.foreground)
                Text(config.message)
                    .font(.subheadline)
                    .foregroundColor(.mutedForeground)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: .spacingSM) {
                    Button {
                        Haptics.light()
                        UserDefaults.standard.set(true, forKey: config.preferenceKey)
                        onDismiss()
                    } label: {
                        Text("Got it")
                            .font(.callout.weight(.semibold))
                            .foregroundColor(.primary)
                            .padding(.horizontal, .spacingSM)
                            .padding(.vertical, .spacingXS)
                            .background(Color.surface)
                            .cornerRadius(.radiusSM)
                            .overlay(
                                RoundedRectangle(cornerRadius: .radiusSM)
                                    .stroke(Color.cardBorder, lineWidth: 1)
                            )
                    }
                    
                    Button {
                        Haptics.selection()
                        UserDefaults.standard.set(true, forKey: config.preferenceKey)
                        onDismiss()
                    } label: {
                        Text("Remind later")
                            .font(.callout)
                            .foregroundColor(.mutedForeground)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.spacingMD)
        .background(Color.elevated)
        .cornerRadius(.radiusMD)
        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(config.title). \(config.message)")
        .accessibilityHint("Dismiss or learn later")
    }
}

