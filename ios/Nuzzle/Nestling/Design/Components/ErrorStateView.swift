import SwiftUI

struct ErrorStateView: View {
    let message: String
    let retryTitle: String?
    let retryAction: (() -> Void)?
    
    init(message: String, retryTitle: String? = "Try Again", retryAction: (() -> Void)? = nil) {
        self.message = message
        self.retryTitle = retryTitle
        self.retryAction = retryAction
    }
    
    var body: some View {
        VStack(spacing: .spacingMD) {
            Image(systemName: "cloud.bolt")  // Softer than warning triangle
                .font(.system(size: 48))
                .foregroundColor(.mutedForeground)  // Less alarming

            Text("We hit a bump")  // Softer language
                .font(.headline)
                .foregroundColor(.foreground)

            Text(message)
                .font(.body)
                .foregroundColor(.mutedForeground)
                .multilineTextAlignment(.center)
                .padding(.horizontal, .spacingMD)

            Text("Don't worry, your data is safe")  // Reassurance
                .font(.caption)
                .foregroundColor(.mutedForeground)

            if let retryTitle = retryTitle, let retryAction = retryAction {
                PrimaryButton(retryTitle, action: retryAction)
                    .padding(.horizontal, .spacingMD)
                    .padding(.top, .spacingSM)
            }
        }
        .padding(.spacing2XL)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(message)")
    }
}

#Preview {
    ErrorStateView(
        message: "Failed to load events. Please check your connection and try again.",
        retryAction: {}
    )
}

