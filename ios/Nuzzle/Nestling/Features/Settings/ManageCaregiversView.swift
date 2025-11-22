import SwiftUI

struct ManageCaregiversView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showInviteCaregiver = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacingLG) {
                    // Header
                    VStack(spacing: .spacingSM) {
                        Text("Family & Caregivers")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.foreground)

                        Text("Share your baby's care log with trusted caregivers")
                            .font(.body)
                            .foregroundColor(.mutedForeground)
                            .multilineTextAlignment(.center)
                    }

                    // Invite Button
                    Button(action: { showInviteCaregiver = true }) {
                        CardView(variant: .default) {
                            HStack(spacing: .spacingMD) {
                                Image(systemName: "person.badge.plus")
                                    .font(.title3)
                                    .foregroundColor(.primary)
                                    .frame(width: 32)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Invite a Caregiver")
                                        .font(.headline)
                                        .foregroundColor(.foreground)

                                    Text("Share this log with your partner or caregiver so everyone stays in sync")
                                        .font(.caption)
                                        .foregroundColor(.mutedForeground)
                                        .lineLimit(2)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundColor(.mutedForeground)
                            }
                            .padding(.spacingMD)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Current Caregivers Section (placeholder for now)
                    VStack(alignment: .leading, spacing: .spacingMD) {
                        Text("Current Access")
                            .font(.headline)
                            .foregroundColor(.foreground)

                        CardView(variant: .default) {
                            HStack(spacing: .spacingMD) {
                                Image(systemName: "person.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.primary)
                                    .frame(width: 32)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("You")
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.foreground)

                                    Text("Owner")
                                        .font(.caption)
                                        .foregroundColor(.mutedForeground)
                                }

                                Spacer()

                                Text("Active")
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.primary.opacity(0.1))
                                    .cornerRadius(12)
                            }
                            .padding(.spacingMD)
                        }

                        Text("Additional caregiver invites will be available soon.")
                            .font(.caption)
                            .foregroundColor(.mutedForeground)
                            .padding(.horizontal, .spacingMD)
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
            .sheet(isPresented: $showInviteCaregiver) {
                InviteCaregiverView()
            }
        }
    }
}

#Preview {
    ManageCaregiversView()
}

