import SwiftUI

struct CaregiverModeView: View {
    @EnvironmentObject var environment: AppEnvironment
    @State private var isEnabled: Bool = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Enable Caregiver Mode", isOn: $isEnabled)
                    .onChange(of: isEnabled) { _, newValue in
                        environment.setCaregiverMode(newValue)
                    }
            } footer: {
                Text("Caregiver Mode simplifies the interface with larger buttons and fewer options, making it easier for caregivers to log events.")
            }
            
            if isEnabled {
                Section("Features") {
                    Label("Larger touch targets (56pt minimum)", systemImage: "hand.tap")
                    Label("Simplified forms", systemImage: "doc.text")
                    Label("Reduced navigation", systemImage: "arrow.triangle.branch")
                }
            }
        }
        .navigationTitle("Caregiver Mode")
        .onAppear {
            isEnabled = environment.isCaregiverMode
        }
    }
}

#Preview {
    NavigationStack {
        CaregiverModeView()
            .environmentObject(AppEnvironment(dataStore: InMemoryDataStore()))
    }
}
