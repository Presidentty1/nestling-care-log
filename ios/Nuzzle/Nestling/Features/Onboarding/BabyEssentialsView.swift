import SwiftUI

struct BabyEssentialsView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @State private var showError = false
    @State private var dobError: String?
    @State private var localName: String = "" // Local state to prevent lag
    
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
                    
                    Text("We use age to suggest nap windows and tailor tips")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.mutedForeground)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, .spacingXL)
                
                // Baby Profile Form (Combined: Name + DOB + Sex)
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
                                // Debounce: Only update coordinator after brief delay
                                coordinator.babyName = newValue
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: .spacingSM) {
                        Text("🎂 Date")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.foreground)
                        
                        // Birth/Due date selector
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
                                    .foregroundColor(.info)
                                    .font(.caption)
                                Text("Nestling is optimized for 0-6 months. You can still use it, but our guidance works best for early months.")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.mutedForeground)
                            }
                            .padding(.spacingMD)
                            .background(Color.surface.opacity(0.5))
                            .cornerRadius(.radiusSM)
                        }
                    }
                    
                    // Sex selection (optional)
                    VStack(alignment: .leading, spacing: .spacingSM) {
                        Text("Sex (Optional)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.foreground)
                        
                        HStack(spacing: .spacingMD) {
                            SexButton(sex: .male, selectedSex: $coordinator.sex)
                            SexButton(sex: .female, selectedSex: $coordinator.sex)
                            SexButton(sex: .other, selectedSex: $coordinator.sex)
                        }
                    }
                    
                }
                .padding(.horizontal, .spacingLG)
                
                Spacer(minLength: 60)
                
                VStack(spacing: .spacingSM) {
                    Button(action: {
                        if !coordinator.babyName.trimmingCharacters(in: .whitespaces).isEmpty && isDOBValid {
                            Haptics.light()
                            coordinator.next()
                        } else {
                            showError = true
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
                    
                    Button("I'll add later") {
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
        .alert("Name Required", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text("Please enter your baby's name to continue.")
        }
        .onAppear {
            localName = coordinator.babyName
        }
    }
}

// MARK: - Sex Button Component
struct SexButton: View {
    let sex: Sex
    @Binding var selectedSex: Sex?
    
    private var isSelected: Bool {
        selectedSex == sex
    }
    
    private var label: String {
        switch sex {
        case .male: return "Boy"
        case .female: return "Girl"
        case .intersex: return "Intersex"
        case .preferNotToSay: return "Prefer not to say"        case .other: return "Other"
        }
    }
    
    var body: some View {
        Button(action: {
            selectedSex = isSelected ? nil : sex
            Haptics.selection()
        }) {
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isSelected ? .white : .foreground)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
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
    BabyEssentialsView(coordinator: OnboardingCoordinator(dataStore: InMemoryDataStore()))
}

