# Supabase Integration Guide

This guide explains how to integrate Supabase cloud sync into the iOS app.

## Current Status

✅ **RemoteDataStore** implementation created (placeholder)  
✅ **SupabaseClient** wrapper created (placeholder)  
⏳ **Requires**: Supabase Swift SDK installation

## Architecture

The app uses a **protocol-based DataStore** that allows swapping implementations:

```
DataStore Protocol
├── InMemoryDataStore (for testing/previews)
├── JSONBackedDataStore (local-only MVP)
├── CoreDataDataStore (local persistence)
└── RemoteDataStore (cloud sync) ← NEW
```

## Setup Steps

### 1. Add Supabase Swift SDK

1. **Open Xcode project**
2. **File → Add Package Dependencies**
3. **Enter URL**: `https://github.com/supabase/supabase-swift`
4. **Select version**: Latest release
5. **Add to target**: Nestling ✅

### 2. Configure Supabase Client

Add your Supabase credentials to `AppEnvironment.swift` or create a config file:

```swift
// In AppEnvironment.swift or new SupabaseConfig.swift

let SUPABASE_URL = "https://your-project.supabase.co"
let SUPABASE_ANON_KEY = "your-anon-key-here"

// Initialize Supabase client
SupabaseClient.shared.configure(url: SUPABASE_URL, anonKey: SUPABASE_ANON_KEY)
```

**⚠️ Security Note**: For production, store credentials in:
- Environment variables (for development)
- Secure keychain (for production)
- Never commit keys to git

### 3. Update RemoteDataStore

1. **Open** `ios/Sources/Domain/Services/RemoteDataStore.swift`
2. **Replace placeholder** `supabaseClient: Any?` with actual Supabase client
3. **Uncomment and implement** all `// TODO:` sections
4. **Follow examples** in comments for each method

### 4. Switch to RemoteDataStore

In `NestlingApp.swift`, update `DataStoreSelector`:

```swift
// Option 1: Always use RemoteDataStore (when authenticated)
let dataStore: DataStore = {
    if SupabaseClient.shared.isConfigured {
        return RemoteDataStore(
            supabaseURL: SUPABASE_URL,
            anonKey: SUPABASE_ANON_KEY
        )
    } else {
        return JSONBackedDataStore() // Fallback to local
    }
}()

// Option 2: Hybrid (local-first with sync)
// Use JSONBackedDataStore for local, sync to RemoteDataStore in background
```

### 5. Add Authentication Flow

Create an authentication view:

```swift
// Sources/Features/Auth/AuthView.swift

struct AuthView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    
    var body: some View {
        VStack {
            TextField("Email", text: $email)
            SecureField("Password", text: $password)
            
            Button(isSignUp ? "Sign Up" : "Sign In") {
                Task {
                    if isSignUp {
                        try await SupabaseClient.shared.signUp(
                            email: email,
                            password: password,
                            name: nil
                        )
                    } else {
                        try await SupabaseClient.shared.signIn(
                            email: email,
                            password: password
                        )
                    }
                }
            }
        }
    }
}
```

### 6. Update AppEnvironment

Add authentication state to `AppEnvironment`:

```swift
@Published var isAuthenticated: Bool = false
@Published var currentUser: User?

func checkAuthentication() {
    Task {
        if let session = try? await SupabaseClient.shared.getCurrentSession() {
            isAuthenticated = true
            // Load user data
        } else {
            isAuthenticated = false
        }
    }
}
```

## Database Schema

The Supabase database should match the iOS models:

### Tables

- **babies**: `id`, `family_id`, `name`, `date_of_birth`, `sex`, `timezone`, `primary_feeding_style`, `created_at`, `updated_at`
- **events**: `id`, `baby_id`, `type`, `subtype`, `start_time`, `end_time`, `amount`, `unit`, `side`, `note`, `created_at`, `updated_at`
- **app_settings**: `user_id`, `ai_data_sharing_enabled`, `feed_reminder_enabled`, etc.
- **profiles**: `id`, `email`, `name`, `ai_data_sharing_enabled`

### RLS Policies

Ensure Row Level Security (RLS) is enabled:

```sql
-- Example: Users can only access their family's babies
CREATE POLICY "Users can view their family's babies"
ON babies FOR SELECT
USING (
    family_id IN (
        SELECT family_id FROM family_members
        WHERE user_id = auth.uid()
    )
);
```

## Edge Functions

The app uses Supabase Edge Functions for AI features:

### generate-predictions

```swift
let response = try await supabaseClient.functions
    .invoke("generate-predictions", body: [
        "babyId": baby.id.uuidString,
        "predictionType": "nap_window"
    ])
```

### ai-assistant

```swift
let response = try await supabaseClient.functions
    .invoke("ai-assistant", body: [
        "babyId": baby.id.uuidString,
        "message": userQuestion
    ])
```

## Sync Strategy

### Option 1: Always Remote (Simple)

- Use `RemoteDataStore` when authenticated
- Use `JSONBackedDataStore` when offline
- No local caching

### Option 2: Local-First with Background Sync (Recommended)

- Use `JSONBackedDataStore` for immediate UI updates
- Sync to `RemoteDataStore` in background
- Handle conflicts (last-write-wins or merge)

### Option 3: Hybrid Store

Create a `HybridDataStore` that:
- Writes to both local and remote
- Reads from local (faster)
- Syncs in background
- Handles offline mode

## Error Handling

Handle common errors:

```swift
do {
    try await remoteStore.addEvent(event)
} catch DataStoreError.networkError(let error) {
    // Show offline message, queue for sync
} catch DataStoreError.authenticationRequired {
    // Show login screen
} catch {
    // Show generic error
}
```

## Testing

1. **Test authentication flow**
2. **Test CRUD operations** (create, read, update, delete)
3. **Test offline mode** (airplane mode)
4. **Test sync conflicts** (edit same event on two devices)
5. **Test RLS policies** (user can't access other families' data)

## Migration from Local to Cloud

When user signs in:

1. **Export local data** (JSON)
2. **Import to Supabase** (via RemoteDataStore)
3. **Switch to RemoteDataStore**
4. **Delete local JSON** (optional)

## Security Checklist

- [ ] Never commit Supabase keys to git
- [ ] Use environment variables for development
- [ ] Use Keychain for production keys
- [ ] Verify RLS policies are correct
- [ ] Test authentication flows
- [ ] Test authorization (users can't access others' data)
- [ ] Enable HTTPS only
- [ ] Validate all inputs server-side

## Resources

- [Supabase Swift SDK](https://github.com/supabase/supabase-swift)
- [Supabase iOS Guide](https://supabase.com/docs/guides/getting-started/tutorials/with-swift)
- [RLS Policies](https://supabase.com/docs/guides/auth/row-level-security)
- [Edge Functions](https://supabase.com/docs/guides/functions)

## Next Steps

1. ✅ RemoteDataStore placeholder created
2. ⏳ Add Supabase Swift SDK
3. ⏳ Implement RemoteDataStore methods
4. ⏳ Add authentication flow
5. ⏳ Test sync functionality
6. ⏳ Handle offline mode
7. ⏳ Implement conflict resolution


