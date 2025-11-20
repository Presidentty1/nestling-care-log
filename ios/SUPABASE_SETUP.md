# Supabase Swift SDK Setup Guide

This guide walks you through adding the Supabase Swift SDK to the Nestling iOS project.

## Prerequisites

- Xcode 15.0 or later
- macOS Sonoma or later
- Active internet connection (for package download)

## Step 1: Add Supabase Package via Xcode

1. Open `ios/Nestling/Nestling.xcodeproj` in Xcode
2. In the Project Navigator, select the **Nestling** project (top-level blue icon)
3. Select the **Nestling** target under "TARGETS"
4. Go to the **Package Dependencies** tab
5. Click the **+** button at the bottom left
6. Enter the package URL: `https://github.com/supabase/supabase-swift`
7. Click **Add Package**
8. Select **Up to Next Major Version** and ensure the latest version is selected
9. Click **Add Package**
10. Make sure the **Supabase** package is checked for the **Nestling** target
11. Click **Add Package** to complete

## Step 2: Update Secrets.swift

1. Open `ios/Nestling/Nestling/Services/Secrets.swift`
2. Find your Supabase project URL and anon key from:
   - Supabase Dashboard → Project Settings → API
   - Or from your `.env` file: `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY`
3. Update the `supabaseURL` and `supabaseAnonKey` properties in `Secrets.swift`:

```swift
static var supabaseURL: String {
    // Replace with your actual Supabase project URL
    return "https://your-project.supabase.co"
}

static var supabaseAnonKey: String {
    // Replace with your actual Supabase anon key (public key)
    return "your-anon-key-here"
}
```

**Important:** The anon key (public key) is safe to include in the app. Never use the service_role key in the client.

## Step 3: Enable SupabaseClientProvider

1. Open `ios/Nestling/Nestling/Services/SupabaseClient.swift`
2. Uncomment the `import Supabase` line at the top
3. Uncomment the `let client: SupabaseClient` property declaration
4. Uncomment the client initialization code in the `init()` method

The file should look like this after uncommenting:

```swift
import Foundation
import Supabase  // ✅ Uncommented

final class SupabaseClientProvider {
    static let shared = SupabaseClientProvider()
    
    let client: SupabaseClient  // ✅ Uncommented
    
    private init() {
        let url = Secrets.supabaseURL
        let anonKey = Secrets.supabaseAnonKey
        
        guard !url.isEmpty, !anonKey.isEmpty else {
            print("⚠️ WARNING: Supabase credentials not configured")
            return
        }
        
        // ✅ Uncommented
        self.client = SupabaseClient(
            supabaseURL: URL(string: url)!,
            supabaseKey: anonKey
        )
        
        self.configured = true
    }
    
    // ... rest of the file
}
```

## Step 4: Verify Setup

1. Build the project (⌘B)
2. Check for any compilation errors
3. If successful, you should see "✅ SupabaseClientProvider initialized" in the console when the app launches

## Troubleshooting

### Package Not Found
- Ensure you're using Xcode 15.0 or later
- Check your internet connection
- Try cleaning the build folder (Product → Clean Build Folder)

### Build Errors
- Ensure the Supabase package is added to the correct target (Nestling, not tests)
- Check that `import Supabase` is uncommented in `SupabaseClient.swift`
- Verify your Secrets.swift has valid URLs and keys

### Runtime Errors
- Verify your Supabase project URL and anon key are correct
- Check that your Supabase project is active and accessible
- Ensure RLS (Row Level Security) policies allow access if needed

## Next Steps

After completing this setup:

1. Proceed to implement `RemoteDataStore.swift` (Phase 1.1)
2. Implement authentication flow (Phase 1.2)
3. Set up data migration (Phase 1.3)

See `MVP_LAUNCH_PLAN.md` for the complete implementation roadmap.

