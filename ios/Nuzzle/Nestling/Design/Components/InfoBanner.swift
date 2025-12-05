import SwiftUI

enum InfoBannerVariant {
    case info
    case warning
    case error
    case success
}

struct InfoBanner: View {
    let title: String
    let message: String?
    let variant: InfoBannerVariant
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        title: String,
        message: String? = nil,
        variant: InfoBannerVariant = .info,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.variant = variant
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: .spacingSM) {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.foreground)
                
                if let message = message {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.mutedForeground)
                }
                
                if let actionTitle = actionTitle, let action = action {
                    Button(action: action) {
                        Text(actionTitle)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(iconColor)
                    }
                    .padding(.top, 4)
                }
            }
            
            Spacer()
        }
        .padding(.spacingMD)
        .background(backgroundColor)
        .cornerRadius(.radiusMD)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }
    
    private var iconName: String {
        switch variant {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        case .success: return "checkmark.circle.fill"
        }
    }
    
    private var iconColor: Color {
        switch variant {
        case .info: return .info
        case .warning: return .warning
        case .error: return .destructive
        case .success: return .success
        }
    }
    
    private var backgroundColor: Color {
        switch variant {
        case .info: return Color.info.opacity(0.1)
        case .warning: return Color.warning.opacity(0.1)
        case .error: return Color.destructive.opacity(0.1)
        case .success: return Color.success.opacity(0.1)
        }
    }
    
    private var accessibilityLabel: String {
        var label = "\(variant == .info ? "Information" : variant == .warning ? "Warning" : variant == .error ? "Error" : "Success"): \(title)"
        if let message = message {
            label += ". \(message)"
        }
        return label
    }
}

#Preview {
    VStack(spacing: 16) {
        InfoBanner(title: "AI Features Disabled", message: "Enable AI Data Sharing to use predictions")
        InfoBanner(title: "Warning", message: "This action cannot be undone", variant: .warning)
        InfoBanner(title: "Success", message: "Event saved successfully", variant: .success)
        InfoBanner(
            title: "Action Required",
            message: "Please enable settings",
            variant: .info,
            actionTitle: "Go to Settings",
            action: {}
        )
    }
    .padding()
}


