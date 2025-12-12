import SwiftUI

struct MoreView: View {
    @EnvironmentObject var environment: AppEnvironment
    @StateObject private var proService = ProSubscriptionService.shared
    @State private var showManageBabies = false
    @State private var showProSubscription = false
    
    var body: some View {
        NavigationStack {
            List {
                // Baby Profile Section
                if let baby = environment.currentBaby {
                    Section {
                        NavigationLink(destination: ManageBabiesView()) {
                            HStack(spacing: .spacingMD) {
                                ZStack {
                                    Circle()
                                        .fill(Color.primary.opacity(0.1))
                                        .frame(width: 56, height: 56)
                                    
                                    Text(baby.name.prefix(1).uppercased())
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(.primary)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(baby.name)
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.foreground)
                                    
                                    Text(babyAgeText(for: baby))
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(.mutedForeground)
                                }
                                
                                Spacer()
                            }
                        }
                    } header: {
                        Text("Baby Profile")
                    }
                }
                
                // Subscription Section
                Section {
                    Button(action: {
                        showProSubscription = true
                    }) {
                        HStack {
                            Image(systemName: proService.isProUser ? "star.fill" : "star")
                                .font(.system(size: 20))
                                .foregroundColor(proService.isProUser ? .yellow : .primary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(proService.isProUser ? "Pro Subscription" : "Upgrade to Pro")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.foreground)
                                
                                if proService.isProUser {
                                    Text("Active")
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(.success)
                                } else if let daysRemaining = proService.trialDaysRemaining {
                                    Text("\(daysRemaining) days left in trial")
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(.mutedForeground)
                                } else {
                                    Text("Unlock AI features")
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(.mutedForeground)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.mutedForeground)
                        }
                    }
                } header: {
                    Text("Subscription")
                }
                
                // Labs Section
                Section {
                    NavigationLink(destination: LabsView()) {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Labs")
                                    .font(.system(size: 16, weight: .semibold))
                                
                                Text("Experimental features & predictions")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(.mutedForeground)
                            }
                        } icon: {
                            Image(systemName: "flask.fill")
                                .foregroundColor(.info)
                        }
                    }
                } header: {
                    Text("Features")
                }
                
                // Settings Section
                Section {
                    NavigationLink(destination: SettingsRootView()) {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    
                    NavigationLink(destination: AboutView()) {
                        Label("About & Help", systemImage: "info.circle.fill")
                    }
                } header: {
                    Text("More")
                }
                
                // Footer
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Text("Nestling")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.mutedForeground)
                            
                            Text("Version \(appVersion)")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.mutedForeground)
                            
                            Text("Made with ❤️ for tired parents")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.mutedForeground)
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showProSubscription) {
                ProSubscriptionView()
            }
        }
    }
    
    private func babyAgeText(for baby: Baby) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .weekOfMonth, .day], from: baby.dateOfBirth, to: now)
        
        if let years = components.year, years > 0 {
            return years == 1 ? "1 year old" : "\(years) years old"
        } else if let months = components.month, months > 0 {
            return months == 1 ? "1 month old" : "\(months) months old"
        } else if let weeks = components.weekOfMonth, weeks > 0 {
            return weeks == 1 ? "1 week old" : "\(weeks) weeks old"
        } else if let days = components.day, days >= 0 {
            return days == 1 ? "1 day old" : "\(days) days old"
        }
        
        return "Newborn"
    }
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

#Preview {
    MoreView()
        .environmentObject(AppEnvironment(dataStore: InMemoryDataStore()))
}

