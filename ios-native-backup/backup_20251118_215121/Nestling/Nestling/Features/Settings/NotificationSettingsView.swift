import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @EnvironmentObject var environment: AppEnvironment
    @State private var feedReminderEnabled: Bool = true
    @State private var feedReminderHours: Int = 3
    @State private var napWindowAlertEnabled: Bool = true
    @State private var diaperReminderEnabled: Bool = true
    @State private var diaperReminderHours: Int = 2
    @State private var quietHoursStart: Date = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var quietHoursEnd: Date = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var quietHoursEnabled: Bool = false
    @State private var permissionStatus: UNAuthorizationStatus = .notDetermined
    @State private var showPermissionAlert = false
    
    var body: some View {
        Form {
            Section("Feed Reminders") {
                Toggle("Enable Feed Reminders", isOn: $feedReminderEnabled)
                
                if feedReminderEnabled {
                    Stepper("Remind every \(feedReminderHours) hours", value: $feedReminderHours, in: 1...6)
                }
            }
            
            Section("Sleep Reminders") {
                Toggle("Nap Window Alerts", isOn: $napWindowAlertEnabled)
            }
            
            Section("Diaper Reminders") {
                Toggle("Enable Diaper Reminders", isOn: $diaperReminderEnabled)
                
                if diaperReminderEnabled {
                    Stepper("Remind every \(diaperReminderHours) hours", value: $diaperReminderHours, in: 1...4)
                }
            }
            
            Section("Quiet Hours") {
                Toggle("Enable Quiet Hours", isOn: $quietHoursEnabled)
                
                if quietHoursEnabled {
                    DatePicker("Start", selection: $quietHoursStart, displayedComponents: .hourAndMinute)
                    DatePicker("End", selection: $quietHoursEnd, displayedComponents: .hourAndMinute)
                }
            }
            
            Section("Permissions") {
                HStack {
                    Text("Notification Permission")
                    Spacer()
                    Text(permissionStatusText)
                        .foregroundColor(.mutedForeground)
                        .font(.caption)
                }
                
                if permissionStatus != .authorized {
                    PrimaryButton("Request Permission") {
                        requestPermission()
                    }
                }
            }
            
            Section("Test") {
                PrimaryButton("Send Test Notification", icon: "bell.fill") {
                    NotificationScheduler.shared.sendTestNotification()
                    Haptics.success()
                }
            }
            
            Section {
                InfoBanner(
                    title: "Local Notifications",
                    message: "Notifications respect quiet hours and are scheduled locally on your device.",
                    variant: .info
                )
            }
        }
        .navigationTitle("Notification Settings")
        .onAppear {
            loadSettings()
        }
        .onChange(of: feedReminderEnabled) { _, _ in saveSettings() }
        .onChange(of: feedReminderHours) { _, _ in saveSettings() }
        .onChange(of: napWindowAlertEnabled) { _, _ in saveSettings() }
        .onChange(of: diaperReminderEnabled) { _, _ in saveSettings() }
        .onChange(of: diaperReminderHours) { _, _ in saveSettings() }
        .onChange(of: quietHoursEnabled) { _, _ in saveSettings() }
        .onChange(of: quietHoursStart) { _, _ in saveSettings() }
        .onChange(of: quietHoursEnd) { _, _ in saveSettings() }
        .task {
            await checkPermissionStatus()
        }
        .alert("Notification Permission Required", isPresented: $showPermissionAlert) {
            Button("Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable notifications in Settings to receive reminders.")
        }
    }
    
    private var permissionStatusText: String {
        switch permissionStatus {
        case .authorized: return "Authorized"
        case .denied: return "Denied"
        case .notDetermined: return "Not Determined"
        case .provisional: return "Provisional"
        @unknown default: return "Unknown"
        }
    }
    
    private func checkPermissionStatus() async {
        permissionStatus = await NotificationPermissionManager.shared.checkPermissionStatus()
    }
    
    private func requestPermission() {
        Task {
            let granted = await NotificationPermissionManager.shared.requestPermission()
            await MainActor.run {
                if granted {
                    permissionStatus = .authorized
                    saveSettings() // Schedule notifications
                } else {
                    showPermissionAlert = true
                }
            }
        }
    }
    
    private func loadSettings() {
        let settings = environment.appSettings
        feedReminderEnabled = settings.feedReminderEnabled
        feedReminderHours = settings.feedReminderHours
        napWindowAlertEnabled = settings.napWindowAlertEnabled
        diaperReminderEnabled = settings.diaperReminderEnabled
        diaperReminderHours = settings.diaperReminderHours
        quietHoursEnabled = settings.quietHoursStart != nil
        if let start = settings.quietHoursStart {
            quietHoursStart = start
        }
        if let end = settings.quietHoursEnd {
            quietHoursEnd = end
        }
    }
    
    private func saveSettings() {
        Task {
            var settings = environment.appSettings
            settings.feedReminderEnabled = feedReminderEnabled
            settings.feedReminderHours = feedReminderHours
            settings.napWindowAlertEnabled = napWindowAlertEnabled
            settings.diaperReminderEnabled = diaperReminderEnabled
            settings.diaperReminderHours = diaperReminderHours
            settings.quietHoursStart = quietHoursEnabled ? quietHoursStart : nil
            settings.quietHoursEnd = quietHoursEnabled ? quietHoursEnd : nil
            
            try? await environment.dataStore.saveAppSettings(settings)
            await MainActor.run {
                environment.appSettings = settings
            }
            
            // Schedule notifications
            if permissionStatus == .authorized {
                NotificationScheduler.shared.scheduleFeedReminder(hours: feedReminderHours, enabled: feedReminderEnabled)
                NotificationScheduler.shared.scheduleDiaperReminder(hours: diaperReminderHours, enabled: diaperReminderEnabled)
                // Nap window alerts would be scheduled when predictions are generated
            }
        }
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}

