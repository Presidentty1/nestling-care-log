import SwiftUI
import UIKit

/// Enhanced night mode for 2AM logging
/// Research: 2AM logging is core use case for baby tracking apps
///
/// Features:
/// - Auto-enable based on time (10PM-6AM)
/// - Extra-dim toggle (50% brightness)
/// - Larger touch targets (60pt minimum)
/// - Minimal animations
/// - High contrast text
struct NightModeOverlay: ViewModifier {
    @ObservedObject var themeManager: ThemeManager
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if themeManager.nightModeEnabled {
                        // Red tint overlay for night mode
                        Color.red
                            .opacity(nightModeOpacity)
                            .blendMode(.multiply)
                            .ignoresSafeArea()
                            .allowsHitTesting(false) // Allow touches to pass through
                    }
                }
            )
            .environment(\.nightModeActive, themeManager.nightModeEnabled)
            .environment(\.extraDimActive, themeManager.extraDimEnabled)
            .onAppear {
                // Auto-enable night mode if it's night time
                if themeManager.autoEnableNightMode {
                    checkAndAutoEnableNightMode()
                }
            }
    }
    
    private var nightModeOpacity: Double {
        // Extra-dim mode uses higher opacity for darker overlay
        return themeManager.extraDimEnabled ? 0.25 : 0.15
    }
    
    private func checkAndAutoEnableNightMode() {
        let hour = Calendar.current.component(.hour, from: Date())
        let isNightTime = hour >= 22 || hour < 7  // 10PM - 7AM
        
        if isNightTime && !themeManager.nightModeEnabled {
            themeManager.nightModeEnabled = true
            logger.debug("[NightMode] Auto-enabled night mode at \(hour):00")
        } else if !isNightTime && themeManager.nightModeEnabled && themeManager.autoEnableNightMode {
            // Auto-disable when daytime arrives
            themeManager.nightModeEnabled = false
            logger.debug("[NightMode] Auto-disabled night mode at \(hour):00")
        }
    }
}

extension View {
    /// Apply enhanced night mode overlay if enabled
    func nightModeOverlay(themeManager: ThemeManager) -> some View {
        modifier(NightModeOverlay(themeManager: themeManager))
    }
}

// MARK: - Night Mode Environment Keys

private struct NightModeActiveKey: EnvironmentKey {
    static let defaultValue = false
}

private struct ExtraDimActiveKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var nightModeActive: Bool {
        get { self[NightModeActiveKey.self] }
        set { self[NightModeActiveKey.self] = newValue }
    }
    
    var extraDimActive: Bool {
        get { self[ExtraDimActiveKey.self] }
        set { self[ExtraDimActiveKey.self] = newValue }
    }
}

// MARK: - Night Mode Button Styles

/// Night mode button style with larger touch targets
/// Minimum 60pt for easy tapping while holding baby
struct NightModeButtonStyle: ButtonStyle {
    @Environment(\.nightModeActive) private var nightModeActive
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(minWidth: 60, minHeight: 60)  // Minimum touch target
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(nightModeActive ? Color.red.opacity(0.2) : Color.accentColor)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(nightModeActive ? nil : .easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Night mode text style with high contrast
struct NightModeTextStyle: ViewModifier {
    @Environment(\.nightModeActive) private var nightModeActive
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(nightModeActive ? .white : .primary)
            .fontWeight(nightModeActive ? .semibold : .regular)  // Higher contrast
    }
}

extension View {
    /// Apply night mode optimized button style
    func nightModeButton() -> some View {
        self.buttonStyle(NightModeButtonStyle())
    }
    
    /// Apply high contrast text for night mode
    func nightModeText() -> some View {
        self.modifier(NightModeTextStyle())
    }
}

// MARK: - Night Mode Settings Card

/// Settings card for night mode preferences
struct NightModeSettingsCard: View {
    @ObservedObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "moon.fill")
                    .foregroundColor(.indigo)
                Text("Night Mode")
                    .font(.headline)
            }
            
            // Enable toggle
            Toggle("Enable Night Mode", isOn: $themeManager.nightModeEnabled)
            
            if themeManager.nightModeEnabled {
                VStack(alignment: .leading, spacing: 12) {
                    // Auto-enable
                    Toggle("Auto-enable at night (10PM-7AM)", isOn: $themeManager.autoEnableNightMode)
                        .font(.subheadline)
                    
                    // Extra-dim
                    Toggle("Extra-dim mode", isOn: $themeManager.extraDimEnabled)
                        .font(.subheadline)
                    
                    Text("Night mode reduces blue light and makes buttons easier to tap while holding your baby.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.leading)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }
}

private let logger = LoggerFactory.create(category: "NightMode")









