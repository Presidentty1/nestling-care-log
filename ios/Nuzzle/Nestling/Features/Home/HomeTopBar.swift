import SwiftUI

/// Top bar for the Home tab showing baby name/age, brand mark, and settings.
/// Supports tapping the baby area to switch babies when applicable.
struct HomeTopBar: View {
    let baby: Baby
    let ageDescription: String
    let onSettingsTapped: () -> Void
    let onBabyTapped: (() -> Void)?
    
    var body: some View {
        HStack(alignment: .center, spacing: .spacingMD) {
            Button(action: {
                onBabyTapped?()
            }) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(baby.name)
                        .font(.headline)
                        .foregroundColor(.foreground)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text(ageDescription)
                        .font(.subheadline)
                        .foregroundColor(.mutedForeground)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(baby.name), \(ageDescription)")
            .accessibilityHint("Double tap to switch baby")
            
            Image("AppIconSmall")
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)
            
            Button(action: onSettingsTapped) {
                Image(systemName: "gearshape.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.primary)
                    .frame(width: 36, height: 36)
                    .background(Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: .radiusSM))
            }
            .accessibilityLabel("Open settings")
            .accessibilityHint("Shows app settings and profile")
        }
        .padding(.horizontal, .spacingMD)
        .padding(.vertical, .spacingSM)
        .background(Color.background.opacity(0.001)) // keeps tap targets without visual change
    }
}

#Preview {
    HomeTopBar(
        baby: Baby.mock(),
        ageDescription: DateUtils.formatBabyAge(dateOfBirth: Baby.mock().dateOfBirth),
        onSettingsTapped: {},
        onBabyTapped: {}
    )
    .background(Color.background)
}
