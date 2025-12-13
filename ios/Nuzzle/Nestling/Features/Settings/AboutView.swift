import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: .spacingLG) {
                // App Icon
                Image(systemName: "heart.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.primary)
                    .padding(.top, .spacing2XL)
                
                // App Name and Version
                VStack(spacing: .spacingSM) {
                    Text("Nestling")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.foreground)
                    
                    Text("Version \(appVersion)")
                        .font(.body)
                        .foregroundColor(.mutedForeground)

#if DEBUG
                    Text("Debug • Build \(buildNumber) • \(bundleIdentifier)")
                        .font(.caption2)
                        .foregroundColor(.mutedForeground)
                        .multilineTextAlignment(.center)
#endif
                }
                
                // Description
                Text("The fastest way to track your baby's daily care.")
                    .font(.body)
                    .foregroundColor(.mutedForeground)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, .spacingMD)
                
                // Links
                VStack(spacing: .spacingMD) {
                    Link("Privacy Policy", destination: URL(string: "https://nestling.app/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://nestling.app/terms")!)
                    Link("Support", destination: URL(string: "https://nestling.app/support")!)
                }
                .padding(.spacingMD)
                
                // Acknowledgments
                VStack(alignment: .leading, spacing: .spacingSM) {
                    Text("Acknowledgments")
                        .font(.headline)
                        .foregroundColor(.foreground)
                    
                    Text("Built with SwiftUI and Core Data")
                        .font(.caption)
                        .foregroundColor(.mutedForeground)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, .spacingMD)
                
                Spacer()
            }
        }
        .navigationTitle("About")
        .background(Color.background)
    }
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

#if DEBUG
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
    }

    private var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "unknown.bundle.id"
    }
#endif
}

#Preview {
    NavigationStack {
        AboutView()
    }
}

