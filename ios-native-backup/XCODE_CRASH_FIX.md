# Xcode Crash Fix Guide

If Xcode keeps crashing unexpectedly when opening this project, follow these steps:

## Quick Fix

Run the automated fix script:

```bash
cd ios
bash scripts/fix_xcode_crashes.sh
```

Then:
1. **Quit Xcode completely** (Cmd+Q, don't just close windows)
2. Wait 10 seconds
3. Reopen the project: `open Nestling/Nestling.xcodeproj`

## Common Causes

### 1. Corrupted Derived Data
Xcode stores build artifacts in DerivedData. If corrupted, it can cause crashes.

**Fix:**
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```

### 2. Corrupted Module Cache
Swift module cache can become corrupted.

**Fix:**
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex
```

### 3. Corrupted Xcode Caches
Xcode's internal caches can cause issues.

**Fix:**
```bash
rm -rf ~/Library/Caches/com.apple.dt.Xcode/*
```

### 4. Project-Specific Build Files
Sometimes project build folders get corrupted.

**Fix:**
```bash
cd ios/Nestling
rm -rf build/ .build/
find . -name "*.xcuserstate" -delete
```

### 5. PBXFileSystemSynchronizedRootGroup Issues
This project uses the modern `PBXFileSystemSynchronizedRootGroup` feature (objectVersion 77). While this is the recommended format, some Xcode versions have bugs with it.

**If crashes persist after cleaning:**
- Update Xcode to the latest version
- Check Console.app for crash logs
- Consider reporting the issue to Apple if it's a known bug

## Manual Steps

If the script doesn't work, try these in order:

### Step 1: Clean Everything
```bash
# Derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Module cache
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex

# Xcode caches
rm -rf ~/Library/Caches/com.apple.dt.Xcode/*

# Project build folders
cd ios/Nestling
rm -rf build/ .build/
find . -name "*.xcuserstate" -delete
```

### Step 2: Verify Project Structure
Ensure these directories exist:
- `ios/Nestling/Nestling/` (source files)
- `ios/Nestling/NestlingTests/` (test files)
- `ios/Nestling/NestlingUITests/` (UI test files)

### Step 3: Check File Permissions
```bash
cd ios/Nestling
find . -type f -name "*.swift" -exec chmod 644 {} \;
find . -type d -exec chmod 755 {} \;
```

### Step 4: Reset Xcode Preferences (Last Resort)
⚠️ **Warning:** This will reset ALL Xcode preferences

```bash
defaults delete com.apple.dt.Xcode
```

Then restart your Mac.

## Prevention

To prevent future crashes:

1. **Keep Xcode Updated**: Always use the latest stable version
2. **Clean Regularly**: Run the fix script monthly or when you notice slowdowns
3. **Don't Force Quit**: Always quit Xcode properly (Cmd+Q)
4. **Check Console**: If crashes persist, check Console.app for error messages

## Still Crashing?

If crashes continue after trying everything:

1. **Check Console.app** for crash logs:
   - Open Console.app
   - Search for "Xcode" and "crash"
   - Look for error messages

2. **Check Xcode Version**:
   ```bash
   xcodebuild -version
   ```
   Ensure you're using Xcode 15.0 or later (required for objectVersion 77)

3. **Report to Apple**: If it's a reproducible bug, report it via Feedback Assistant

4. **Temporary Workaround**: If needed, you can downgrade the project format:
   - Open project in Xcode
   - File → Project Settings
   - Change "Project Format" to "Xcode 14.0-compatible"
   - Note: This will convert PBXFileSystemSynchronizedRootGroup to traditional file references

## Project Format

This project uses:
- **Object Version**: 77 (Xcode 15+)
- **File System Synchronized Groups**: Yes (modern format)
- **Swift Version**: 5.0
- **iOS Deployment Target**: 17.0

These are all correct and modern settings. Crashes are usually due to corrupted caches, not the project format itself.

