import SwiftUI

/// Banner to label example timeline data (Epic 1 AC7)
struct ExampleDataBanner: View {
    var body: some View {
        HStack(spacing: .spacingSM) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(Color.eventDiaper)
                .font(.caption)
            
            Text("Example day – you'll see your own pattern as you log")
                .font(.caption)
                .foregroundColor(.mutedForeground)
            
            Spacer()
        }
        .padding(.spacingMD)
        .background(Color.surface)
        .cornerRadius(.radiusMD)
        .overlay(
            RoundedRectangle(cornerRadius: .radiusMD)
                .stroke(Color.separator, lineWidth: 1)
        )
        .accessibilityLabel("Example data banner")
        .accessibilityHint("This timeline shows example data. Your own logged events will appear here as you use the app.")
    }
}

#Preview {
    ExampleDataBanner()
        .padding()
}
