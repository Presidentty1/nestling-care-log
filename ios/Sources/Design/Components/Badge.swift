import SwiftUI

enum BadgeVariant {
    case `default`
    case secondary
    case destructive
    case outline
}

struct Badge: View {
    let text: String
    let variant: BadgeVariant
    
    init(_ text: String, variant: BadgeVariant = .default) {
        self.text = text
        self.variant = variant
    }
    
    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(textColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(backgroundColor)
            .cornerRadius(8)
            .accessibilityLabel("Badge: \(text)")
    }
    
    private var backgroundColor: Color {
        switch variant {
        case .default: return Color.primary
        case .secondary: return Color.mutedForeground
        case .destructive: return Color.destructive
        case .outline: return Color.clear
        }
    }
    
    private var textColor: Color {
        switch variant {
        case .default, .secondary, .destructive: return .white
        case .outline: return .foreground
        }
    }
}

#Preview {
    HStack(spacing: 8) {
        Badge("New")
        Badge("Beta", variant: .secondary)
        Badge("Urgent", variant: .destructive)
        Badge("Draft", variant: .outline)
    }
    .padding()
}


