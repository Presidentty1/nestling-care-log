import SwiftUI

/// Sticky banner that surfaces an active session (sleep/feed) with live timer.
struct OngoingTimerBanner: View {
    let event: Event
    let onStop: () -> Void
    var onEdit: (() -> Void)?
    
    @State private var now: Date = Date()
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    
    private var elapsedDescription: String {
        let minutes = Int(now.timeIntervalSince(event.startTime) / 60)
        return DateUtils.formatDuration(minutes: max(minutes, 1))
    }
    
    private var isSleep: Bool {
        event.type == .sleep
    }
    
    var body: some View {
        HStack(spacing: .spacingMD) {
            ZStack {
                Circle()
                    .fill((isSleep ? Color.eventSleep : Color.eventFeed).opacity(0.16))
                    .frame(width: 44, height: 44)
                Image(systemName: isSleep ? "moon.zzz.fill" : "timer")
                    .foregroundColor(isSleep ? .eventSleep : .eventFeed)
                    .font(.headline)
            }
            .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(isSleep ? "Sleeping" : "Ongoing")
                    .font(.headline)
                    .foregroundColor(.foreground)
                Text("\(elapsedDescription) so far")
                    .font(.subheadline)
                    .foregroundColor(.mutedForeground)
                    .lineLimit(1)
            }
            
            Spacer(minLength: 0)
            
            HStack(spacing: .spacingSM) {
                if let onEdit {
                    Button("Edit") {
                        Haptics.selection()
                        onEdit()
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.surface)
                    .cornerRadius(.radiusSM)
                    .overlay(
                        RoundedRectangle(cornerRadius: .radiusSM)
                            .stroke(Color.cardBorder, lineWidth: 1)
                    )
                }
                
                Button("Stop") {
                    Haptics.light()
                    onStop()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background((isSleep ? Color.eventSleep : Color.eventFeed))
                .cornerRadius(.radiusMD)
                .accessibilityLabel("Stop timer")
                .accessibilityHint("Stops the current session")
            }
        }
        .padding(.spacingMD)
        .background(Color.elevated)
        .cornerRadius(.radiusLG)
        .overlay(
            RoundedRectangle(cornerRadius: .radiusLG)
                .stroke(Color.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 6)
        .onReceive(timer) { newDate in
            now = newDate
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(isSleep ? "Sleeping" : "Ongoing"), \(elapsedDescription) elapsed")
    }
}

#Preview {
    VStack {
        OngoingTimerBanner(
            event: Event.mockSleep(babyId: Baby.mock().id, durationMinutes: 45),
            onStop: {},
            onEdit: {}
        )
    }
    .padding()
    .background(Color.background)
}



