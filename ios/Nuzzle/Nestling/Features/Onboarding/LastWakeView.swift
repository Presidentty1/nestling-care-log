import SwiftUI

struct LastWakeView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @State private var selectedWakeOption: WakeOption = .justNow
    @State private var customWakeTime: Date = Date()
    @State private var showCustomTimePicker = false
    
    enum WakeOption: String, CaseIterable {
        case justNow = "Just now"
        case fifteenMin = "15 min ago"
        case thirtyMin = "30 min ago"
        case fortyFiveMin = "45 min ago"
        case custom = "Custom time"
        
        func getDate() -> Date {
            let now = Date()
            switch self {
            case .justNow:
                return now
            case .fifteenMin:
                return now.addingTimeInterval(-15 * 60)
            case .thirtyMin:
                return now.addingTimeInterval(-30 * 60)
            case .fortyFiveMin:
                return now.addingTimeInterval(-45 * 60)
            case .custom:
                return now
            }
        }
    }
    
    var shouldShowNapWindow: Bool {
        coordinator.selectedFocusAreas.contains(.napsAndNights) ||
        coordinator.selectedFocusAreas.contains(.all)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: .spacingXL) {
                VStack(spacing: .spacingSM) {
                    if shouldShowNapWindow {
                        Text("When did \(babyName) last wake up?")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.foreground)
                            .multilineTextAlignment(.center)
                        
                        Text("I'll predict the next nap window")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.mutedForeground)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("Is \(babyName) awake right now?")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.foreground)
                            .multilineTextAlignment(.center)
                        
                        Text("This helps me give you better suggestions")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.mutedForeground)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, .spacingXL)
                
                if shouldShowNapWindow {
                    // Wake time options
                    VStack(spacing: .spacingMD) {
                        ForEach(WakeOption.allCases, id: \.self) { option in
                            WakeOptionButton(
                                title: option.rawValue,
                                isSelected: selectedWakeOption == option,
                                action: {
                                    selectedWakeOption = option
                                    Haptics.selection()
                                    
                                    if option == .custom {
                                        showCustomTimePicker = true
                                        coordinator.lastWakeTime = customWakeTime
                                    } else {
                                        showCustomTimePicker = false
                                        coordinator.lastWakeTime = option.getDate()
                                    }
                                    
                                    coordinator.updateNapPrediction()
                                }
                            )
                        }
                        
                        if showCustomTimePicker {
                            DatePicker(
                                "Wake time",
                                selection: $customWakeTime,
                                in: ...Date(),
                                displayedComponents: [.hourAndMinute, .date]
                            )
                            .datePickerStyle(.graphical)
                            .padding()
                            .background(Color.surface)
                            .cornerRadius(.radiusMD)
                            .onChange(of: customWakeTime) { _, newValue in
                                coordinator.lastWakeTime = newValue
                                coordinator.updateNapPrediction()
                            }
                        }
                    }
                    .padding(.horizontal, .spacingLG)
                    
                    // Nap window prediction card
                    if let napWindow = coordinator.firstNapWindow {
                        VStack(alignment: .leading, spacing: .spacingSM) {
                            HStack {
                                Image(systemName: "moon.zzz.fill")
                                    .foregroundColor(.eventSleep)
                                Text("Next nap window")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.mutedForeground)
                                Spacer()
                                if napWindow.start < Date() {
                                    Text("now")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.warning)
                                        .cornerRadius(8)
                                } else {
                                    Text("in \(minutesUntil(napWindow.start)) min")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.primary)
                                        .cornerRadius(8)
                                }
                            }
                            
                            Text(formatNapWindow(napWindow))
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.foreground)
                            
                            Text("Based on \(babyName)'s age and typical wake windows for this stage.")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.mutedForeground)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.spacingLG)
                        .background(Color.surface)
                        .cornerRadius(.radiusLG)
                        .overlay(
                            RoundedRectangle(cornerRadius: .radiusLG)
                                .stroke(Color.eventSleep.opacity(0.3), lineWidth: 2)
                        )
                        .padding(.horizontal, .spacingLG)
                    }
                    
                    // Sleeping now toggle
                    Toggle(isOn: $coordinator.isSleepingNow) {
                        Text("Actually, they're sleeping right now")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.foreground)
                    }
                    .padding(.horizontal, .spacingLG)
                    .onChange(of: coordinator.isSleepingNow) { _, _ in
                        Haptics.selection()
                    }
                } else {
                    // Simple awake/asleep options for non-nap focus
                    VStack(spacing: .spacingMD) {
                        SimpleStateButton(
                            title: "Yes, awake",
                            icon: "sun.max.fill",
                            isSelected: !coordinator.isSleepingNow,
                            action: {
                                coordinator.isSleepingNow = false
                                coordinator.lastWakeTime = Date()
                                Haptics.selection()
                            }
                        )
                        
                        SimpleStateButton(
                            title: "No, sleeping now",
                            icon: "moon.zzz.fill",
                            isSelected: coordinator.isSleepingNow,
                            action: {
                                coordinator.isSleepingNow = true
                                coordinator.lastWakeTime = nil
                                Haptics.selection()
                            }
                        )
                    }
                    .padding(.horizontal, .spacingLG)
                }
                
                Spacer(minLength: 40)
                
                VStack(spacing: .spacingSM) {
                    Button(action: {
                        Haptics.light()
                        // TODO: Analytics.track(.firstNapWindowShown)
                        coordinator.next()
                    }) {
                        Text("Continue")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.primary)
                            .cornerRadius(.radiusXL)
                            .shadow(color: Color.primary.opacity(0.3), radius: 12, x: 0, y: 6)
                    }
                    
                    Button("Skip for now") {
                        Haptics.light()
                        coordinator.skip()
                    }
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.mutedForeground)
                }
                .padding(.horizontal, .spacingLG)
                .padding(.bottom, .spacing2XL)
            }
        }
        .background(Color.background)
        .onAppear {
            // Set default last wake time
            if coordinator.lastWakeTime == nil {
                coordinator.lastWakeTime = Date()
                coordinator.updateNapPrediction()
            }
            
            Task {
                await Analytics.shared.logOnboardingStepViewed(step: "last_wake")
            }
        }
    }
    
    private var babyName: String {
        coordinator.babyName.isEmpty ? "baby" : coordinator.babyName
    }
    
    private func formatNapWindow(_ window: NapWindow) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: window.start)) – \(formatter.string(from: window.end))"
    }
    
    private func minutesUntil(_ date: Date) -> Int {
        max(0, Int(date.timeIntervalSinceNow / 60))
    }
}

// MARK: - Wake Option Button
private struct WakeOptionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .foreground)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .white : .mutedForeground)
            }
            .padding(.spacingMD)
            .background(isSelected ? Color.primary : Color.surface)
            .cornerRadius(.radiusMD)
            .overlay(
                RoundedRectangle(cornerRadius: .radiusMD)
                    .stroke(isSelected ? Color.primary : Color.cardBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Simple State Button
struct SimpleStateButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: .spacingMD) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .foreground)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .mutedForeground)
            }
            .padding(.spacingLG)
            .background(isSelected ? Color.primary : Color.surface)
            .cornerRadius(.radiusLG)
            .overlay(
                RoundedRectangle(cornerRadius: .radiusLG)
                    .stroke(isSelected ? Color.primary : Color.cardBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    LastWakeView(coordinator: OnboardingCoordinator(dataStore: InMemoryDataStore()))
}

