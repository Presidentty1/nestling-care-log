import SwiftUI
import UIKit

struct InviteCaregiverView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var environment: AppEnvironment
    @State private var email = ""
    @State private var showShareSheet = false
    @State private var toast: ToastMessage? = nil
    @State private var isSendingEmail = false
    @State private var inviteCode: String = ""
    @State private var inviteLink: String = ""
    
    private func generateInviteCode() -> String {
        // Generate a unique 6-character invite code
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // Exclude confusing chars
        var code = ""
        for _ in 0..<6 {
            if let randomChar = characters.randomElement() {
                code.append(randomChar)
            }
        }
        return code
    }
    
    private func generateInviteLink() -> String {
        // Generate invite link with code
        if let baby = environment.currentBaby {
            // Use baby ID as part of the invite for uniqueness
            let babyIdShort = String(baby.id.uuidString.prefix(8))
            return "https://nuzzle.app/invite/\(inviteCode)?baby=\(babyIdShort)"
        }
        return "https://nuzzle.app/invite/\(inviteCode)"
    }
    
    private func initializeInvite() {
        if inviteCode.isEmpty {
            inviteCode = generateInviteCode()
            // Store invite code for this baby
            if let baby = environment.currentBaby {
                InviteCodeService.shared.storeInviteCode(inviteCode, for: baby.id)
            }
        }
        inviteLink = generateInviteLink()
    }

    private func sendInviteEmail() {
        guard !email.isEmpty else {
            toast = ToastMessage(message: "Please enter an email address", type: .error)
            return
        }

        // Basic email validation
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        guard emailPredicate.evaluate(with: email) else {
            toast = ToastMessage(message: "Please enter a valid email address", type: .error)
            return
        }

        isSendingEmail = true

        // For now, use the system email composer
        // In production, you'd integrate with a service like SendGrid or AWS SES
        let subject = "You're invited to join our baby tracking family!"
        let body = """
        Hi there!

        I've invited you to join our baby tracking app to help care for our little one together.

        Invite Code: \(inviteCode)
        Or click this link: \(inviteLink)

        The app helps us stay coordinated with feeding, sleeping, diaper changes, and more.

        Looking forward to having you on the team!

        Sent from Nuzzle
        """

        let codedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? body
        let codedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject

        if let url = URL(string: "mailto:\(email)?subject=\(codedSubject)&body=\(codedBody)"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            toast = ToastMessage(message: "Email composer opened", type: .success)
        } else {
            toast = ToastMessage(message: "Unable to open email app", type: .error)
        }

        isSendingEmail = false
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacingLG) {
                    // Header
                    VStack(spacing: .spacingSM) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.primary)

                        Text("Invite a Caregiver")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.foreground)

                        Text("Share your baby's care log with trusted family members or caregivers")
                            .font(.body)
                            .foregroundColor(.mutedForeground)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, .spacingMD)
                    }

                    // Invite Options
                    VStack(spacing: .spacingMD) {
                        // Email Invite (placeholder)
                        CardView(variant: .default) {
                            VStack(spacing: .spacingMD) {
                                HStack(spacing: .spacingMD) {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(.primary)
                                        .frame(width: 24)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Email Invitation")
                                            .font(.headline)
                                            .foregroundColor(.foreground)

                                        Text("Send an invite link via email")
                                            .font(.caption)
                                            .foregroundColor(.mutedForeground)
                                    }
                                }

                                TextField("Enter email address", text: $email)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)

                                PrimaryButton("Send Invite") {
                                    sendInviteEmail()
                                }
                                .disabled(email.isEmpty || isSendingEmail)
                            }
                            .padding(.spacingMD)
                        }

                        // Share Link
                        CardView(variant: .default) {
                            VStack(spacing: .spacingMD) {
                                HStack(spacing: .spacingMD) {
                                    Image(systemName: "link")
                                        .foregroundColor(.primary)
                                        .frame(width: 24)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Share Invite Link")
                                            .font(.headline)
                                            .foregroundColor(.foreground)

                                        Text("Copy or share the invite link directly")
                                            .font(.caption)
                                            .foregroundColor(.mutedForeground)
                                    }
                                }

                                // Invite Code Display
                                VStack(alignment: .leading, spacing: .spacingXS) {
                                    Text("Invite Code")
                                        .font(.caption)
                                        .foregroundColor(.mutedForeground)
                                    
                                    HStack {
                                        Text(inviteCode.isEmpty ? "Generating..." : inviteCode)
                                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                                            .foregroundColor(.primary)
                                            .padding(.spacingSM)
                                            .frame(maxWidth: .infinity)
                                            .background(Color.surface)
                                            .cornerRadius(.radiusMD)
                                        
                                        Button(action: {
                                            UIPasteboard.general.string = inviteCode
                                            toast = ToastMessage(message: "Invite code copied", type: .success)
                                            Haptics.light()
                                        }) {
                                            Image(systemName: "doc.on.doc")
                                                .foregroundColor(.primary)
                                                .padding(.spacingSM)
                                        }
                                    }
                                }
                                
                                Divider()
                                
                                // Invite Link Display
                                VStack(alignment: .leading, spacing: .spacingXS) {
                                    Text("Or share this link")
                                        .font(.caption)
                                        .foregroundColor(.mutedForeground)
                                    
                                    HStack {
                                        Text(inviteLink)
                                            .font(.caption)
                                            .foregroundColor(.mutedForeground)
                                            .lineLimit(1)
                                            .truncationMode(.middle)

                                        Spacer()

                                        Button(action: {
                                            UIPasteboard.general.string = inviteLink
                                            toast = ToastMessage(message: "Invite link copied", type: .success)
                                            Haptics.light()
                                        }) {
                                            Image(systemName: "doc.on.doc")
                                                .foregroundColor(.primary)
                                        }

                                        Button(action: { 
                                            showShareSheet = true
                                            Haptics.light()
                                        }) {
                                            Image(systemName: "square.and.arrow.up")
                                                .foregroundColor(.primary)
                                        }
                                    }
                                }
                            }
                            .padding(.spacingMD)
                        }
                    }

                    // Note
                    InfoBanner(
                        title: "Coming Soon",
                        message: "Full caregiver sharing features are in development. For now, you can share the invite link manually.",
                        variant: .info
                    )
                    .padding(.horizontal, .spacingMD)
                }
                .padding(.spacing2XL)
            }
            .navigationTitle("Invite Caregiver")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.background)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [inviteLink])
            }
            .toast($toast)
            .onAppear {
                initializeInvite()
            }
        }
    }
}

#Preview {
    InviteCaregiverView()
}
