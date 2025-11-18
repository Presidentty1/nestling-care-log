import SwiftUI

struct BabySetupView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @State private var showError = false
    
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
                        DatePicker("Date of Birth", selection: $coordinator.dateOfBirth, displayedComponents: .date)
                            .datePickerStyle(.compact)
                    }
                    
                    Section("Sex (Optional)") {
                        Picker("Sex", selection: $coordinator.sex) {
                            Text("Not specified").tag(nil as Sex?)
                            ForEach(Sex.allCases, id: \.self) { s in
                                Text(s.displayName).tag(s as Sex?)
                            }
                        }
                    }
                }
                .frame(height: 300)
                
                VStack(spacing: .spacingSM) {
                    PrimaryButton("Continue", isDisabled: coordinator.babyName.trimmingCharacters(in: .whitespaces).isEmpty) {
                        coordinator.next()
                    }
                    .padding(.horizontal, .spacingMD)
                    
                    Button("Skip") {
                        coordinator.skip()
                    }
                    .foregroundColor(.mutedForeground)
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


