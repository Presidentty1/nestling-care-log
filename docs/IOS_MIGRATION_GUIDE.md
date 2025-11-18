# iOS Migration Guide for Nestling Care Log

This guide helps you convert the Nestling web app into a native iOS app using SwiftUI.

## Prerequisites

- Xcode 15+
- macOS Sonoma or later
- iOS 17+ target
- Swift 5.9+
- CocoaPods (for Supabase iOS SDK)

## Architecture Overview

### Tech Stack Mapping

| Web (Current) | iOS (Target) |
|--------------|--------------|
| React + TypeScript | SwiftUI + Swift |
| Zustand (state) | @Observable + @State |
| React Query | Swift async/await + Combine |
| Supabase JS | Supabase Swift SDK |
| localforage | UserDefaults + CoreData |
| React Router | NavigationStack |
| Tailwind CSS | Native SwiftUI styling |

## Phase 1: Project Setup

### 1.1 Create Xcode Project

```bash
# Create new iOS app project
# App Name: Nestling
# Organization Identifier: app.lovable
# Bundle ID: app.lovable.3be850d6430e4062887da465d2abf643
# Interface: SwiftUI
# Language: Swift
# Storage: None (we'll use Supabase)
```

### 1.2 Install Supabase iOS SDK

Add to `Podfile`:
```ruby
platform :ios, '17.0'

target 'Nestling' do
  use_frameworks!
  
  # Supabase
  pod 'Supabase', '~> 2.0'
  pod 'GoTrue', '~> 2.0'
  pod 'PostgREST', '~> 2.0'
  pod 'Realtime', '~> 2.0'
  pod 'Storage', '~> 2.0'
  pod 'Functions', '~> 2.0'
end
```

Run:
```bash
pod install
```

### 1.3 Configure Supabase Client

Create `Services/SupabaseClient.swift`:
```swift
import Supabase
import Foundation

@MainActor
class SupabaseClient: ObservableObject {
    static let shared = SupabaseClient()
    
    let client: SupabaseClient
    
    private init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: "https://tzvkwhznmkzfpenzxbfz.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR6dmt3aHpubWt6ZnBlbnp4YmZ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMwNjc5MjIsImV4cCI6MjA3ODY0MzkyMn0.OihzLKsB663MqotEGX9xxr6lNBCMjKDjcxTLwnDdTMA"
        )
    }
}
```

## Phase 2: Core Data Models

### 2.1 Create Swift Models

Map from `src/integrations/supabase/types.ts` to Swift structs.

Create `Models/Baby.swift`:
```swift
import Foundation

struct Baby: Codable, Identifiable {
    let id: UUID
    let familyId: UUID
    let name: String
    let dateOfBirth: Date
    let dueDate: Date?
    let sex: String?
    let primaryFeedingStyle: String?
    let timezone: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name, sex, timezone
        case familyId = "family_id"
        case dateOfBirth = "date_of_birth"
        case dueDate = "due_date"
        case primaryFeedingStyle = "primary_feeding_style"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
```

Create `Models/Event.swift`:
```swift
import Foundation

struct Event: Codable, Identifiable {
    let id: UUID
    let babyId: UUID
    let familyId: UUID
    let type: EventType
    let startTime: Date
    let endTime: Date?
    let amount: Double?
    let unit: String?
    let side: String?
    let subtype: String?
    let note: String?
    let createdBy: UUID?
    let createdAt: Date
    let updatedAt: Date
    
    enum EventType: String, Codable {
        case feed, diaper, sleep, tummyTime = "tummy_time"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, type, amount, unit, side, subtype, note
        case babyId = "baby_id"
        case familyId = "family_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
```

### 2.2 Create ViewModels

Create `ViewModels/BabyViewModel.swift`:
```swift
import Foundation
import Supabase

@MainActor
@Observable
class BabyViewModel {
    var babies: [Baby] = []
    var activeBaby: Baby?
    var isLoading = false
    var errorMessage: String?
    
    private let supabase = SupabaseClient.shared.client
    
    func fetchBabies() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response: [Baby] = try await supabase
                .from("babies")
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value
            
            babies = response
            if activeBaby == nil {
                activeBaby = babies.first
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func setActiveBaby(_ baby: Baby) {
        activeBaby = baby
        UserDefaults.standard.set(baby.id.uuidString, forKey: "activeBabyId")
    }
}
```

