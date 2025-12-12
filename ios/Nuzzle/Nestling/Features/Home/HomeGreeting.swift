import SwiftUI

/// Lightweight, supportive greeting for the Home tab.
struct HomeGreeting: View {
    let timeOfDay: HomeViewModel.TimeOfDay
    
    private var message: String {
        switch timeOfDay {
        case .morning:
            return "Good morning, you’ve got this."
        case .day:
            return "Keeping things steady."
        case .evening:
            return "Evening wind-down time."
        case .night:
            return "Late night? I’m here to help."
        }
    }
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: .spacingSM) {
            VStack(alignment: .leading, spacing: 4) {
                Text(message)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.foreground)
                    .multilineTextAlignment(.leading)
                Text("Quickly see what’s next and log in two taps.")
                    .font(.subheadline)
                    .foregroundColor(.mutedForeground)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, .spacingMD)
    }
}

#Preview {
    VStack(spacing: 16) {
        HomeGreeting(timeOfDay: .morning)
        HomeGreeting(timeOfDay: .night)
    }
    .padding()
    .background(Color.background)
}

