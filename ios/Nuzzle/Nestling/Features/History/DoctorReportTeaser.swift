import SwiftUI

/// Doctor Report Teaser - Promotional card for PDF doctor reports (Pro feature)
/// Small card in History tab highlighting shareable reports for pediatrician visits
struct DoctorReportTeaser: View {
    let isPro: Bool
    let onUpgradeTap: () -> Void
    let onGenerateTap: () -> Void

    var body: some View {
        CardView(variant: .outline) {
            HStack(spacing: .spacingMD) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.primary.opacity(0.1))
                        .frame(width: 40, height: 40)

                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.primary)
                }

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pediatrician Visit Coming Up?")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.foreground)

                    Text("Generate a shareable PDF report")
                        .font(.caption)
                        .foregroundColor(.mutedForeground)
                        .lineLimit(2)
                }

                Spacer()

                // CTA Button
                if isPro {
                    Button(action: {
                        Haptics.medium()
                        onGenerateTap()
                    }) {
                        Text("Generate")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, .spacingMD)
                            .padding(.vertical, .spacingSM)
                            .background(Color.primary)
                            .cornerRadius(.radiusSM)
                    }
                } else {
                    Button(action: {
                        Haptics.light()
                        onUpgradeTap()
                    }) {
                        Text("Pro Feature")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.primary)
                            .padding(.horizontal, .spacingMD)
                            .padding(.vertical, .spacingSM)
                            .background(Color.primary.opacity(0.1))
                            .cornerRadius(.radiusSM)
                    }
                }
            }
        }
        .padding(.horizontal, .spacingLG)
    }
}

#Preview {
    VStack(spacing: .spacingLG) {
        DoctorReportTeaser(
            isPro: true,
            onUpgradeTap: {},
            onGenerateTap: {}
        )

        DoctorReportTeaser(
            isPro: false,
            onUpgradeTap: {},
            onGenerateTap: {}
        )
    }
    .padding()
    .background(Color.background)
}