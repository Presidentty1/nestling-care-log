# ⚠️ Fix Code Signing Error

## The Problem
Build is failing with: **"Signing for 'App' requires a development team"**

## Quick Fix (2 Steps)

### Step 1: Add Your Apple ID to Xcode (if not already added)
1. Open **Xcode** → **Settings** (or **Preferences** on older versions)
2. Click the **"Accounts"** tab
3. Click the **"+"** button at bottom left
4. Select **"Apple ID"**
5. Sign in with your Apple ID (the same one you use for iCloud/App Store)
6. Click **"Sign In"**

### Step 2: Select Your Team in the Project
1. In Xcode, click the **blue "App" project icon** in the left sidebar (at the very top)
2. Under **TARGETS**, select **"App"**
3. Click the **"Signing & Capabilities"** tab
4. Check the box: **"Automatically manage signing"**
5. Under **"Team"**, click the dropdown and select your Apple ID/name
   - It will show something like: "Your Name (Personal Team)" or "Your Name (Team ID)"
6. Xcode will automatically:
   - Generate a provisioning profile
   - Set up code signing
   - Fix the build error

### Step 3: Build Again
- Select your iPhone from the device dropdown
- Press **Cmd+R** to build and run

## Important Notes
- ✅ **Free Apple ID works** - You don't need a paid developer account ($99/year) to test on your own device
- ✅ **Personal Team** - Xcode will create a "Personal Team" for free accounts
- ⚠️ **Bundle ID** - If you get a bundle ID conflict, Xcode will suggest changing it automatically

## If You Still See Errors
- Make sure your iPhone is **unlocked** and **trusted** (Settings → General → VPN & Device Management)
- Try **Product → Clean Build Folder** (Shift+Cmd+K) then build again
- Restart Xcode if the team doesn't appear in the dropdown
