# Firebase Setup for iOS

## Adding Firebase iOS SDK

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing
3. Enable Google Analytics if prompted

### 2. Add iOS App to Firebase

1. In Firebase Console, click "Add app" → iOS icon
2. Bundle ID: `app.lovable.3be850d6430e4062887da465d2abf643`
3. App nickname: `Nuzzle`
4. Download `GoogleService-Info.plist`
5. Add the file to `ios/Nuzzle/Nuzzle/` directory

### 3. Add Firebase SDK via Swift Package Manager

1. Open Xcode project: `ios/Nuzzle/Nuzzle.xcodeproj`
2. **File → Add Package Dependencies...**
3. Enter: `https://github.com/firebase/firebase-ios-sdk.git`
4. Set dependency rule: **Up to Next Major Version** `10.0.0`
5. Add these products to Nuzzle target:
   - FirebaseAnalytics
   - FirebaseCore
   - FirebaseCrashlytics (optional, for additional crash reporting)

### 4. Configure Environment Variables

Add to your Xcode scheme environment variables:

```
# Product → Scheme → Edit Scheme → Run → Arguments → Environment Variables
FIREBASE_ENABLED=true
```

Or create a `.xcconfig` file in the project.

### 5. Initialize Firebase in App Delegate

The app will automatically initialize Firebase when the AnalyticsService is created.

## Firebase Analytics Events

The app tracks these key events:

### User Journey

- `app_open` - App launched
- `user_signup` - User created account
- `baby_added` - First baby profile created
- `onboarding_complete` - Onboarding finished

### Core Actions

- `event_logged` - Feed, sleep, diaper, or tummy time logged
- `event_edited` - Event modified
- `event_deleted` - Event removed
- `settings_changed` - User updated preferences

### Business Metrics

- `paywall_viewed` - Pro upgrade screen shown
- `subscription_started` - User purchased subscription
- `trial_started` - Free trial activated
- `feature_used` - Pro feature accessed

### Error Tracking

- `error_occurred` - App errors logged
- `sync_failed` - Data sync issues
- `permission_denied` - User denied permissions

## User Properties

Firebase tracks these user characteristics:

- `user_id` - Supabase user ID
- `baby_count` - Number of babies
- `subscription_status` - free/pro/trial
- `days_active` - Consecutive usage days
- `platform` - ios/web
- `app_version` - Current app version

## Testing Firebase Integration

### 1. Debug Mode

Enable debug mode to see events in Firebase console immediately:

```bash
# In Xcode scheme environment variables
FIREBASE_ANALYTICS_DEBUG_MODE=1
```

### 2. Test Events

```swift
// In Xcode debug console or code
AnalyticsService.shared.trackEvent("test_event", parameters: ["test": "value"])
```

### 3. Verify in Firebase Console

1. Go to Firebase Console → Analytics → Events
2. Events should appear within minutes in debug mode
3. Check user properties in Audiences section

## Firebase Remote Config (Optional)

For A/B testing of paywall variations:

1. Enable Remote Config in Firebase Console
2. Add parameters like `paywall_variant` with different values
3. Fetch config in app and use for paywall testing

## Environment Variables

Required environment variables:

```bash
# Web app (.env)
VITE_FIREBASE_API_KEY=your-api-key
VITE_FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=your-project-id
VITE_FIREBASE_STORAGE_BUCKET=your-project.appspot.com
VITE_FIREBASE_MESSAGING_SENDER_ID=123456789
VITE_FIREBASE_APP_ID=1:123456789:web:abcdef123456
VITE_FIREBASE_MEASUREMENT_ID=G-ABCDEFGHIJ

# iOS (Xcode scheme environment variables)
FIREBASE_ENABLED=true
```

## Privacy & Compliance

- Firebase Analytics respects app privacy settings
- Analytics data is anonymized by default
- Users can opt-out in app settings
- Data is processed in accordance with GDPR
