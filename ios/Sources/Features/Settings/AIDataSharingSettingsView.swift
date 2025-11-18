import SwiftUI

struct AIDataSharingSettingsView: View {
    @EnvironmentObject var environment: AppEnvironment
    @Environment(\.dismiss) var dismiss
    @State private var aiEnabled: Bool
    
    init() {
        _aiEnabled = State(initialValue: true)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: .spacingLG) {
                    Text("AI Data Sharing")
                        .font(.headline)
                        .foregroundColor(.foreground)
                    
                    Text("Enable AI features to get smart predictions for feeds and naps. Your data is used only to improve predictions and is never shared with third parties.")
                        .font(.body)
                        .foregroundColor(.mutedForeground)
                    
                    Toggle("Enable AI Data Sharing", isOn: $aiEnabled)
                        .padding(.spacingMD)
                        .background(Color.surface)
                        .cornerRadius(.radiusMD)
                    
                    if !aiEnabled {
                        Text("AI features will be disabled. You can still log events manually.")
                            .font(.caption)
                            .foregroundColor(.mutedForeground)
                    }
                }
                .padding(.spacingMD)
            }
            .navigationTitle("AI Data Sharing")
            .background(Color.background)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveSettings()
                        dismiss()
                    }
                }
            }
            .onAppear {
                aiEnabled = environment.appSettings.aiDataSharingEnabled
            }
        }
    }
    
    private func saveSettings() {
        var settings = environment.appSettings
        settings.aiDataSharingEnabled = aiEnabled
        
        Task {
            do {
                try await environment.dataStore.saveAppSettings(settings)
                await MainActor.run {
                    environment.appSettings = settings
                }
            } catch {
                print("Failed to save settings: \(error)")
            }
        }
    }
}

#Preview {
    AIDataSharingSettingsView()
        .environmentObject(AppEnvironment(dataStore: InMemoryDataStore()))
}


