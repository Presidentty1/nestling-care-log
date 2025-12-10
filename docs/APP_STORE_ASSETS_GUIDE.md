# App Store Assets Guide

## Required Assets

### 1. App Icon

**Specifications:**
- **Size**: 1024×1024 pixels
- **Format**: PNG (no alpha channel, no transparency)
- **Color Space**: RGB
- **File Name**: `AppIcon-1024.png`

**Requirements:**
- Must be sharp at all sizes
- No rounded corners (iOS adds them automatically)
- No text or UI elements
- Matches "Nuzzle" branding
- Professional, polished design

**Design Tips:**
- Use simple, recognizable icon
- Test at small sizes (appears at 60×60 on home screen)
- Ensure good contrast
- Avoid fine details

### 2. Screenshots

**Required Sizes:**

#### iPhone 6.5" Display (iPhone 14 Pro Max / 15 Pro Max)
- **Size**: 1290×2796 pixels
- **Required**: Minimum 5 screenshots
- **Recommended Order**:
  1. Home screen (timeline, quick actions)
  2. Event logging (feed form)
  3. History view (day-by-day navigation)
  4. Nap predictor (AI prediction card)
  5. AI assistant (chat interface)
  6. Settings (optional)

#### iPhone 5.5" Display (iPhone 8 Plus)
- **Size**: 1242×2208 pixels
- **Required**: Minimum 5 screenshots
- **Same order as above**

#### iPad Pro 12.9" (if iPad supported)
- **Size**: 2048×2732 pixels
- **Required**: Minimum 5 screenshots
- **Same order as above**

**Screenshot Guidelines:**
- Show real app content (not mockups)
- Use actual user data (anonymized)
- Highlight key features
- Include text overlays with feature descriptions (optional)
- Ensure good lighting and contrast
- No device frames needed (iOS adds them)

**Content to Show:**
1. **Home Screen**: Timeline with events, quick actions, nap prediction
2. **Event Logging**: Feed form with amount, timer, notes
3. **History**: Date picker, filtered events, summary
4. **Nap Predictor**: Prediction card with time and reasoning
5. **AI Assistant**: Chat interface with question/answer
6. **Settings**: Baby management, account settings

### 3. App Preview Video (Optional but Recommended)

**Specifications:**
- **Duration**: 15-30 seconds
- **Format**: MP4 or MOV
- **Resolution**: Match screenshot sizes
- **Content**: Show key features in action

**Recommended Flow:**
1. Open app → Home screen (2s)
2. Tap quick action → Log feed (3s)
3. View timeline → Event appears (2s)
4. Navigate to history → Day picker (2s)
5. Show nap prediction → AI feature (3s)
6. End with app icon/branding (2s)

## Creating Assets

### Screenshot Capture

**Using iOS Simulator:**
1. Open app in simulator
2. Navigate to screen
3. Device → Screenshot (Cmd+S)
4. Screenshot saved to Desktop
5. Edit in image editor if needed

**Using Physical Device:**
1. Use QuickTime Player (Mac)
2. File → New Movie Recording
3. Select device
4. Record screen
5. Export frames as screenshots

**Using Xcode:**
1. Run app on simulator
2. Debug → View Debugging → Screenshot
3. Save screenshot

### Image Editing

**Tools:**
- **Figma**: Design screenshots with overlays
- **Sketch**: Professional design tool
- **Photoshop**: Advanced editing
- **Preview (Mac)**: Basic editing

**Tips:**
- Add text overlays to highlight features
- Ensure consistent styling
- Use app's color scheme
- Keep file sizes reasonable (<5MB per screenshot)

## App Store Connect Upload

### Steps

1. **Log in to App Store Connect**
   - https://appstoreconnect.apple.com
   - Navigate to your app

2. **App Store Tab**
   - Select version
   - Scroll to "App Screenshots"

3. **Upload Screenshots**
   - Drag and drop or click to upload
   - Upload for each device size
   - Preview before saving

4. **App Icon**
   - App Information → App Icon
   - Upload 1024×1024 PNG
   - Preview before saving

5. **App Preview Video**
   - Optional section
   - Upload video file
   - Add preview image

## Checklist

### Before Upload
- [ ] App icon created (1024×1024)
- [ ] Screenshots captured for all required sizes
- [ ] Screenshots show real app content
- [ ] Text overlays added (if desired)
- [ ] Images optimized (reasonable file sizes)
- [ ] All assets match "Nuzzle" branding

### App Store Connect
- [ ] App icon uploaded
- [ ] Screenshots uploaded for iPhone 6.5"
- [ ] Screenshots uploaded for iPhone 5.5"
- [ ] Screenshots uploaded for iPad (if supported)
- [ ] App preview video uploaded (optional)
- [ ] All assets preview correctly

## Resources

- [App Store Screenshot Specifications](https://developer.apple.com/app-store/product-page/)
- [App Icon Guidelines](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- [App Preview Guidelines](https://developer.apple.com/app-store/app-previews/)

## Quick Reference

| Asset | Size | Format | Required |
|-------|------|--------|----------|
| App Icon | 1024×1024 | PNG | Yes |
| iPhone 6.5" Screenshots | 1290×2796 | PNG/JPG | 5+ |
| iPhone 5.5" Screenshots | 1242×2208 | PNG/JPG | 5+ |
| iPad Screenshots | 2048×2732 | PNG/JPG | 5+ (if supported) |
| App Preview Video | Match screenshot | MP4/MOV | Optional |











