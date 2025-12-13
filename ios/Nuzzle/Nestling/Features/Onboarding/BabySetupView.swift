import SwiftUI

struct BabySetupView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @State private var showError = false
    @State private var dobError: String?
    @State private var localName: String = ""
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
            case .justNow: return now
            case .fifteenMin: return now.addingTimeInterval(-15 * 60)
            case .thirtyMin: return now.addingTimeInterval(-30 * 60)
            case .fortyFiveMin: return now.addingTimeInterval(-45 * 60)
            case .custom: return now
            }
        }
    }
    
    private var isDOBValid: Bool {
        coordinator.dateOfBirth <= Date()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: .spacingXL) {
                VStack(spacing: .spacingSM) {
                    Text("Who is this for?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.foreground)
                    
                    Text("We'll use age to suggest nap windows and tailor tips")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.mutedForeground)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, .spacingXL)
                
                // Baby Profile Form
                VStack(alignment: .leading, spacing: .spacingLG) {
                    VStack(alignment: .leading, spacing: .spacingSM) {
                        Text("👶 Baby's Name")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.foreground)
                        
                        TextField("Enter name", text: $localName)
                            .textInputAutocapitalization(.words)
                            .font(.system(size: 17, weight: .regular))
                            .padding()
                            .frame(height: 56)
                            .background(Color.surface)
                            .cornerRadius(.radiusMD)
                            .overlay(
                                RoundedRectangle(cornerRadius: .radiusMD)
                                    .stroke(Color.cardBorder, lineWidth: 1)
                            )
                            .onChange(of: localName) { _, newValue in
                                coordinator.babyName = newValue
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: .spacingSM) {
                        Text("🎂 Date")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.foreground)
                        
                        Picker("Date Type", selection: $coordinator.birthDueSelection) {
                            Text("Date of Birth").tag(BirthDueSelection.dateOfBirth)
                            Text("Due Date").tag(BirthDueSelection.dueDate)
                        }
                        .pickerStyle(.segmented)
                        .padding(.bottom, .spacingSM)
                        
                        if coordinator.birthDueSelection == .dateOfBirth {
                            DatePicker(
                                "Date of Birth",
                                selection: $coordinator.dateOfBirth,
                                in: ...Date(),
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .font(.system(size: 17, weight: .regular))
                            .padding()
                            .frame(height: 56)
                            .background(Color.surface)
                            .cornerRadius(.radiusMD)
                            .overlay(
                                RoundedRectangle(cornerRadius: .radiusMD)
                                    .stroke(Color.cardBorder, lineWidth: 1)
                            )
                            .onChange(of: coordinator.dateOfBirth) { _, newDate in
                                if newDate > Date() {
                                    dobError = "Birth date can't be in the future"
                                } else {
                                    dobError = nil
                                }
                                
                                let ageInMonths = Calendar.current.dateComponents([.month], from: newDate, to: Date()).month ?? 0
                                if ageInMonths > 6 {
                                    coordinator.showAgeWarning = true
                                } else {
                                    coordinator.showAgeWarning = false
                                }
                                
                                // Update nap prediction when DOB changes
                                coordinator.updateNapPrediction()
                            }
                        } else {
                            DatePicker(
                                "Due Date",
                                selection: $coordinator.dueDate,
                                in: Date()...,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .font(.system(size: 17, weight: .regular))
                            .padding()
                            .frame(height: 56)
                            .background(Color.surface)
                            .cornerRadius(.radiusMD)
                            .overlay(
                                RoundedRectangle(cornerRadius: .radiusMD)
                                    .stroke(Color.cardBorder, lineWidth: 1)
                            )
                        }
                        
                        if let dobError = dobError {
                            Text(dobError)
                                .font(.caption)
                                .foregroundColor(.destructive)
                        }
                        
                        if coordinator.showAgeWarning {
                            HStack(spacing: .spacingSM) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.eventDiaper)
                                    .font(.caption)
                                Text("Nestling is optimized for 0-6 months. You can still use it, but guidance is best for early months.")
                                    .font(.caption)
                                    .foregroundColor(.mutedForeground)
                            }
                            .padding(.spacingSM)
                            .background(Color.surface)
                            .cornerRadius(.radiusSM)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: .spacingSM) {
                        Text("Gender (Optional)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.foreground)
                        
                        Picker("Gender", selection: $coordinator.sex) {
                            Text("Not specified").tag(nil as Sex?)
                            Text("Girl").tag(Sex.female as Sex?)
                            Text("Boy").tag(Sex.male as Sex?)
                            Text("Intersex").tag(Sex.intersex as Sex?)
                            Text("Prefer not to say").tag(Sex.preferNotToSay as Sex?)
                        }
                        .font(.system(size: 17, weight: .regular))
                        .padding()
                        .frame(height: 56)
                        .background(Color.surface)
                        .cornerRadius(.radiusMD)
                        .overlay(
                            RoundedRectangle(cornerRadius: .radiusMD)
                                .stroke(Color.cardBorder, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, .spacingLG)
                
                // Nap prediction section (shown after baby info is entered)
                if !coordinator.babyName.isEmpty && isDOBValid {
                    VStack(spacing: .spacingMD) {
                        Text("When did \(babyName) last wake up?")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.foreground)
                            .multilineTextAlignment(.center)
                        
                        VStack(spacing: .spacingSM) {
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
                    }
                    .padding(.top, .spacingMD)
                }
                
                Spacer(minLength: 40)
                
                VStack(spacing: .spacingSM) {
                    Button(action: {
                        if !isDOBValid {
                            dobError = "Birth date can't be in the future"
                        } else {
                            Haptics.light()
                            coordinator.next()
                        }
                    }) {
                        Text("Continue")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                coordinator.babyName.trimmingCharacters(in: .whitespaces).isEmpty || !isDOBValid
                                    ? Color.primary.opacity(0.5)
                                    : Color.primary
                            )
                            .cornerRadius(.radiusXL)
                            .shadow(
                                color: coordinator.babyName.trimmingCharacters(in: .whitespaces).isEmpty || !isDOBValid
                                    ? .clear
                                    : Color.primary.opacity(0.3),
                                radius: 12,
                                x: 0,
                                y: 6
                            )
                    }
                    .disabled(coordinator.babyName.trimmingCharacters(in: .whitespaces).isEmpty || !isDOBValid)
                    .padding(.horizontal, .spacingLG)
                    
                    Button("Skip for now") {
                        Haptics.light()
                        coordinator.skip()
                    }
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.mutedForeground)
                }
                .padding(.bottom, .spacing2XL)
            }
        }
        .background(Color.background)
        .onAppear {
            // Set default last wake time and update prediction
            if coordinator.lastWakeTime == nil {
                coordinator.lastWakeTime = Date()
                coordinator.updateNapPrediction()
            }
            
            Task {
                await Analytics.shared.logOnboardingStepViewed(step: "baby_setup")
            }
        }
        .alert("Name Required", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text("Please enter your baby's name to continue.")
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

#Preview {
    BabySetupView(coordinator: OnboardingCoordinator(dataStore: InMemoryDataStore()))
}

