import SwiftUI
import UserNotifications

struct NotificationsIntroView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    
    var body: some View {
        ScrollView {
            VStack(spacing: .spacingLG) {
                VStack(spacing: .spacingMD) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.primary)
                    
                    Text("Gentle reminders, when you want them")
                        .font(.headline)
                        .foregroundColor(.foreground)
                        .multilineTextAlignment(.center)
                    
                    Text("Choose which reminders work for you. You're always in control.")
                        .font(.body)
                        .foregroundColor(.mutedForeground)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, .spacingMD)
                }
                .padding(.top, .spacing2XL)
                
                CardView {
                    VStack(alignment: .leading, spacing: .spacingMD) {
                        HStack(spacing: .spacingSM) {
                            Image(systemName: "drop.fill")
                                .foregroundColor(.eventFeed)
                            Text("Feed reminders when it's been a while")
                                .font(.body)
                        }
                        
                        HStack(spacing: .spacingSM) {
                            Image(systemName: "moon.fill")
                                .foregroundColor(.eventSleep)
                            Text("Nap window alerts based on wake time")
                                .font(.body)
                        }
                        
                        HStack(spacing: .spacingSM) {
                            Image(systemName: "drop.circle.fill")
                                .foregroundColor(.eventDiaper)
                            Text("Diaper reminders if it's been a long stretch")
                                .font(.body)
                        }
                    }
                }
                .padding(.horizontal, .spacingMD)
                
                VStack(spacing: .spacingSM) {
                    PrimaryButton("Allow notifications") {
                        requestNotificationPermission()
                    }
                    .padding(.horizontal, .spacingMD)
                    
                    Button("Not now") {
                        coordinator.completeOnboarding()
                    }
                    .foregroundColor(.mutedForeground)
                }
                .padding(.bottom, .spacing2XL)
            }
        }
        .background(Color.background)
    }
    
    private func requestNotificationPermission() {
        Task {
            _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            // Proceed with onboarding regardless of permission result
            coordinator.completeOnboarding()
        }
    }
}

#Preview {
    NotificationsIntroView(coordinator: OnboardingCoordinator(dataStore: InMemoryDataStore()))
}

