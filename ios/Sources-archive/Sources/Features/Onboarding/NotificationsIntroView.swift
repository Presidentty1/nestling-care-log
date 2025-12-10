import SwiftUI

struct NotificationsIntroView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @State private var isRequestingPermission = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: .spacingLG) {
                VStack(spacing: .spacingMD) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.primary)
                    
                    Text("Stay on Track")
                        .font(.headline)
                        .foregroundColor(.foreground)
                    
                    Text("Get gentle reminders for feeds, diaper changes, and nap windows. You can customize these in Settings.")
                        .font(.body)
                        .foregroundColor(.mutedForeground)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, .spacingMD)
                }
                .padding(.top, .spacing2XL)
                
                CardView {
                    VStack(alignment: .leading, spacing: .spacingMD) {
                        HStack {
                            Image(systemName: "drop.fill")
                                .foregroundColor(.eventFeed)
                            Text("Feed reminders")
                                .font(.body)
                        }
                        
                        HStack {
                            Image(systemName: "moon.fill")
                                .foregroundColor(.eventSleep)
                            Text("Nap window alerts")
                                .font(.body)
                        }
                        
                        HStack {
                            Image(systemName: "drop.circle.fill")
                                .foregroundColor(.eventDiaper)
                            Text("Diaper change reminders")
                                .font(.body)
                        }
                    }
                }
                .padding(.horizontal, .spacingMD)
                
                InfoBanner(
                    title: "Note",
                    message: "We'll ask for notification permission when you're ready. You can enable or disable reminders anytime in Settings.",
                    variant: .info
                )
                .padding(.horizontal, .spacingMD)
                
                VStack(spacing: .spacingSM) {
                    // Epic 6 AC1: Only request permission after user taps "Allow notifications"
                    PrimaryButton("Allow notifications", icon: "bell.fill", isDisabled: isRequestingPermission) {
                        Task {
                            isRequestingPermission = true
                            let granted = await NotificationPermissionManager.shared.requestPermission()
                            isRequestingPermission = false
                            
                            // Analytics
                            await Analytics.shared.log("notification_permission_requested", parameters: [
                                "granted": granted,
                                "context": "onboarding"
                            ])
                            
                            // Complete onboarding regardless of permission result
                            coordinator.completeOnboarding()
                        }
                    }
                    .padding(.horizontal, .spacingMD)
                    
                    Button("Skip for now") {
                        // Analytics
                        Task {
                            await Analytics.shared.log("notification_permission_skipped", parameters: [
                                "context": "onboarding"
                            ])
                        }
                        coordinator.skip()
                    }
                    .foregroundColor(.mutedForeground)
                }
                .padding(.bottom, .spacing2XL)
            }
        }
        .background(NuzzleTheme.background)
    }
}

#Preview {
    NotificationsIntroView(coordinator: OnboardingCoordinator(dataStore: InMemoryDataStore()))
}


