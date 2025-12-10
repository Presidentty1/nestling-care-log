# How to See the UX Changes

## The changes ARE in the code, but you need to rebuild!

All the code changes were successfully saved, but you need to rebuild the app to see them on your device/simulator.

## Quick Rebuild Steps

### Option 1: Full Clean Rebuild (Recommended)

```bash
# 1. Clean and rebuild the web assets
npm run build

# 2. Sync with Capacitor
npx cap sync ios

# 3. Open in Xcode and rebuild
npx cap open ios
```

Then in Xcode:

1. Product → Clean Build Folder (Shift + Cmd + K)
2. Product → Build (Cmd + B)
3. Run on simulator/device

### Option 2: Quick Rebuild

```bash
# Just rebuild and sync
npm run build && npx cap sync ios && npx cap open ios
```

## What Changed (You'll See After Rebuild)

### Onboarding Screen

- ✅ Input fields are **taller** (h-16 = 64pt instead of 56pt)
- ✅ Labels are **bolder** (font-semibold)
- ✅ Inputs have **2px borders** (more visible)
- ✅ Calendar button is **larger** (64x64pt)
- ✅ Better spacing overall
- ✅ "Just Born Today" button text (was "Set to Today")
- ✅ Unit selection cards are bigger with better touch targets

### History Screen

- ✅ Day selector buttons are **larger** (68x72pt)
- ✅ Better spacing between days
- ✅ Improved visual states

### General

- ✅ No horizontal scrolling
- ✅ Safe area insets for notch/home indicator
- ✅ Better text contrast in dark mode

## Troubleshooting

If you still don't see changes after rebuild:

### Clear All Caches

```bash
# Clear npm cache
rm -rf node_modules
npm install

# Clear Capacitor cache
rm -rf dist
npm run build

# Clear iOS build
rm -rf ios/App/build
rm -rf ios/App/DerivedData
```

### Then rebuild from scratch

```bash
npm run build
npx cap sync ios
npx cap open ios
```

In Xcode:

- Product → Clean Build Folder
- Delete app from simulator/device
- Rebuild and run

## Verify Changes in Code

You can verify the changes are in the code:

```bash
# Check onboarding changes
grep "h-16" src/pages/Onboarding.tsx

# Check permissions
grep "NSSpeechRecognition" legacy-capacitor-shell/App/App/Info.plist

# Check safe area CSS
grep "safe-area-inset" src/index.css
```

All should show results if changes are saved.

## Quick Test After Rebuild

1. **Onboarding**: Input fields should be noticeably taller
2. **History**: Day buttons should be larger and more touch-friendly
3. **Home**: No horizontal scroll, proper safe areas
4. **Dark mode**: Better text contrast

---

**Note**: The code changes ARE there, you just need to rebuild the iOS app to see them!
