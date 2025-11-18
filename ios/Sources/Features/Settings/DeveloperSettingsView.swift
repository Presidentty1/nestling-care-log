import SwiftUI

struct DeveloperSettingsView: View {
    @EnvironmentObject var environment: AppEnvironment
    @State private var showWidgetTest = false
    @State private var showResetConfirmation = false
    
    var body: some View {
        List {
            Section("Widget Testing") {
                Button("Reload All Widgets") {
                    WidgetTestHelper.reloadAllWidgets()
                }
                
                Button("Test Widget Data") {
                    let testData = WidgetTestHelper.generateTestData()
                    WidgetTestHelper.testDataPersistence(data: testData)
                }
                
                Button("Clear Test Data") {
                    WidgetTestHelper.clearTestData()
                }
                
                Button("Verify App Groups") {
                    let verified = WidgetTestHelper.verifyAppGroups()
                    // Could show alert with result
                }
            }
            
            Section("Data Management") {
                Button("Reset All Data", role: .destructive) {
                    showResetConfirmation = true
                }
            }
            
            Section("Debug Info") {
                HStack {
                    Text("Data Store Type")
                    Spacer()
                    Text(dataStoreType)
                        .foregroundColor(.mutedForeground)
                }
                
                HStack {
                    Text("App Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                        .foregroundColor(.mutedForeground)
                }
            }
        }
        .navigationTitle("Developer")
        .alert("Reset All Data", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                Task {
                    // Reset data store
                    // This would clear all data - implement carefully
                }
            }
        } message: {
            Text("This will delete all babies, events, and settings. This action cannot be undone.")
        }
    }
    
    private var dataStoreType: String {
        if environment.dataStore is JSONBackedDataStore {
            return "JSON"
        } else if String(describing: type(of: environment.dataStore)).contains("CoreData") {
            return "Core Data"
        } else {
            return "In Memory"
        }
    }
}

#Preview {
    NavigationStack {
        DeveloperSettingsView()
            .environmentObject(AppEnvironment(dataStore: InMemoryDataStore()))
    }
}


