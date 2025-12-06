# 🔧 CRITICAL: Force Fresh Install of Updated App

## The Problem
Your device/simulator is running an **OLD binary** from before the UX changes. Even though you rebuilt, iOS cached the old app.

## The Solution: Complete App Reset

### Step 1: Delete App from Device/Simulator
1. **On Simulator**: Long press the Nuzzle app icon → Delete App
2. **On Physical Device**: Long press app → Remove App → Delete App

### Step 2: Clean Everything in Xcode
1. **Product → Clean Build Folder** (⇧⌘K)
2. Close Xcode completely
3. Delete Derived Data:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/Nestling-*
   ```
4. Reopen Xcode

### Step 3: Build & Install Fresh
1. **Product → Build** (⌘B) - Wait for success
2. **Product → Run** (⌘R) - This installs a fresh copy

## What You Should See After Fresh Install

### Onboarding (4 Steps, Not 9!)
- **Step 1**: Welcome screen
- **Step 2**: "Tell us about your baby" - ALL fields in ONE screen:
  - Baby's name (NO LAG - uses local state)
  - Birthday picker
  - Gender selector
  - Initial state (asleep/awake buttons)
- **Step 3**: Preferences (units + AI consent combined)
- **Step 4**: "You're all set!" celebration

### Home Screen
- **Next Nap** is HUGE hero card (28pt text)
- **Last Feed** and **Last Diaper** are smaller satellite cards
- Streak counter is prominent with large flame

### History
- Selected day uses **border** (not solid fill)
- Timeline has **6px colored left bar** (was 3px)

## If Still Not Working

Check in Xcode → Product → Scheme → Edit Scheme → Run → Build Configuration is "Debug"

The files ARE correct - you just need to delete the old app completely!

