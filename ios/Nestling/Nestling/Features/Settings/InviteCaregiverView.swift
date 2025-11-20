import SwiftUI
import UIKit

struct InviteCaregiverView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var showShareSheet = false
    @State private var inviteLink = "https://nestling.app/invite/family123" // Placeholder

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
                                    // TODO: Implement email sending
                                    dismiss()
                                }
                                .disabled(email.isEmpty)
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
                                        // TODO: Show toast
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
        }
    }
}

#Preview {
    InviteCaregiverView()
}
