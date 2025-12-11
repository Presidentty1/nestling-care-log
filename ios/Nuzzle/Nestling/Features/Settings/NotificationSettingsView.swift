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
    @State private var remindersPaused = false
    @State private var showPermissionAlert = false
    @State private var nextScheduledText: String = "Not scheduled"
    
    var body: some View {
        Form {
            Section("General") {
                Toggle("Pause All Reminders", isOn: $remindersPaused)
                    .onChange(of: remindersPaused) { _, paused in
                        // When pausing/unpausing, we don't need to request permission
                        // Just update the paused state
                        saveSettings()
                    }

                if remindersPaused {
                    Text("All reminders are paused. Toggle off to resume.")
                        .font(.caption)
                        .foregroundColor(.mutedForeground)
                }
            }

            Section("Feed Reminders") {
                Toggle("Enable Feed Reminders", isOn: $feedReminderEnabled)
                    .disabled(remindersPaused)
                    .onChange(of: feedReminderEnabled) { _, enabled in
                        if enabled && permissionStatus != .authorized && !remindersPaused {
                            requestPermission()
                        }
                        trackNotifToggle(type: "feed_reminder", enabled: enabled)
                    }
                
                if feedReminderEnabled {
                    Stepper("Remind every \(feedReminderHours) hours", value: $feedReminderHours, in: 1...6)
                    
                    if permissionStatus != .authorized {
                        Text("Enable notifications to receive reminders")
                            .font(.caption)
                            .foregroundColor(.mutedForeground)
                    }
                }
            }
            
            Section("Sleep Reminders") {
                Toggle("Nap Window Alerts", isOn: $napWindowAlertEnabled)
                    .disabled(remindersPaused)
                    .onChange(of: napWindowAlertEnabled) { _, enabled in
                        if enabled && permissionStatus != .authorized && !remindersPaused {
                            requestPermission()
                        }
                        trackNotifToggle(type: "nap_window", enabled: enabled)
                    }
                
                if napWindowAlertEnabled && permissionStatus != .authorized {
                    Text("Enable notifications to receive nap reminders")
                        .font(.caption)
                        .foregroundColor(.mutedForeground)
                }
            }
            
            Section("Diaper Reminders") {
                Toggle("Enable Diaper Reminders", isOn: $diaperReminderEnabled)
                    .disabled(remindersPaused)
                    .onChange(of: diaperReminderEnabled) { _, enabled in
                        if enabled && permissionStatus != .authorized && !remindersPaused {
                            requestPermission()
                        }
                        trackNotifToggle(type: "diaper_reminder", enabled: enabled)
                    }
                
                if diaperReminderEnabled {
                    Stepper("Remind every \(diaperReminderHours) hours", value: $diaperReminderHours, in: 1...4)
                    
                    if permissionStatus != .authorized {
                        Text("Enable notifications to receive reminders")
                            .font(.caption)
                            .foregroundColor(.mutedForeground)
                    }
                }
            }
            
            Section("Quiet Hours") {
                Toggle("Enable Quiet Hours", isOn: $quietHoursEnabled)
                
                if quietHoursEnabled {
                    DatePicker("Start", selection: $quietHoursStart, displayedComponents: .hourAndMinute)
                    DatePicker("End", selection: $quietHoursEnd, displayedComponents: .hourAndMinute)
                }
            }
            
            Section("Schedule Info") {
                HStack {
                    Text("Next scheduled reminder")
                    Spacer()
                    Text(nextScheduledText)
                        .font(.caption)
                        .foregroundColor(.mutedForeground)
                        .multilineTextAlignment(.trailing)
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
                    Task {
                        NotificationScheduler.shared.sendTestNotification()
                        Haptics.success()
                    }
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
            updateNextScheduledText()
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
    
    private func updateNextScheduledText() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let calendarDates: [Date] = requests.compactMap { request in
                if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                    return trigger.nextTriggerDate()
                }
                return nil
            }
            let intervalDates: [Date] = requests.compactMap { request in
                if let trigger = request.trigger as? UNTimeIntervalNotificationTrigger {
                    return Date().addingTimeInterval(trigger.timeInterval)
                }
                return nil
            }
            let all = (calendarDates + intervalDates).sorted()
            guard let next = all.first else {
                DispatchQueue.main.async {
                    self.nextScheduledText = "Not scheduled"
                }
                return
            }
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateStyle = .short
            let text = formatter.string(from: next)
            DispatchQueue.main.async {
                self.nextScheduledText = text
            }
        }
    }
    
    private var permissionStatusText: String {
        switch permissionStatus {
        case .authorized: return "Authorized"
        case .denied: return "Denied"
        case .notDetermined: return "Not Determined"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }
    
    private func checkPermissionStatus() async {
        ReminderService.shared.checkAuthorizationStatus()
        await MainActor.run {
            permissionStatus = ReminderService.shared.authorizationStatus
        }
    }
    
    private func requestPermission() {
        Task {
            let granted = await ReminderService.shared.requestAuthorization()
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
        remindersPaused = settings.remindersPaused
        Task {
            await ReminderService.shared.updatePausedState(remindersPaused)
        }
        quietHoursEnabled = settings.quietHoursStart != nil
        if let start = settings.quietHoursStart {
            quietHoursStart = start
        }
        if let end = settings.quietHoursEnd {
            quietHoursEnd = end
        }
        ReminderService.shared.updateQuietHours(start: settings.quietHoursStart, end: settings.quietHoursEnd)
    }
    
    private func saveSettings() {
        Task {
            var settings = environment.appSettings
            settings.feedReminderEnabled = feedReminderEnabled
            settings.feedReminderHours = feedReminderHours
            settings.napWindowAlertEnabled = napWindowAlertEnabled
            settings.diaperReminderEnabled = diaperReminderEnabled
            settings.diaperReminderHours = diaperReminderHours
            settings.remindersPaused = remindersPaused

            // Update ReminderService with the paused state
            await ReminderService.shared.updatePausedState(remindersPaused)
            settings.quietHoursStart = quietHoursEnabled ? quietHoursStart : nil
            settings.quietHoursEnd = quietHoursEnabled ? quietHoursEnd : nil
            ReminderService.shared.updateQuietHours(start: settings.quietHoursStart, end: settings.quietHoursEnd)
            
            try? await environment.dataStore.saveAppSettings(settings)
            await MainActor.run {
                environment.appSettings = settings
                updateNextScheduledText()
            }
            
            // Schedule notifications via ReminderService
            if permissionStatus == .authorized, environment.currentBaby != nil {
                // Feed and diaper reminders will be scheduled when events are logged (check time since)
                // Nap window reminders will be scheduled when nap window is predicted
                // For now, just save settings - reminders will be checked/scheduled when events change
            }
        }
    }
    
    private func trackNotifToggle(type: String, enabled: Bool) {
        AnalyticsService.shared.track(event: "notif_type_enabled", properties: [
            "notif_type": type,
            "enabled": enabled
        ])
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}

