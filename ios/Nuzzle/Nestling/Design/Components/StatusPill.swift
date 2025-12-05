import SwiftUI

enum StatusPillVariant {
    case `default`
    case success
    case warning
    case destructive
    case info
}

struct StatusPill: View {
    let title: String
    let variant: StatusPillVariant
    
    init(_ title: String, variant: StatusPillVariant = .default) {
        self.title = title
        self.variant = variant
    }
    
    var body: some View {
        Text(title)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(textColor)
            .padding(.horizontal, .spacingSM)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .cornerRadius(.radiusSM)
            .accessibilityLabel("Status: \(title)")
    }
    
    private var backgroundColor: Color {
        switch variant {
        case .default: return Color.mutedForeground.opacity(0.2)
        case .success: return Color.success.opacity(0.2)
        case .warning: return Color.warning.opacity(0.2)
        case .destructive: return Color.destructive.opacity(0.2)
        case .info: return Color.info.opacity(0.2)
        }
    }
    
    private var textColor: Color {
        switch variant {
        case .default: return .foreground
        case .success: return .success
        case .warning: return .warning
        case .destructive: return .destructive
        case .info: return .info
        }
    }
}

#Preview {
    HStack(spacing: 8) {
        StatusPill("Active")
        StatusPill("Success", variant: .success)
        StatusPill("Warning", variant: .warning)
        StatusPill("Error", variant: .destructive)
    }
    .padding()
}


