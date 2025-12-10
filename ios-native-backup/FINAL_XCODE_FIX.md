# Final Xcode Crash Fix Guide

If Xcode is still crashing after running the rebuild script, follow these steps in order:

## Step 1: Fix xcode-select (CRITICAL)

Your system is pointing to Command Line Tools instead of Xcode. This MUST be fixed first:

```bash
cd ios
bash scripts/fix_xcode_select.sh
```

This will require your password (sudo access).

## Step 2: Run Aggressive Cleanup

```bash
cd ios
bash scripts/aggressive_xcode_fix.sh
```

## Step 3: Restart Your Mac

**This is important** - many Xcode issues require a full restart to clear system-level caches.

## Step 4: Check Console.app for Crash Logs

1. Open **Console.app** (Applications → Utilities → Console)
2. In the search box, type: `Xcode crash`
3. Look for recent crash reports
4. Check the error messages - they will tell you exactly what's wrong

Common error patterns:

- **"PBXFileSystemSynchronizedRootGroup"** → Issue with modern project format
- **"Cannot read file"** → Corrupted or missing source file
- **"Memory"** → System resource issue
- **"Plugin"** → Corrupted Xcode plugin

## Step 5: Test Xcode Itself

Before opening your project, test if Xcode works at all:

1. Open Xcode
2. File → New → Project
3. Create a simple iOS App
4. Try to build it

If Xcode crashes on a simple new project, the issue is with Xcode itself, not your project.

## Step 6: If Still Crashing - Convert Project Format

The project uses `PBXFileSystemSynchronizedRootGroup` which can cause crashes in some Xcode versions. To convert to traditional file references:

### Option A: Use Xcode (Recommended)

1. Open the project in Xcode (if possible)
2. File → Project Settings
3. Change "Project Format" from "Xcode 15.0-compatible" to "Xcode 14.0-compatible"
4. Xcode will convert the project format
5. Change it back to "Xcode 15.0-compatible" if desired

### Option B: Manual Conversion (Advanced)

This requires manually editing the project file - not recommended unless you're comfortable with it.

## Step 7: Check Xcode Version Compatibility

Your project requires:

- **Xcode 15.0+** (for objectVersion 77)
- **macOS Sonoma+** (for iOS 17 SDK)

Check your Xcode version:

```bash
xcodebuild -version
```

If you have an older version, update Xcode from the App Store.

## Step 8: Nuclear Option - Reset Everything

If nothing else works:

```bash
# Reset Xcode preferences
defaults delete com.apple.dt.Xcode

# Remove all Xcode data
rm -rf ~/Library/Developer/Xcode/*
rm -rf ~/Library/Caches/com.apple.dt.Xcode/*
rm -rf ~/Library/Preferences/com.apple.dt.Xcode.plist

# Restart Mac
sudo reboot
```

Then reinstall Xcode from the App Store.

## Getting Help

If crashes persist after all these steps:

1. **Check Console.app** for the exact error message
2. **Take a screenshot** of the error
3. **Note when it crashes** (on open, when building, when browsing files, etc.)
4. **Check Apple Developer Forums** for similar issues
5. **Report to Apple** via Feedback Assistant if it's a bug

## Quick Reference

```bash
# Fix xcode-select
cd ios && bash scripts/fix_xcode_select.sh

# Aggressive cleanup
cd ios && bash scripts/aggressive_xcode_fix.sh

# Diagnose issues
cd ios && bash scripts/diagnose_xcode_crash.sh

# Standard cleanup
cd ios && bash scripts/fix_xcode_crashes.sh
```
