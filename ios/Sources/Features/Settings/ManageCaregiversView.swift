import SwiftUI

struct ManageCaregiversView: View {
    @Environment(\.dismiss) var dismiss
    
    private let webAppURL = "https://nuzzle.app/settings/caregivers"
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacingLG) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.primary)
                        .padding(.top, .spacingXL)
                    
                    Text("Manage Caregivers")
                        .font(.headline)
                        .foregroundColor(.foreground)
                    
                    VStack(spacing: .spacingMD) {
                        Text("Shared access is supported via the web app. Invite family members, manage permissions, and sync across devices.")
                            .font(.body)
                            .foregroundColor(.mutedForeground)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, .spacingMD)
                        
                        PrimaryButton("Open Caregiver Settings on Web", icon: "safari.fill") {
                            openWebApp()
                        }
                        .padding(.horizontal, .spacingMD)
                        .padding(.top, .spacingSM)
                    }
                }
                .padding(.spacing2XL)
            }
            .navigationTitle("Manage Caregivers")
            .background(Color.background)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func openWebApp() {
        guard let url = URL(string: webAppURL) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    ManageCaregiversView()
}


