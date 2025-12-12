# App Not Installing on iPhone - Troubleshooting Guide

## Quick Checks

### 1. Check Xcode Build Output

After running the app, look at the Xcode console for any errors like:

- ❌ Code signing errors
- ❌ Provisioning profile errors
- ❌ "Unable to install"
- ❌ "App installation failed"

### 2. Check Your Apple Developer Account Type

**Free Account (Personal Team)**:

- Team name looks like: "Your Name (Personal Team)"
- **Limitations**:
  - Apps expire after 7 days
  - Maximum 3 apps on device at once
  - Apps must be re-signed weekly
  - Can be uninstalled automatically

**Paid Developer Account**:

- Team name is your organization or "Your Name"
- Team ID: 9BS3VKTM6N (this is what you have)
- Apps don't expire
- Unlimited apps

### 3. Device Preparation Checklist

On your iPhone:

1. Go to **Settings → General → VPN & Device Management**
2. Look for your developer certificate
3. If you see "Untrusted Developer", tap it and click "Trust"

### 4. Xcode Run Settings

In Xcode:

1. Select your iPhone from device menu
2. **Product → Scheme → Edit Scheme**
3. Click **Run** in left sidebar
4. Under **Info** tab:
   - Build Configuration: **Debug**
   - Executable: **Nuzzle.app**
5. Under **Options** tab:
   - Check "Install Application" is enabled
   - GPU Frame Capture: **Automatic**

## Step-by-Step Fix

### Option 1: Clean Install

```bash
# 1. Clean build folder
cd "/Users/tyhorton/Coding Projects/nestling-care-log/ios/Nuzzle"
rm -rf ~/Library/Developer/Xcode/DerivedData/

# 2. In Xcode: Product → Clean Build Folder (⇧⌘K)
# 3. Delete app from iPhone if it exists
# 4. Build and Run (⌘R)
```

### Option 2: Manual Installation Method

If automatic installation fails:

1. **Archive the app**:
   - In Xcode: **Product → Archive**
   - Wait for archive to complete
2. **Export for Development**:
   - Window → Organizer
   - Select your archive
   - Click "Distribute App"
   - Choose "Development"
   - Check "Install on device"
   - Select your iPhone
   - Click "Export"

3. **Drag and drop IPA**:
   - You can also drag the .app bundle to your device via Xcode Devices window

### Option 3: Check Device Limit (Free Account)

If using free account:

1. Delete old test apps from your iPhone
2. Free accounts limited to 3 apps max
3. Settings → General → iPhone Storage
4. Delete apps you don't need

## Common Issues

### Issue: "App not found after closing"

**Cause**: Free developer account apps expire or hit 3-app limit
**Solution**:

- Use paid developer account for persistent apps
- Or re-run from Xcode every 7 days

### Issue: "Could not launch app"

**Cause**: Code signing / provisioning error
**Solution**:

1. Xcode → Preferences → Accounts
2. Download manual profiles
3. Select your team in target settings
4. "Automatically manage signing" ✓

### Issue: "App Installed but No Icon"

**Cause**: SpringBoard cache issue
**Solution**:

```bash
# Restart iPhone or reset home screen layout
# Settings → General → Transfer or Reset iPhone → Reset Home Screen Layout
```

## Verify Installation

After running from Xcode:

1. ✅ App launches successfully
2. ✅ Disconnect iPhone from Mac
3. ✅ Force close the app
4. ✅ Check home screen for "Nuzzle" icon
5. ✅ Tap icon - app should launch

If icon appears: **Success!** 🎉
If icon disappears: **Free account limitation** or installation failed

## Your Current Settings

- Bundle ID: `com.nestling.app.dev`
- Team ID: `9BS3VKTM6N`
- Code Sign: Automatic
- Scheme: Fixed with `launchAutomaticallySubstyle = "2"`

## Next Steps

Try these in order:

1. ☐ Clean build + delete app from phone + rebuild
2. ☐ Check Settings → VPN & Device Management on iPhone
3. ☐ Try manual installation via Archive
4. ☐ Check if you have 3+ apps already (free account)
5. ☐ If all else fails, check Xcode console for specific error

## Still Not Working?

Share the error from Xcode console after you try to run the app.
