import SwiftUI
import UIKit

struct InviteCaregiverView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var showShareSheet = false
    @State private var toast: ToastMessage? = nil
    @State private var isSendingEmail = false
    @State private var inviteLink = "https://nuzzle.app/invite/family123" // Placeholder

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

        Click this link to get started: \(inviteLink)

        The app helps us stay coordinated with feeding, sleeping, diaper changes, and more.

        Looking forward to having you on the team!

        Sent from Nestling (Nuzzle)
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

                                HStack {
                                    Text(inviteLink)
                                        .font(.caption)
                                        .foregroundColor(.mutedForeground)
                                        .lineLimit(1)
                                        .truncationMode(.middle)

                                    Spacer()

                                    Button(action: {
                                        UIPasteboard.general.string = inviteLink
                                        toast = ToastMessage(message: "Invite link copied to clipboard", type: .success)
                                    }) {
                                        Image(systemName: "doc.on.doc")
                                            .foregroundColor(.primary)
                                    }

                                    Button(action: { showShareSheet = true }) {
                                        Image(systemName: "square.and.arrow.up")
                                            .foregroundColor(.primary)
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
        }
    }
}

#Preview {
    InviteCaregiverView()
}
