import SwiftUI

struct ManageCaregiversView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showInviteCaregiver = false
    @State private var showRevokeConfirm = false
    @State private var caregiverToRevoke: String?
    @State private var invites: [String] = []
    
    private let relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

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

                    // Current Caregivers Section
                    VStack(alignment: .leading, spacing: .spacingMD) {
                        Text("Current Access")
                            .font(.headline)
                            .foregroundColor(.foreground)

                        // Owner (you)
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
                        
                        // Sync status
                        if CaregiverSyncService.shared.isEnabled {
                            HStack(spacing: .spacingSM) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.success)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Family sharing enabled")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.foreground)
                                    
                                    if let lastSync = CaregiverSyncService.shared.lastSyncTime {
                                        Text("Last synced: \(lastSync, formatter: relativeDateFormatter)")
                                            .font(.caption2)
                                            .foregroundColor(.mutedForeground)
                                    }
                                }
                                
                                Spacer()
                                
                                if CaregiverSyncService.shared.isSyncing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .scaleEffect(0.8)
                                }
                            }
                            .padding(.spacingMD)
                            .background(Color.success.opacity(0.05))
                            .cornerRadius(.radiusSM)
                        }

                        InfoBanner(
                            title: "Family Sharing",
                            message: "When you invite a caregiver, logs will sync automatically across all devices via iCloud.",
                            variant: .info
                        )

                        if !invites.isEmpty {
                            VStack(alignment: .leading, spacing: .spacingSM) {
                                Text("Pending Invites")
                                    .font(.headline)
                                ForEach(invites, id: \.self) { invite in
                                    HStack {
                                        Text(invite)
                                            .foregroundColor(.foreground)
                                        Spacer()
                                        Button("Revoke") {
                                            caregiverToRevoke = invite
                                            showRevokeConfirm = true
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                }
                            }
                            .padding(.spacingMD)
                            .background(Color.surface)
                            .cornerRadius(.radiusSM)
                        }
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
            .alert("Revoke access?", isPresented: $showRevokeConfirm) {
                Button("Revoke", role: .destructive) {
                    Task {
                        if let target = caregiverToRevoke {
                            await CaregiverSyncService.shared.revokeAccess(caregiverId: target)
                            invites.removeAll { $0 == target }
                        }
                        caregiverToRevoke = nil
                    }
                }
                Button("Cancel", role: .cancel) {
                    caregiverToRevoke = nil
                }
            } message: {
                Text("This caregiver will lose access to shared data.")
            }
        }
    }
}

#Preview {
    ManageCaregiversView()
}

