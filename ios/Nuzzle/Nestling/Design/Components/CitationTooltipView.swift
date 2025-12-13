import SwiftUI

/// Tooltip view for displaying medical citations
/// Research: Build trust through transparency
///
/// Usage:
/// ```swift
/// .sheet(isPresented: $showCitation) {
///     CitationTooltipView(
///         citation: MedicalCitationService.shared.citation(for: .napPrediction),
///         onDismiss: { showCitation = false }
///     )
/// }
/// ```
struct CitationTooltipView: View {
    let citation: MedicalCitationService.MedicalCitation
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Source badge
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue)
                        Text(citation.source)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.1))
                    )
                    
                    // Title
                    Text(citation.title)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    // Summary
                    Text(citation.summary)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    // Learn more link
                    Link(destination: URL(string: citation.url)!) {
                        HStack {
                            Text("Read full guidelines")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                        }
                        .foregroundColor(.accentColor)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.accentColor.opacity(0.1))
                    )
                    
                    // Last reviewed
                    HStack {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text("Last reviewed: \(formattedDate)")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    
                    Divider()
                    
                    // Medical disclaimer
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Medical Disclaimer")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        Text(MedicalCitationService.shared.medicalDisclaimer())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(uiColor: .tertiarySystemGroupedBackground))
                    )
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Based on Research")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: citation.lastReviewed)
    }
}

/// AAP Citation Badge for use in predictions and insights
/// Shows trust signal with tap-to-learn-more
struct AAPCitationBadge: View {
    let feature: MedicalCitationService.Feature
    let context: String
    @State private var showTooltip = false
    
    var body: some View {
        Button(action: {
            showTooltip = true
            MedicalCitationService.shared.trackCitationViewed(feature: feature, context: context)
        }) {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.caption2)
                Text("AAP")
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundColor(.blue)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(Color.blue.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("American Academy of Pediatrics citation")
        .accessibilityHint("Tap to learn more about the research behind this feature")
        .sheet(isPresented: $showTooltip) {
            CitationTooltipView(
                citation: MedicalCitationService.shared.citation(for: feature),
                onDismiss: { showTooltip = false }
            )
        }
    }
}

/// Research-backed badge for use in paywalls and marketing
struct ResearchBackedBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.caption2)
            Text("Research-backed")
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(.blue)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.blue.opacity(0.1))
        )
    }
}

// MARK: - Preview

#Preview("Citation Tooltip") {
    CitationTooltipView(
        citation: MedicalCitationService.MedicalCitation(
            source: "American Academy of Pediatrics",
            title: "Sleep Duration and Wake Windows",
            url: "https://www.aap.org/en/patient-care/sleep/",
            summary: "Age-appropriate wake windows prevent overtiredness and improve sleep quality. Newborns need 45-60 minute wake windows, increasing gradually with age.",
            lastReviewed: Date()
        ),
        onDismiss: { print("Dismissed") }
    )
}

#Preview("AAP Badge") {
    VStack {
        AAPCitationBadge(
            feature: .napPrediction,
            context: "nap_card"
        )
        
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(uiColor: .systemGroupedBackground))
}

#Preview("Research Badge") {
    VStack {
        ResearchBackedBadge()
        
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(uiColor: .systemGroupedBackground))
}
