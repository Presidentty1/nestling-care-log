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
                        }
                        
                        if let dobError = dobError {
                            Text(dobError)
                                .font(.caption)
                                .foregroundColor(.destructive)
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