## Phase 3: Navigation Structure

### 3.1 Main App Structure

Create `NestlingApp.swift`:
```swift
import SwiftUI

@main
struct NestlingApp: App {
    @State private var authViewModel = AuthViewModel()
    @State private var babyViewModel = BabyViewModel()
    
    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                MainTabView()
                    .environment(authViewModel)
                    .environment(babyViewModel)
            } else {
                AuthView()
                    .environment(authViewModel)
            }
        }
    }
}
```

### 3.2 Tab Navigation

Create `Views/MainTabView.swift`:
```swift
import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Today", systemImage: "house.fill")
                }
                .tag(0)
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "calendar")
                }
                .tag(1)
            
            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
    }
}
```

## Phase 4: UI Components

### 4.1 Component Mapping

See `COMPONENT_INVENTORY.md` for complete component catalog.

Key mappings:
- `Button` → `Button` with `.buttonStyle()`
- `Card` → `VStack` with `.background()` and `.cornerRadius()`
- `Sheet` → `.sheet()` modifier
- `Dialog` → `.alert()` or `.sheet()`
- `Toast` → Custom `ToastView` with animation

### 4.2 Design System

See `DESIGN_TOKENS_IOS.md` for complete design token mapping.

Create `Theme/DesignTokens.swift`:
```swift
import SwiftUI

enum DesignTokens {
    // Colors
    enum Colors {
        static let primary = Color(hue: 0.55, saturation: 0.85, brightness: 0.7)
        static let primarySoft = Color(hue: 0.55, saturation: 0.4, brightness: 0.95)
        static let background = Color(.systemBackground)
        static let surface = Color(.secondarySystemBackground)
        // ... see DESIGN_TOKENS_IOS.md
    }
    
    // Typography
    enum FontSize {
        static let h1: CGFloat = 32
        static let h2: CGFloat = 24
        static let h3: CGFloat = 20
        static let body: CGFloat = 16
        static let caption: CGFloat = 14
    }
    
    // Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }
    
    // Corner Radius
    enum CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let pill: CGFloat = 999
    }
}
```

## Phase 5: Core Features Implementation

### 5.1 Home Screen (P0)

Create `Views/Home/HomeView.swift`:
```swift
import SwiftUI

struct HomeView: View {
    @Environment(BabyViewModel.self) private var babyViewModel
    @State private var eventViewModel = EventViewModel()
    @State private var showLogSheet = false
    @State private var logType: Event.EventType?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.md) {
                    // Baby selector
                    if let baby = babyViewModel.activeBaby {
                        BabySelectorCard(baby: baby)
                    }
                    
                    // Next nap prediction
                    NapPredictionCard()
                    
                    // Quick actions
                    QuickActionsGrid(onAction: { type in
                        logType = type
                        showLogSheet = true
                    })
                    
                    // Today's timeline
                    TodayTimelineView()
                }
                .padding(DesignTokens.Spacing.md)
            }
            .navigationTitle("Today")
            .sheet(isPresented: $showLogSheet) {
                if let type = logType {
                    LogEventSheet(eventType: type)
                }
            }
        }
    }
}
```

### 5.2 Logging Screens (P0)

Create `Views/Logging/LogEventSheet.swift`:
```swift
import SwiftUI

struct LogEventSheet: View {
    let eventType: Event.EventType
    @Environment(\.dismiss) private var dismiss
    @State private var eventViewModel = EventViewModel()
    
    var body: some View {
        NavigationStack {
            Form {
                switch eventType {
                case .feed:
                    FeedFormView()
                case .diaper:
                    DiaperFormView()
                case .sleep:
                    SleepFormView()
                case .tummyTime:
                    TummyTimeFormView()
                }
            }
            .navigationTitle("Log \(eventType.rawValue.capitalized)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await eventViewModel.saveEvent()
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}
```

### 5.3 AI Features (P0)

