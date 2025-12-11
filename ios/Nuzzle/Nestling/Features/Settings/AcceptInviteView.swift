import SwiftUI

struct AcceptInviteView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var environment: AppEnvironment
    @State private var inviteCode = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacingLG) {
                    // Header
                    VStack(spacing: .spacingSM) {
                        Image(systemName: "person.2.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.primary)
                        
                        Text("Accept Invite")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.foreground)
                        
                        Text("Enter the invite code to join a baby's care log")
                            .font(.body)
                            .foregroundColor(.mutedForeground)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, .spacingMD)
                    }
                    .padding(.top, .spacing2XL)
                    
                    // Invite Code Input
                    CardView(variant: .default) {
                        VStack(alignment: .leading, spacing: .spacingMD) {
                            Text("Invite Code")
                                .font(.headline)
                                .foregroundColor(.foreground)
                            
                            TextField("Enter 6-character code", text: $inviteCode)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.allCharacters)
                                .disableAutocorrection(true)
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .onChange(of: inviteCode) { _, newValue in
                                    // Limit to 6 characters and uppercase
                                    inviteCode = String(newValue.prefix(6).uppercased())
                                }
                            
                            if let error = errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.destructive)
                            }
                            
                            PrimaryButton("Accept Invite", icon: "checkmark.circle.fill") {
                                acceptInvite()
                            }
                            .disabled(inviteCode.count != 6 || isProcessing)
                            .overlay {
                                if isProcessing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                }
                            }
                        }
                        .padding(.spacingMD)
                    }
                    .padding(.horizontal, .spacingMD)
                    
                    // Instructions
                    InfoBanner(
                        title: "How it works",
                        message: "Ask the parent for their 6-character invite code. Once accepted, you'll be able to view and log events for their baby.",
                        variant: .info
                    )
                    .padding(.horizontal, .spacingMD)
                }
                .padding(.spacing2XL)
            }
            .navigationTitle("Accept Invite")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.background)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Invite Accepted!", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                    // Refresh babies to show the shared baby
                    Task {
                        await environment.refreshBabies()
                    }
                }
            } message: {
                Text("You now have access to this baby's care log. You can view and log events.")
            }
        }
    }
    
    private func acceptInvite() {
        guard inviteCode.count == 6 else {
            errorMessage = "Please enter a 6-character code"
            return
        }
        
        isProcessing = true
        errorMessage = nil
        
        Task {
            // Validate invite code
            if let babyId = InviteCodeService.shared.acceptInviteCode(inviteCode) {
                // Check if baby exists in data store
                do {
                    let babies = try await environment.dataStore.fetchBabies()
                    if babies.contains(where: { $0.id == babyId }) {
                        await MainActor.run {
                            isProcessing = false
                            UserDefaults.standard.set(true, forKey: "shouldShowCaregiverWelcome")
                            showSuccess = true
                        }
                    } else {
                        // Baby not found locally - would need to fetch from backend in production
                        await MainActor.run {
                            isProcessing = false
                            errorMessage = "Baby profile not found. The invite code may be invalid or expired."
                        }
                    }
                } catch {
                    await MainActor.run {
                        isProcessing = false
                        errorMessage = "Failed to load baby profile: \(error.localizedDescription)"
                    }
                }
            } else {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = "Invalid invite code. Please check and try again."
                }
            }
        }
    }
}

#Preview {
    AcceptInviteView()
        .environmentObject(AppEnvironment(dataStore: InMemoryDataStore()))
}






