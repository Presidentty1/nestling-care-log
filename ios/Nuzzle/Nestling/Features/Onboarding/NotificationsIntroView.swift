import SwiftUI
import UserNotifications

struct NotificationsIntroView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    
    var body: some View {
        ScrollView {
            VStack(spacing: .spacingXL) {
                VStack(spacing: .spacingSM) {
                    Text("Want me to watch the clock for you?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.foreground)
                        .multilineTextAlignment(.center)
                    
                    Text("Get gentle nudges before \(babyName) gets overtired")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.mutedForeground)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, .spacingXL)
                .padding(.horizontal, .spacingLG)
                
                // Show nap window context if available
                if let napWindow = coordinator.firstNapWindow {
                    VStack(alignment: .leading, spacing: .spacingSM) {
                        HStack {
                            Image(systemName: "moon.zzz.fill")
                                .foregroundColor(.eventSleep)
                            Text("Next nap window")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.mutedForeground)
                            Spacer()
                        }
                        
                        Text(formatNapWindow(napWindow))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.foreground)
                    }
                    .padding(.spacingLG)
                    .background(Color.surface)
                    .cornerRadius(.radiusMD)
                    .overlay(
                        RoundedRectangle(cornerRadius: .radiusMD)
                            .stroke(Color.eventSleep.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, .spacingLG)
                }
                
                VStack(alignment: .leading, spacing: .spacingMD) {
                    NotificationBulletPoint(icon: "bell.badge.fill", text: "I'll nudge you before \(babyName) gets overtired")
                    NotificationBulletPoint(icon: "moon.zzz.fill", text: "Reminders for nap windows & bedtime")
                    NotificationBulletPoint(icon: "slider.horizontal.3", text: "You can tweak or mute reminders anytime")
                }
                .padding(.horizontal, .spacingLG)
                
                Toggle(isOn: $coordinator.wantsNapNotifications) {
                    Text("Remind me before naps & bedtime")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.foreground)
                }
                .padding(.horizontal, .spacingLG)
                .onChange(of: coordinator.wantsNapNotifications) { _, _ in
                    Haptics.selection()
                }
                
                Spacer(minLength: 40)
                
                VStack(spacing: .spacingSM) {
                    Button(action: {
                        Haptics.light()
                        requestNotificationPermission()
                    }) {
                        Text("Turn on notifications")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.primary)
                            .cornerRadius(.radiusXL)
                            .shadow(color: Color.primary.opacity(0.3), radius: 12, x: 0, y: 6)
                    }
                    
                    Button("Not now") {
                        Haptics.light()
                        coordinator.wantsNapNotifications = false
                        coordinator.next()
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
            Task {
                await Analytics.shared.logOnboardingStepViewed(step: "notifications")
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
    
    private func requestNotificationPermission() {
        Task {
            do {
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                coordinator.wantsNapNotifications = granted
                // TODO: Analytics.track(.notificationOptIn, granted: granted)
            } catch {
                logger.debug("Error requesting notification permission: \(error)")
            }
            
            await MainActor.run {
                coordinator.next()
            }
        }
    }
}

// MARK: - Notification Bullet Point
private struct NotificationBulletPoint: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: .spacingSM) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.primary)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.foreground)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    NotificationsIntroView(coordinator: OnboardingCoordinator(dataStore: InMemoryDataStore()))
}

