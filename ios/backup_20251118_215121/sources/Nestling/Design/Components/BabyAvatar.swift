import SwiftUI

struct BabyAvatar: View {
    let name: String
    let size: CGFloat
    
    init(name: String, size: CGFloat = 40) {
        self.name = name
        self.size = size
    }
    
    var body: some View {
        Text(initials)
            .font(.system(size: size * 0.4, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(backgroundColor)
            .clipShape(Circle())
            .accessibilityLabel("Avatar for \(name)")
    }
    
    private var initials: String {
        name.split(separator: " ")
            .compactMap { $0.first }
            .prefix(2)
            .map { String($0) }
            .joined()
            .uppercased()
    }
    
    private var backgroundColor: Color {
        // Generate consistent color from name
        let hash = name.hashValue
        let colors: [Color] = [
            .eventFeed, .eventSleep, .eventDiaper, .eventTummy,
            .primary, .secondary
        ]
        return colors[abs(hash) % colors.count]
    }
}

#Preview {
    HStack(spacing: 16) {
        BabyAvatar(name: "Emma")
        BabyAvatar(name: "Lucas", size: 60)
        BabyAvatar(name: "Sophia Grace", size: 80)
    }
    .padding()
}