Create `ViewModels/AIViewModel.swift`:
```swift
import Foundation
import Supabase

@MainActor
@Observable
class AIViewModel {
    var aiDataSharingEnabled = false
    var isLoading = false
    var errorMessage: String?
    
    private let supabase = SupabaseClient.shared.client
    
    func checkAIConsent() async {
        do {
            let profile: Profile = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: supabase.auth.currentUser?.id ?? "")
                .single()
                .execute()
                .value
            
            aiDataSharingEnabled = profile.aiDataSharingEnabled ?? false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func updateAIConsent(enabled: Bool) async {
        isLoading = true
        
        do {
            try await supabase
                .from("profiles")
                .update(["ai_data_sharing_enabled": enabled])
                .eq("id", value: supabase.auth.currentUser?.id ?? "")
                .execute()
            
            aiDataSharingEnabled = enabled
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
```

## Phase 6: Testing Strategy

### 6.1 Unit Tests

Create `NestlingTests/ViewModelTests.swift`:
```swift
import XCTest
@testable import Nestling

final class BabyViewModelTests: XCTestCase {
    func testFetchBabies() async {
        let viewModel = BabyViewModel()
        await viewModel.fetchBabies()
        XCTAssertFalse(viewModel.babies.isEmpty)
    }
}
```

### 6.2 UI Tests

Create `NestlingUITests/HomeFlowTests.swift`:
```swift
import XCTest

final class HomeFlowTests: XCTestCase {
    func testQuickLogFlow() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Test feed logging
        app.buttons["Log Feed"].tap()
        // ... assertions
    }
}
```

## Phase 7: Deployment

### 7.1 App Store Assets

Required:
- App icon (1024x1024px) - see `APP_ICON_GUIDELINES.md`
- Screenshots (6.7", 6.5", 5.5" displays)
- Privacy nutrition labels
- App Store description (see `APP_STORE_METADATA.md`)

### 7.2 Build Configuration

1. Set deployment target to iOS 17.0
2. Configure signing & capabilities:
   - Push Notifications
   - Background Modes (for timers)
   - Microphone (for cry analysis)
3. Add privacy usage descriptions to Info.plist:
   - NSMicrophoneUsageDescription
   - NSPhotoLibraryUsageDescription

### 7.3 TestFlight Distribution

```bash
# Archive for distribution
xcodebuild archive \
  -workspace Nestling.xcworkspace \
  -scheme Nestling \
  -configuration Release \
  -archivePath ./build/Nestling.xcarchive

# Export IPA
xcodebuild -exportArchive \
  -archivePath ./build/Nestling.xcarchive \
  -exportPath ./build \
  -exportOptionsPlist ExportOptions.plist
```

## Migration Checklist

### Must Have (P0)
- [ ] Authentication (sign up, login, logout)
- [ ] Baby profile creation/switching
- [ ] Feed logging (breast, bottle, pumping)
- [ ] Diaper logging (wet, dirty, mixed)
- [ ] Sleep logging (start/stop timer, manual entry)
- [ ] Home dashboard with timeline
- [ ] Next nap prediction
- [ ] Basic AI Q&A (with consent check)
- [ ] Settings (profile, preferences)
- [ ] Offline support (CoreData cache)

### Should Have (P1)
- [ ] History view with filtering
- [ ] Analytics/insights
- [ ] Cry analysis
- [ ] Smart predictions
- [ ] Multi-caregiver sync
- [ ] Push notifications
- [ ] Voice logging
- [ ] Medical disclaimers

### Nice to Have (P2+)
- [ ] Photo gallery
- [ ] Milestones
- [ ] Growth tracking
- [ ] Sleep training
- [ ] Parent wellness
- [ ] Referrals
- [ ] Widgets
- [ ] Apple Watch companion

## Resources

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Supabase Swift SDK](https://github.com/supabase/supabase-swift)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- See `ARCHITECTURE.md` for current web architecture
- See `DATA_MODEL.md` for database schema
- See `COMPONENT_INVENTORY.md` for UI components
- See `API_ENDPOINTS.md` for backend API contracts
- See `DESIGN_TOKENS_IOS.md` for design system mapping

## Getting Help

If you encounter issues during migration:
1. Check the web app's behavior in browser for reference
2. Review error logs in Supabase dashboard
3. Test API calls using Postman/Insomnia first
4. Use SwiftUI previews for rapid UI iteration
