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
                    Section("Name") {
                        TextField("Baby's name", text: $coordinator.babyName)
                            .textInputAutocapitalization(.words)
                    }
                    
                    Section("Date of Birth") {
                        DatePicker(
                            "Date of Birth",
                            selection: $coordinator.dateOfBirth,
                            in: ...Date(), // Prevent future dates
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
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
                    
                    Section("Sex (Optional)") {
                        Picker("Sex", selection: $coordinator.sex) {
                            Text("Not specified").tag(nil as Sex?)
                            Text("Girl").tag(Sex.female as Sex?)
                            Text("Boy").tag(Sex.male as Sex?)
                            Text("Intersex").tag(Sex.intersex as Sex?)
                            Text("Prefer not to say").tag(Sex.preferNotToSay as Sex?)
                        }
                    }
                }
                .frame(height: 320)
                .scrollDismissesKeyboard(.interactively)
                
                VStack(spacing: .spacingSM) {
                    PrimaryButton(
                        "Continue",
                        isDisabled: coordinator.babyName.trimmingCharacters(in: .whitespaces).isEmpty || !isDOBValid
                    ) {
                        if !isDOBValid {
                            dobError = "Birth date can't be in the future"
                        } else {
                            coordinator.next()
                        }
                    }
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

