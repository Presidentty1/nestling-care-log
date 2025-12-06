import SwiftUI

enum CardVariant {
    case `default`
    case emphasis
    case success
    case warning
    case info
    case elevated
    case outline
}

struct CardView<Content: View>: View {
    let variant: CardVariant
    let content: Content
    
    init(variant: CardVariant = .default, @ViewBuilder content: () -> Content) {
        self.variant = variant
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(.spacingMD)
            .background(backgroundColor)
            .overlay(overlay)
            .cornerRadius(.radiusMD)
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
    }
    
    private var backgroundColor: Color {
        switch variant {
        case .default, .outline: return .surface
        case .emphasis: return Color.primary.opacity(0.05)
        case .success: return Color.success.opacity(0.1)
        case .warning: return Color.warning.opacity(0.1)
        case .info: return Color.info.opacity(0.1)
        case .elevated: return .surface
        }
    }
    
    @ViewBuilder
    private var overlay: some View {
        if variant == .outline {
            RoundedRectangle(cornerRadius: .radiusMD)
                .stroke(Color.border, lineWidth: 1)
        } else if variant == .emphasis {
            RoundedRectangle(cornerRadius: .radiusMD)
                .stroke(Color.primary.opacity(0.2), lineWidth: 1)
        } else {
            EmptyView()
        }
    }
    
    private var shadowColor: Color {
        variant == .elevated ? Color.black.opacity(0.1) : Color.clear
    }
    
    private var shadowRadius: CGFloat {
        variant == .elevated ? 8 : 0
    }
    
    private var shadowY: CGFloat {
        variant == .elevated ? 4 : 0
    }
}

#Preview {
    VStack(spacing: 16) {
        CardView(variant: .default) {
            Text("Default Card")
        }
        CardView(variant: .emphasis) {
            Text("Emphasis Card")
        }
        CardView(variant: .elevated) {
            Text("Elevated Card")
        }
    }
    .padding()
}

