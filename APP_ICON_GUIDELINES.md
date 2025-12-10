# App Icon Design Guidelines for Nestling

## Design Brief

- **Style:** Clean, modern, calming
- **Colors:** Primary blue (#3b82f6) or purple (#8b5cf6)
- **Concept:** Baby bottle, moon, or abstract baby symbol
- **Mood:** Trustworthy, friendly, sleep-friendly

## Technical Requirements

- **Size:** 1024×1024 pixels
- **Format:** PNG (no transparency)
- **Color space:** sRGB
- **No text in icon** (works globally)
- **Simple at small sizes** (recognizable at 60×60)

## Design Options

### Option 1: Baby Bottle

- Simple bottle silhouette
- Gradient blue/purple
- Clean lines, modern style

### Option 2: Moon with Star

- Crescent moon
- Small star
- Represents sleep tracking

### Option 3: Abstract Baby

- Minimalist baby face outline
- Friendly, not too cute
- Professional yet warm

## Color Palette

- Primary: #3b82f6 (blue)
- Secondary: #8b5cf6 (purple)
- Accent: #ec4899 (pink)
- Background: White or light gradient

## How to Create

### Using Figma:

1. Create 1024×1024 artboard
2. Design icon centered
3. Export as PNG (2x quality)
4. Test at various sizes (60×60, 120×120)

### Using Canva:

1. Custom size: 1024×1024
2. Use shape tools for bottle/moon
3. Add gradient overlay
4. Download as PNG

### Using AppIcon.co:

1. Upload your 1024×1024 PNG
2. Generates all iOS/Android sizes
3. Download zip
4. Place in project

## File Naming

- `icon-1024.png` (App Store listing)
- `apple-touch-icon.png` (180×180 for iOS)
- `favicon.ico` (16×16, 32×32 for web)

## Testing

- [ ] View at 60×60 (home screen size)
- [ ] View at 120×120 (retina)
- [ ] Test in light mode
- [ ] Test in dark mode
- [ ] Check against similar apps

## Implementation

Once designed, place files in:

- `public/icon-1024.png` - App Store asset
- `public/apple-touch-icon.png` - iOS home screen
- `public/favicon.ico` - Web browser
