# ⚠️ Manual Setup Required

Some files in the project are read-only and require manual updates. Complete these steps after the automated migration:

## 1. Update package.json Scripts

Add these scripts to the `scripts` section in `package.json`:

```json
{
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "build:dev": "vite build --mode development",
    "lint": "eslint .",
    "preview": "vite preview",
    
    // ADD THESE NEW SCRIPTS:
    "cap:sync": "npm run build && npx cap sync",
    "cap:ios": "npm run cap:sync && npx cap open ios",
    "cap:android": "npm run cap:sync && npx cap open android",
    "cap:run:ios": "npm run build && npx cap sync && npx cap run ios",
    "cap:run:android": "npm run build && npx cap sync && npx cap run android",
    "test": "vitest",
    "test:ui": "vitest --ui",
    "test:coverage": "vitest --coverage",
    "test:e2e": "playwright test",
    "test:e2e:ui": "playwright test --ui",
    "test:e2e:debug": "playwright test --debug",
    "test:ios": "npm run cap:sync && xcodebuild test -workspace ios/App/App.xcworkspace -scheme App -destination 'platform=iOS Simulator,name=iPhone 15'"
  }
}
```

## 2. Update .gitignore

Add these lines to `.gitignore`:

```gitignore
# Capacitor
ios/App/Podfile.lock
ios/App/Pods/
android/app/build/
android/.gradle/
.DS_Store

# Keep .vscode folder but ignore settings
!.vscode/settings.json
!.vscode/extensions.json
```

## 3. Initialize Capacitor

Run these commands in your terminal:

```bash
# Initialize Capacitor (one time only)
npx cap init

# When prompted, use these values:
# App Name: Nestling
# App ID: app.lovable.3be850d6430e4062887da465d2abf643
# Web Dir: dist
```

The `capacitor.config.ts` file has already been created for you with the correct configuration.

## 4. Add iOS Platform (macOS only)

```bash
# Build web assets
npm run build

# Add iOS platform
npx cap add ios

# Open in Xcode
npx cap open ios
```

## 5. Configure iOS Permissions (macOS only)

After running `npx cap add ios`, edit `ios/App/App/Info.plist` and add these permissions before the closing `</dict>` tag:

```xml
<!-- Microphone for cry analysis -->
<key>NSMicrophoneUsageDescription</key>
<string>Nestling needs microphone access to analyze your baby's cry patterns and provide insights.</string>

<!-- Photo Library -->
<key>NSPhotoLibraryUsageDescription</key>
<string>Nestling can save baby milestone photos to your library.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Nestling needs permission to save photos to your library.</string>

<!-- Notifications -->
<key>UIBackgroundModes</key>
<array>
  <string>remote-notification</string>
</array>

<!-- Dark mode support -->
<key>UIUserInterfaceStyle</key>
<string>Automatic</string>

<!-- Safe area insets -->
<key>UIViewControllerBasedStatusBarAppearance</key>
<true/>
```

## 6. Set iOS Deployment Target (macOS only)

Edit `ios/App/Podfile` and ensure it has:

```ruby
platform :ios, '14.0'
```

Then run:

```bash
cd ios/App
pod install
cd ../..
```

## 7. Add Android Platform (Optional)

```bash
# Build web assets
npm run build

# Add Android platform
npx cap add android

# Open in Android Studio
npx cap open android
```

## 8. Verify Installation

Run this checklist:

```bash
# Check dependencies
npm list @capacitor/core @capacitor/ios @capacitor/cli

# Check Capacitor config exists
ls capacitor.config.ts

# Build app
npm run build

# Sync to native platforms
npx cap sync

# (macOS only) Open in Xcode
npx cap open ios
```

## 9. Test Everything

Follow the complete `TESTING_CHECKLIST.md` to verify all features work.

## 10. Enable Hot Reload (Optional, for development)

For faster iOS development, you can enable hot-reload:

1. Find your local IP address:
   ```bash
   ifconfig | grep "inet " | grep -v 127.0.0.1
   # Example output: 192.168.1.10
   ```

2. Edit `capacitor.config.ts` and uncomment these lines:
   ```typescript
   server: {
     url: 'http://192.168.1.10:5173', // Your IP here
     cleartext: true
   }
   ```

3. Run `npm run dev` on your computer
4. In Xcode, run on simulator/device
5. App will load from your dev server with instant updates!

## Troubleshooting

### "Command not found: cap"
Install Capacitor CLI globally:
```bash
npm install -g @capacitor/cli
```

### iOS build fails
```bash
cd ios/App
pod install
cd ../..
npx cap sync ios
```

### Permission denied errors
```bash
sudo xcode-select --reset
sudo xcodebuild -license accept
```

### Type errors in Cursor
```bash
npx supabase gen types typescript --project-id tzvkwhznmkzfpenzxbfz > src/integrations/supabase/types.ts
```

## Next Steps

After completing these manual steps:
1. Read `DEVELOPMENT.md` for development workflow
2. Read `DEPLOYMENT.md` for deployment instructions
3. Follow `MIGRATION_CHECKLIST.md` for complete migration
4. Use `TESTING_CHECKLIST.md` to verify everything works
