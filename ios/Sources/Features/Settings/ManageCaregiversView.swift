import SwiftUI

struct ManageCaregiversView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacingLG) {
                    Text("Manage Caregivers")
                        .font(.headline)
                        .foregroundColor(.foreground)
                    
                    Text("Family sharing and caregiver invites are coming soon. For now, you can manage your baby profiles in the web app.")
                        .font(.body)
                        .foregroundColor(.mutedForeground)
                        .multilineTextAlignment(.center)
                        .padding(.spacingMD)
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
}

#Preview {
    ManageCaregiversView()
}


