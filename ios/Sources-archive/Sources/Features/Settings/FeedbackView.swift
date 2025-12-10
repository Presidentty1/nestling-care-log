import SwiftUI

struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var rating: Int = 3
    @State private var category: FeedbackCategory = .general
    @State private var message = ""
    @State private var includeDeviceInfo = true
    @State private var isSubmitting = false
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacingXL) {
                    // Header
                    VStack(spacing: .spacingMD) {
                        Image(systemName: "text.bubble.fill")
                            .font(.system(size: 64))
                            .foregroundColor(Color.adaptivePrimary(colorScheme))

                        Text("Send Feedback")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color.adaptiveForeground(colorScheme))

                        Text("Help us improve Nestling with your thoughts and suggestions")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                    }
                    .padding(.horizontal, .spacingMD)

                    // Rating
                    VStack(alignment: .leading, spacing: .spacingMD) {
                        Text("Overall Experience")
                            .font(.headline)
                            .foregroundColor(Color.adaptiveForeground(colorScheme))

                        HStack(spacing: .spacingMD) {
                            ForEach(1...5, id: \.self) { star in
                                Button(action: {
                                    rating = star
                                    Haptics.light()
                                }) {
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .font(.system(size: 32))
                                        .foregroundColor(star <= rating ? .yellow : Color.adaptiveTextTertiary(colorScheme))
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Text(ratingText(for: rating))
                            .font(.caption)
                            .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                    }
                    .padding(.horizontal, .spacingMD)

                    // Category
                    VStack(alignment: .leading, spacing: .spacingMD) {
                        Text("Category")
                            .font(.headline)
                            .foregroundColor(Color.adaptiveForeground(colorScheme))

                        Picker("Category", selection: $category) {
                            ForEach(FeedbackCategory.allCases, id: \.self) { category in
                                Text(category.displayName).tag(category)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal, .spacingMD)

                    // Message
                    VStack(alignment: .leading, spacing: .spacingMD) {
                        Text("Message")
                            .font(.headline)
                            .foregroundColor(Color.adaptiveForeground(colorScheme))

                        TextEditor(text: $message)
                            .frame(height: 120)
                            .padding(.spacingSM)
                            .background(Color.adaptiveSurface(colorScheme))
                            .cornerRadius(.radiusMD)
                            .overlay(
                                RoundedRectangle(cornerRadius: .radiusMD)
                                    .stroke(Color.adaptiveTextTertiary(colorScheme).opacity(0.3), lineWidth: 1)
                            )

                        Text("\(message.count)/500 characters")
                            .font(.caption)
                            .foregroundColor(message.count > 450 ? .red : Color.adaptiveTextTertiary(colorScheme))
                    }
                    .padding(.horizontal, .spacingMD)

                    // Options
                    VStack(alignment: .leading, spacing: .spacingMD) {
                        Toggle("Include device and app information", isOn: $includeDeviceInfo)

                        Text("This helps us understand your setup and provide better support")
                            .font(.caption)
                            .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                    }
                    .padding(.horizontal, .spacingMD)

                    // Submit Button
                    PrimaryButton(
                        "Send Feedback",
                        icon: "paperplane.fill",
                        isLoading: isSubmitting
                    ) {
                        Task {
                            await submitFeedback()
                        }
                    }
                    .disabled(message.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
                    .padding(.horizontal, .spacingMD)

                    Spacer()
                }
                .padding(.vertical, .spacing2XL)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                }
            }
            .alert("Thank You!", isPresented: $showSuccess) {
                Button("OK", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("We read every message and appreciate your feedback. This helps us make Nestling better for everyone!")
            }
        }
    }

    private func ratingText(for rating: Int) -> String {
        switch rating {
        case 1: return "Poor"
        case 2: return "Fair"
        case 3: return "Good"
        case 4: return "Great"
        case 5: return "Excellent"
        default: return ""
        }
    }

    private func submitFeedback() async {
        isSubmitting = true

        // Prepare feedback data
        var feedbackData: [String: Any] = [
            "rating": rating,
            "category": category.rawValue,
            "message": message,
            "timestamp": Date().ISO8601Format(),
            "platform": "iOS",
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        ]

        if includeDeviceInfo {
            feedbackData["device_info"] = [
                "model": UIDevice.current.model,
                "system_version": UIDevice.current.systemVersion,
                "app_version": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
            ]
        }

        // In a real implementation, this would send to a backend service
        // For now, we'll just log it and simulate success
        Logger.info("Feedback submitted: \(feedbackData)")

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        await MainActor.run {
            isSubmitting = false
            showSuccess = true
        }

        // Analytics
        await Analytics.shared.log("feedback_submitted", parameters: [
            "rating": rating,
            "category": category.rawValue,
            "message_length": message.count,
            "include_device_info": includeDeviceInfo
        ])
    }
}

enum FeedbackCategory: String, CaseIterable, Identifiable {
    case bug = "bug"
    case idea = "idea" // Epic 9 AC1: "idea" category
    case confusing = "confusing" // Epic 9 AC1: "confusing" category
    case other = "other" // Epic 9 AC1: "other" category
    case general = "general"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bug: return "Bug Report"
        case .idea: return "Feature Idea"
        case .confusing: return "Something Confusing"
        case .other: return "Other"
        case .general: return "General Feedback"
        }
    }
}

#Preview {
    FeedbackView()
}