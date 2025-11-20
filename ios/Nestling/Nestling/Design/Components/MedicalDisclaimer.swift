import SwiftUI

enum MedicalDisclaimerVariant {
    case ai
    case sleep
    case predictions
}

struct MedicalDisclaimer: View {
    let variant: MedicalDisclaimerVariant
    
    var body: some View {
        InfoBanner(
            title: "Medical Disclaimer",
            message: disclaimerText,
            variant: .warning
        )
        .padding(.horizontal, .spacingMD)
    }
    
    private var disclaimerText: String {
        switch variant {
        case .ai:
            return "Nestling gives general guidance, not medical care. If your baby seems very unwell or you're worried, contact a pediatric professional."
        case .sleep:
            return "Nestling gives general guidance, not medical care. If your baby seems very unwell or you're worried, contact a pediatric professional."
        case .predictions:
            return "Nestling gives general guidance, not medical care. If your baby seems very unwell or you're worried, contact a pediatric professional."
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        MedicalDisclaimer(variant: .ai)
        MedicalDisclaimer(variant: .sleep)
        MedicalDisclaimer(variant: .predictions)
    }
    .padding()
}

