import SwiftUI

/// Modal view showing detailed medical citation information
struct CitationTooltipView: View {
    let citation: MedicalCitationService.MedicalCitation
    let onDismiss: () -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: .spacingLG) {
                    // Header
                    VStack(alignment: .leading, spacing: .spacingSM) {
                        Text("Medical Citation")
                            .font(.headingLG)
                            .foregroundColor(.foreground)

                        Text("Evidence-based guidance")
                            .font(.bodyMD)
                            .foregroundColor(.mutedForeground)
                    }

                    // Citation content
                    VStack(alignment: .leading, spacing: .spacingMD) {
                        // Source
                        VStack(alignment: .leading, spacing: .spacingXS) {
                            Text("Source")
                                .font(.caption)
                                .foregroundColor(.mutedForeground)
                                .textCase(.uppercase)

                            Text(citation.source)
                                .font(.bodyMD)
                                .foregroundColor(.foreground)
                                .fontWeight(.medium)
                        }

                        // Title
                        VStack(alignment: .leading, spacing: .spacingXS) {
                            Text("Reference")
                                .font(.caption)
                                .foregroundColor(.mutedForeground)
                                .textCase(.uppercase)

                            Text(citation.title)
                                .font(.bodyMD)
                                .foregroundColor(.foreground)
                        }

                        // Summary
                        VStack(alignment: .leading, spacing: .spacingXS) {
                            Text("Summary")
                                .font(.caption)
                                .foregroundColor(.mutedForeground)
                                .textCase(.uppercase)

                            Text(citation.summary)
                                .font(.bodyMD)
                                .foregroundColor(.foreground)
                                .lineSpacing(4)
                        }

                        // URL
                        VStack(alignment: .leading, spacing: .spacingXS) {
                            Text("Learn More")
                                .font(.caption)
                                .foregroundColor(.mutedForeground)
                                .textCase(.uppercase)

                            Button(action: openURL) {
                                HStack {
                                    Text(citation.url)
                                        .font(.bodySM)
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)

                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                }
                            }
                            .buttonStyle(.plain)
                        }

                        // Last reviewed
                        VStack(alignment: .leading, spacing: .spacingXS) {
                            Text("Last Reviewed")
                                .font(.caption)
                                .foregroundColor(.mutedForeground)
                                .textCase(.uppercase)

                            Text(citation.lastReviewed.formatted(date: .abbreviated, time: .omitted))
                                .font(.bodySM)
                                .foregroundColor(.mutedForeground)
                        }
                    }
                    .padding(.spacingLG)
                    .background(Color.surface)
                    .cornerRadius(.radiusLG)

                    // Disclaimer
                    VStack(alignment: .leading, spacing: .spacingSM) {
                        HStack(spacing: .spacingSM) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.warning)
                                .font(.body)

                            Text("Important Disclaimer")
                                .font(.headingMD)
                                .foregroundColor(.foreground)
                        }

                        Text(MedicalCitationService.shared.medicalDisclaimer())
                            .font(.bodyMD)
                            .foregroundColor(.mutedForeground)
                            .lineSpacing(4)

                        Text("This app provides general information based on established pediatric guidelines. Always consult with your pediatrician for personalized medical advice.")
                            .font(.bodySM)
                            .foregroundColor(.mutedForeground)
                            .lineSpacing(4)
                    }
                    .padding(.spacingLG)
                    .background(Color.warning.opacity(0.05))
                    .cornerRadius(.radiusLG)
                    .overlay(
                        RoundedRectangle(cornerRadius: .radiusLG)
                            .stroke(Color.warning.opacity(0.2), lineWidth: 1)
                    )

                    Spacer()
                }
                .padding(.spacingLG)
            }
            .navigationBarItems(trailing: Button("Done") { onDismiss() })
            .navigationTitle("Citation Details")
        }
    }

    private func openURL() {
        guard let url = URL(string: citation.url) else { return }
        UIApplication.shared.open(url)

        // Analytics
        MedicalCitationService.shared.trackCitationViewed(feature: .napPrediction, context: "tooltip_link_clicked")
    }
}

#Preview {
    CitationTooltipView(
        citation: MedicalCitationService.shared.citation(for: .napPrediction),
        onDismiss: {}
    )
}