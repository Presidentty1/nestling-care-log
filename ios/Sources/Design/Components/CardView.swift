import SwiftUI

enum CardVariant {
    case `default`
    case emphasis
    case success
    case warning
    case info
    case destructive
    case elevated
    case outline
}

struct CardView<Content: View>: View {
    let variant: CardVariant
    let content: Content
    @Environment(\.colorScheme) private var colorScheme

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
            .adaptiveShadow(shadowLevel, scheme: colorScheme)
    }
    
    private var backgroundColor: Color {
        switch variant {
        case .default, .outline: return Color.adaptiveSurface(colorScheme)
        case .emphasis: return Color.adaptivePrimary(colorScheme).opacity(0.05)
        case .success: return Color.success.opacity(0.1)
        case .warning: return Color.warning.opacity(0.1)
        case .info: return Color.info.opacity(0.1)
        case .destructive: return Color.red.opacity(0.1)
        case .elevated: return Color.adaptiveElevated(colorScheme)
        }
    }
    
    @ViewBuilder
    private var overlay: some View {
        if variant == .outline {
            RoundedRectangle(cornerRadius: .radiusMD)
                .stroke(Color.adaptiveBorder(colorScheme), lineWidth: 1)
        } else if variant == .emphasis {
            RoundedRectangle(cornerRadius: .radiusMD)
                .stroke(Color.adaptivePrimary(colorScheme).opacity(0.2), lineWidth: 1)
        } else {
            EmptyView()
        }
    }
    
    private var shadowLevel: ShadowLevel {
        variant == .elevated ? .lg : .sm
    }
}

// Legacy color definitions moved to DesignSystem.swift
// Use Color.adaptiveBorder(_:) and Color.adaptiveInfo(_:) instead

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


