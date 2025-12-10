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
    @Environment(\.colorScheme) private var colorScheme
    
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
        case .default: return Color.adaptivePrimary(colorScheme)
        case .secondary: return Color.adaptiveMutedForeground(colorScheme)
        case .destructive: return Color.destructive
        case .outline: return Color.clear
        }
    }

    private var textColor: Color {
        switch variant {
        case .default, .secondary, .destructive: return Color.adaptivePrimaryForeground(colorScheme)
        case .outline: return Color.adaptiveForeground(colorScheme)
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


