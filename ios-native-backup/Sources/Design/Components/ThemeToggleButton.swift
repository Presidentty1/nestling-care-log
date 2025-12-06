import SwiftUI

/// Quick theme toggle button for navigation bars
struct ThemeToggleButton: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) private var systemColorScheme

    var body: some View {
        Button(action: {
            Haptics.light()
            themeManager.toggleTheme()
        }) {
            Image(systemName: currentIcon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color.adaptiveSurface(systemColorScheme).opacity(0.8))
                        .overlay(
                            Circle()
                                .stroke(Color.adaptiveBorder(systemColorScheme), lineWidth: 0.5)
                        )
                )
        }
        .accessibilityLabel("Toggle theme")
        .accessibilityHint("Switch between light and dark appearance")
    }

    private var currentIcon: String {
        let effectiveTheme = themeManager.effectiveTheme ?? systemColorScheme
        return effectiveTheme == .dark ? "sun.max.fill" : "moon.fill"
    }
}

#Preview {
    ThemeToggleButton()
        .environmentObject(ThemeManager())
        .padding()
}