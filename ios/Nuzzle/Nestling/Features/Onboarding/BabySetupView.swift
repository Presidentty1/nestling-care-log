import SwiftUI

struct BabySetupView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @State private var showError = false
    @State private var dobError: String?
    
    private var isDOBValid: Bool {
        coordinator.dateOfBirth <= Date()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: .spacingLG) {
                VStack(spacing: .spacingSM) {
                    Text("Tell us about your baby")
                        .font(.headline)
                        .foregroundColor(.foreground)
                    
                    Text("We'll use this to personalize your experience")
                        .font(.body)
                        .foregroundColor(.mutedForeground)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, .spacing2XL)
                
                Form {
                    Section {
                        TextField("Baby's name", text: $coordinator.babyName)
                            .textInputAutocapitalization(.words)
                            .font(.system(size: 17, weight: .regular))
                            .padding(.vertical, 4)
                    } header: {
                        Text("Name")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.foreground)
                    }
                    
                    Section {
                        DatePicker(
                            "Date of Birth",
                            selection: $coordinator.dateOfBirth,
                            in: ...Date(), // Prevent future dates
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .font(.system(size: 17, weight: .regular))
                        .padding(.vertical, 4)
                        .onChange(of: coordinator.dateOfBirth) { _, newDate in
                            if newDate > Date() {
                                dobError = "Birth date can't be in the future"
                            } else {
                                dobError = nil
                            }
                            
                            // Check if baby is >6 months old (Epic 1 AC4)
                            let ageInMonths = Calendar.current.dateComponents([.month], from: newDate, to: Date()).month ?? 0
                            if ageInMonths > 6 {
                                coordinator.showAgeWarning = true
                            } else {
                                coordinator.showAgeWarning = false
                            }
                        }
                        
                        if let dobError = dobError {
                            Text(dobError)
                                .font(.caption)
                                .foregroundColor(.destructive)
                        }
                        
                        // Age >6mo warning (Epic 1 AC4)
                        if coordinator.showAgeWarning {
                            HStack(spacing: .spacingSM) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.eventDiaper)
                                    .font(.caption)
                                Text("Nuzzle is optimized for 0-6 months. You can still use it, but guidance is best for early months.")
                                    .font(.caption)
                                    .foregroundColor(.mutedForeground)
                            }
                            .padding(.spacingSM)
                            .background(Color.surface)
                            .cornerRadius(.radiusSM)
                        }
                    }
                    
                    Section {
                        Picker("Sex", selection: $coordinator.sex) {
                            Text("Not specified").tag(nil as Sex?)
                            Text("Girl").tag(Sex.female as Sex?)
                            Text("Boy").tag(Sex.male as Sex?)
                            Text("Intersex").tag(Sex.intersex as Sex?)
                            Text("Prefer not to say").tag(Sex.preferNotToSay as Sex?)
                        }
                        .font(.system(size: 17, weight: .regular))
                    } header: {
                        Text("Sex (Optional)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.foreground)
                    }
                }
                .frame(height: 360)
                .scrollDismissesKeyboard(.interactively)
                
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
                    .padding(.horizontal, .spacingMD)
                }
                .padding(.bottom, .spacing2XL)
            }
        }
        .background(Color.background)
        .alert("Name Required", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text("Please enter your baby's name to continue.")
        }
    }
}

#Preview {
    BabySetupView(coordinator: OnboardingCoordinator(dataStore: InMemoryDataStore()))
}

