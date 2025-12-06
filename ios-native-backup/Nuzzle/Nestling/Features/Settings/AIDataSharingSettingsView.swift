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
                    
                    Text("Turn on Smart Predictions to get suggested nap windows and feeding times based on your baby's patterns. Your data is used only to improve these suggestions and is never sold.")
                        .font(.body)
                        .foregroundColor(.mutedForeground)
                    
                    Text("Data is never sold, never shared with third parties for advertising")
                        .font(.caption)
                        .foregroundColor(.mutedForeground)
                        .padding(.bottom, .spacingSM)
                    
                    Toggle("Enable Smart Predictions", isOn: $aiEnabled)
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

