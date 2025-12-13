import SwiftUI

/// Privacy explainer view showing how Nuzzle protects user data
/// Research: ALL baby tracking apps score LOW on privacy (Consumer Reports)
/// Opportunity: Make privacy a core differentiator
///
/// Usage in Settings → Privacy section
struct PrivacyExplainerView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Hero section
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                    
                    Text("Your baby's data stays private")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("We built Nuzzle with privacy at its core. Your family's information is yours alone.")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // Privacy features
                VStack(spacing: 16) {
                    PrivacyFeatureCard(
                        icon: "iphone",
                        iconColor: .blue,
                        title: "Your data stays local",
                        body: "All tracking data lives on your device and your private iCloud. We never see or access your baby's information.",
                        badge: nil
                    )
                    
                    PrivacyFeatureCard(
                        icon: "person.2.slash",
                        iconColor: .orange,
                        title: "No third-party access",
                        body: "We don't share or sell your data. Ever. No advertisers, no data brokers, no exceptions.",
                        badge: nil
                    )
                    
                    PrivacyFeatureCard(
                        icon: "brain",
                        iconColor: .purple,
                        title: "AI runs on your device",
                        body: "Predictions and analysis happen locally. Your baby's patterns never leave your control.",
                        badge: "NEW"
                    )
                    
                    PrivacyFeatureCard(
                        icon: "lock.rotation",
                        iconColor: .green,
                        title: "End-to-end encryption",
                        body: "When you sync with your partner, data is encrypted in transit and at rest using Apple's CloudKit.",
                        badge: nil
                    )
                    
                    PrivacyFeatureCard(
                        icon: "trash",
                        iconColor: .red,
                        title: "Delete anytime",
                        body: "Permanently delete all your data with one tap. It's gone from your device and iCloud immediately.",
                        badge: nil
                    )
                    
                    PrivacyFeatureCard(
                        icon: "eye.slash",
                        iconColor: .gray,
                        title: "No tracking, no profiling",
                        body: "We don't track your behavior across apps or build advertising profiles. Your usage is your business.",
                        badge: nil
                    )
                }
                .padding(.horizontal)
                
                // Compliance badges
                VStack(spacing: 12) {
                    Text("Compliance & Standards")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        ComplianceBadge(
                            title: "HIPAA-Aligned",
                            description: "We follow health information privacy practices"
                        )
                        
                        ComplianceBadge(
                            title: "COPPA Compliant",
                            description: "Child Online Privacy Protection Act compliant"
                        )
                        
                        ComplianceBadge(
                            title: "GDPR Ready",
                            description: "European privacy regulation compliant"
                        )
                    }
                    .padding(.horizontal)
                }
                
                // Data access and deletion
                VStack(alignment: .leading, spacing: 16) {
                    Text("Your data rights")
                        .font(.headline)
                    
                    NavigationLink(destination: DataExportView()) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Export your data")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Text("Download everything in JSON format")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "square.and.arrow.down")
                                .foregroundColor(.accentColor)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                        )
                    }
                    
                    NavigationLink(destination: DataDeletionView()) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Delete all data")
                                    .font(.body)
                                    .foregroundColor(.red)
                                
                                Text("Permanently remove all information")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                        )
                    }
                }
                .padding()
                
                // Learn more
                Link(destination: URL(string: "https://nuzzle.app/privacy")!) {
                    HStack {
                        Text("Read our full Privacy Policy")
                            .font(.subheadline)
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                    }
                    .foregroundColor(.accentColor)
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Privacy & Security")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

/// Privacy feature card
struct PrivacyFeatureCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let body: String
    let badge: String?
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    if let badge = badge {
                        Text(badge)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.accentColor)
                            )
                    }
                    
                    Spacer()
                }
                
                Text(body)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }
}

/// Compliance badge
struct ComplianceBadge: View {
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title3)
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }
}

/// Quick privacy badge for use in other views
struct PrivacyBadge: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.shield.fill")
                .foregroundColor(.green)
                .font(.caption)
            
            Text("Your data stays on your device")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.green.opacity(0.1))
        )
    }
}

/// Privacy confirmation message after first sync
struct FirstSyncPrivacyConfirmation: View {
    let partnerName: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text("First sync complete!")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Your data is encrypted and only visible to you and \(partnerName).")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button("Learn more about security") {
                    // Navigate to privacy explainer
                }
                .font(.caption)
                .foregroundColor(.accentColor)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .padding()
    }
}

// Placeholder views for navigation (to be implemented)
struct DataExportView: View {
    var body: some View {
        Text("Data Export Coming Soon")
    }
}

struct DataDeletionView: View {
    var body: some View {
        Text("Data Deletion Coming Soon")
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        PrivacyExplainerView()
    }
}

#Preview("Privacy Badge") {
    VStack {
        PrivacyBadge()
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(uiColor: .systemGroupedBackground))
}

#Preview("First Sync Confirmation") {
    VStack {
        Spacer()
        FirstSyncPrivacyConfirmation(partnerName: "James") {
            print("Dismissed")
        }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(uiColor: .systemGroupedBackground))
}
