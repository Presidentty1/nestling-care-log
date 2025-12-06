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
            return "Nestling is not a medical device. AI features provide general information only and should not replace professional medical judgment."
        case .sleep:
            return "Sleep predictions are estimates based on patterns. Always consult your pediatrician for medical advice."
        case .predictions:
            return "Predictions are estimates based on recent patterns. Always trust your instincts and consult a doctor if concerned."
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


