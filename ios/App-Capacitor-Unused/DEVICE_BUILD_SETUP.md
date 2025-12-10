# Building on Your iPhone - Setup Guide

## Quick Setup (2 minutes)

To build on your physical iPhone, you need to set up code signing:

### Step 1: Connect Your iPhone

1. Connect your iPhone to your Mac via USB
2. Unlock your iPhone
3. Tap "Trust This Computer" if prompted

### Step 2: Set Your Development Team in Xcode

1. In Xcode, click on the **"App"** project (blue icon) in the left sidebar
2. Select the **"App"** target (under TARGETS)
3. Click the **"Signing & Capabilities"** tab
4. Check **"Automatically manage signing"**
5. Under **"Team"**, select your Apple ID:
   - If you see "Add an Account...", click it and sign in with your Apple ID
   - If you already have an account, select it from the dropdown
6. Xcode will automatically:
   - Create a provisioning profile
   - Set your development team
   - Configure code signing

### Step 3: Select Your iPhone

1. At the top of Xcode, click the device selector (next to the scheme)
2. Select your iPhone from the list (it should show "Ty's iPhone 17 Pro" or similar)

### Step 4: Build and Run

1. Press **Cmd+R** to build and run
2. On your iPhone, you may need to:
   - Go to Settings → General → VPN & Device Management
   - Trust your developer certificate
   - Then run the app again

## Notes

- **Free Apple ID**: You can use a free Apple ID for development (no $99/year needed for testing on your own device)
- **Bundle ID**: The app uses `com.lovable.nestlingcarelog` - if you get a conflict, Xcode will suggest a unique one
- **First Time**: The first build may take longer as Xcode sets up certificates

## Troubleshooting

- **"No signing certificate"**: Make sure you're signed into Xcode with your Apple ID (Xcode → Settings → Accounts)
- **"Device not trusted"**: Trust the computer on your iPhone, and trust the developer certificate in iPhone Settings
- **"Provisioning profile error"**: Let Xcode automatically manage signing - it will fix this
