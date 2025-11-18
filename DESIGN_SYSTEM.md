# Nestling Design System

A comprehensive design system for the Nestling baby tracking app, optimized for mobile-first experiences with iOS-quality design patterns.

## Design Philosophy

- **Mobile-First**: All components optimized for thumb-friendly interaction (44pt minimum tap targets)
- **iOS-Inspired**: Clean, modern aesthetic with familiar iOS patterns
- **Accessibility**: High contrast, clear hierarchy, readable typography
- **Consistency**: Single source of truth for all design tokens

---

## Color Tokens

### Brand Colors

#### Light Mode
```css
--primary: hsl(168, 46%, 34%)          /* #2E7D6A - Calming teal for actions */
--primary-foreground: hsl(0, 0%, 100%) /* White text on primary */
--primary-600: hsl(168, 50%, 29%)      /* #256E5E - Darker teal for pressed states */
--primary-100: hsl(168, 57%, 90%)      /* #D8EFE9 - Light teal for subtle backgrounds */
```

#### Dark Mode
```css
--primary: hsl(168, 36%, 64%)          /* #82C6B6 - Lighter teal for dark backgrounds */
--primary-foreground: hsl(0, 0%, 100%) /* White text on primary */
--primary-600: hsl(168, 35%, 58%)      /* #73B5A5 - Darker variant */
--primary-100: hsl(168, 26%, 21%)      /* #24413A - Dark teal background */
```

### Semantic Colors

#### Light Mode
```css
--success: hsl(168, 46%, 34%)          /* Matches primary - positive actions */
--warning: hsl(38, 96%, 55%)           /* #F5A623 - Caution/attention */
--destructive: hsl(0, 64%, 55%)        /* #D64545 - Errors/delete actions */
--secondary: hsl(235, 100%, 70%)       /* #6A7DFF - Links & highlights */
--info: hsl(207, 90%, 54%)             /* #2196F3 - Informational messages */
```

#### Dark Mode
```css
--success: hsl(168, 36%, 64%)          /* Matches primary */
--warning: hsl(39, 100%, 70%)          /* #FFC266 - Lighter for dark backgrounds */
--destructive: hsl(0, 100%, 75%)       /* #FF7D7D - Lighter for dark backgrounds */
--secondary: hsl(235, 100%, 81%)       /* #9AA6FF - Lighter indigo */
--info: hsl(207, 89%, 70%)             /* #64B5F6 - Lighter for dark backgrounds */
```

### Event-Specific Colors

Used for color-coding different types of baby tracking events to improve scannability and visual hierarchy.

#### Light Mode
```css
--event-feed: hsl(199, 89%, 48%)       /* #0BA5EC - Soft blue (nurturing, milk) */
--event-sleep: hsl(250, 70%, 60%)      /* #8B5CF6 - Purple (rest, night) */
--event-diaper: hsl(25, 95%, 53%)      /* #FB923C - Warm orange (attention) */
--event-tummy: hsl(142, 71%, 45%)      /* #10B981 - Green (growth, activity) */
--event-medication: hsl(0, 84%, 60%)   /* #EF4444 - Red (medical attention) */
```

#### Dark Mode
```css
--event-feed: hsl(199, 89%, 65%)       /* #52B5F5 - Lighter blue */
--event-sleep: hsl(250, 70%, 75%)      /* #A78BFA - Lighter purple */
--event-diaper: hsl(25, 95%, 65%)      /* #FDBA74 - Lighter orange */
--event-tummy: hsl(142, 71%, 60%)      /* #34D399 - Lighter green */
--event-medication: hsl(0, 84%, 75%)   /* #FCA5A5 - Lighter red */
```

#### Usage Guidelines
- **Icons**: Use event colors for icons in timeline rows, quick actions, and summary chips
- **Backgrounds**: Apply as subtle tints (`bg-event-{type}/5` or `/10`) for visual grouping
- **Borders**: Use with 20% opacity (`border-event-{type}/20`) for card accents
- **Text**: Avoid using event colors for body text; reserve for icons and accents only
- **Consistency**: Always pair color with icons/labels (never rely on color alone for meaning)

#### iOS/SwiftUI Mapping
```swift
extension Color {
    static let eventFeed = Color("EventFeed")           // Blue
    static let eventSleep = Color("EventSleep")         // Purple
    static let eventDiaper = Color("EventDiaper")       // Orange
    static let eventTummy = Color("EventTummy")         // Green
    static let eventMedication = Color("EventMedication") // Red
}
```

### Background Layers

#### Light Mode
```css
--background: hsl(210, 17%, 98%)       /* #F8FAFB - Main app background */
--surface: hsl(0, 0%, 100%)            /* #FFFFFF - Cards, sheets */
--elevated: hsl(0, 0%, 100%)           /* #FFFFFF - Elevated cards */
```

#### Dark Mode
```css
--background: hsl(210, 31%, 9%)        /* #0F1417 - Main app background */
--surface: hsl(204, 20%, 12%)          /* #141A1E - Cards, sheets */
--elevated: hsl(202, 17%, 14%)         /* #182127 - Elevated cards */
```

### Text Hierarchy

#### Light Mode
```css
--foreground: hsl(199, 62%, 8%)        /* #0D1B1E - Primary text */
--muted-foreground: hsl(199, 19%, 62%) /* #8FA1A8 - Secondary text */
--text-subtle: hsl(199, 17%, 28%)      /* #415058 - Tertiary text */
```

#### Dark Mode
```css
--foreground: hsl(190, 25%, 93%)       /* #EAF0F2 - Primary text */
--muted-foreground: hsl(197, 12%, 58%) /* #86969E - Secondary text */
--text-subtle: hsl(195, 15%, 75%)      /* #B8C5CB - Tertiary text */
```

### UI Elements

```css
--border: Light: hsl(202, 25%, 91%) | Dark: hsl(204, 22%, 19%)
--input: Matches border color
--ring: Matches primary color (for focus states)
```

---

## Border Radius Scale

```css
--radius-xs: 0.5rem   /* 8px  - Small elements, icons */
--radius-sm: 0.75rem  /* 12px - Chips, pills, badges */
--radius: 0.875rem    /* 14px - Buttons (default) */
--radius-md: 1rem     /* 16px - Cards */
--radius-lg: 1.25rem  /* 20px - Sheets, drawers */
--radius-xl: 1.5rem   /* 24px - Modals */
```

### Tailwind Classes
- `rounded-xs` → 8px
- `rounded-sm` → 12px
- `rounded` → 14px (buttons)
- `rounded-md` → 16px (cards)
- `rounded-lg` → 20px (sheets)
- `rounded-xl` → 24px (modals)

---

## Spacing Scale

```css
--spacing-xs: 0.25rem  /* 4px  - Tight spacing */
--spacing-sm: 0.5rem   /* 8px  - Small gaps */
--spacing-md: 1rem     /* 16px - Default spacing */
--spacing-lg: 1.5rem   /* 24px - Large gaps */
--spacing-xl: 2rem     /* 32px - Section spacing */
--spacing-2xl: 3rem    /* 48px - Major sections */
```

### Tailwind Classes
- `space-xs` / `gap-xs` / `p-xs` → 4px
- `space-sm` / `gap-sm` / `p-sm` → 8px
- `space-md` / `gap-md` / `p-md` → 16px
- `space-lg` / `gap-lg` / `p-lg` → 24px
- `space-xl` / `gap-xl` / `p-xl` → 32px
- `space-2xl` / `gap-2xl` / `p-2xl` → 48px

---

## Shadow Scale

### Light Mode
```css
--shadow-sm: 0 1px 2px rgba(13, 27, 30, 0.04)   /* Subtle depth */
--shadow-md: 0 4px 12px rgba(13, 27, 30, 0.08)  /* Floating elements */
--shadow-lg: 0 8px 24px rgba(13, 27, 30, 0.12)  /* Elevated cards */
--shadow-xl: 0 12px 32px rgba(13, 27, 30, 0.16) /* Modals, sheets */
--shadow-soft: 0 6px 24px rgba(13, 27, 30, 0.06) /* Gentle elevation */
```

### Dark Mode
```css
--shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.2)
--shadow-md: 0 4px 12px rgba(0, 0, 0, 0.3)
--shadow-lg: 0 8px 24px rgba(0, 0, 0, 0.4)
--shadow-xl: 0 12px 32px rgba(0, 0, 0, 0.5)
--shadow-soft: 0 10px 30px rgba(0, 0, 0, 0.35)
```

### Tailwind Classes
- `shadow-sm` → Subtle depth
- `shadow-md` → Floating elements
- `shadow-lg` → Elevated cards
- `shadow-xl` → Modals
- `shadow-soft` → Gentle elevation

---

## Typography Scale

```typescript
fontSize: {
  'headline': ['22px', { lineHeight: '28px', fontWeight: '700' }],  // Page titles
  'title': ['17px', { lineHeight: '22px', fontWeight: '600' }],     // Section headers
  'body': ['15px', { lineHeight: '20px' }],                         // Body text
  'caption': ['13px', { lineHeight: '18px' }],                      // Captions, metadata
  'label': ['11px', { lineHeight: '13px', fontWeight: '500', letterSpacing: '0.06em' }], // Labels
}
```

### Usage
- `text-headline` → Page titles, main headings
- `text-title` → Section headers, card titles
- `text-body` → Default body text
- `text-caption` → Secondary info, timestamps
- `text-label` → Form labels, small UI text

---

## Components

### Button Variants

```typescript
// Primary - Main actions
<Button variant="default">Save</Button>

// Secondary - Alternative actions
<Button variant="secondary">Cancel</Button>

// Ghost - Subtle actions
<Button variant="ghost">Skip</Button>

// Destructive - Dangerous actions
<Button variant="destructive">Delete</Button>

// Outline - Less emphasis
<Button variant="outline">Learn More</Button>
```

**Sizes**: `sm`, `default`, `lg`, `icon`

### Card Variants

```typescript
// Default - Standard card
<Card variant="default">Content</Card>

// Emphasis - Primary accent (e.g., nap predictions)
<Card variant="emphasis">Important content</Card>

// Success - Positive feedback
<Card variant="success">Achievement unlocked</Card>

// Warning - Attention needed
<Card variant="warning">Check this out</Card>

// Info - Informational content
<Card variant="info">Helpful tip</Card>

// Elevated - Extra shadow
<Card variant="elevated">Elevated content</Card>

// Outline - Stronger border
<Card variant="outline">Outlined content</Card>

// Ghost - No border
<Card variant="ghost">Borderless content</Card>
```

**Usage Guidelines:**
- Use `emphasis` for high-priority information (nap windows, predictions)
- Use `success` for achievements, positive milestones
- Use `warning` for reminders, upcoming deadlines
- Use `info` for tips, contextual help
- Reserve semantic variants (success/warning/info) for meaningful context only

**Key Features**:
- Minimum 44pt tap target on mobile
- Haptic feedback on interaction
- Clear visual hierarchy
- Disabled states with reduced opacity

### Card Variants

```typescript
// Default - Standard card
<Card variant="default">
  <CardHeader>
    <CardTitle>Card Title</CardTitle>
  </CardHeader>
  <CardContent>Content</CardContent>
</Card>

// Emphasis - Highlighted card (e.g., "Next Nap" prediction)
<Card variant="emphasis">
  <CardContent>Important info</CardContent>
</Card>

// Elevated - Card with shadow
<Card variant="elevated">
  <CardContent>Floating content</CardContent>
</Card>

// Outline - Strong border, no fill
<Card variant="outline">
  <CardContent>Outlined content</CardContent>
</Card>

// Ghost - No border or shadow
<Card variant="ghost">
  <CardContent>Minimal card</CardContent>
</Card>
```

**Key Features**:
- Rounded corners (16px)
- Consistent padding
- Support for header, content, footer sections
- Emphasis variant uses primary color accent

### Chip / Pill Component

```typescript
// Status chips
<Chip variant="default">Active</Chip>
<Chip variant="success">Complete</Chip>
<Chip variant="warning">Pending</Chip>
<Chip variant="destructive">Error</Chip>

// Filter chips
<Chip variant="outline">All Events</Chip>
<Chip variant="muted">Archived</Chip>

// Removable chip
<Chip removable onRemove={() => handleRemove()}>
  Tag Name
</Chip>
```

**Sizes**: `sm`, `md` (default), `lg`

**Key Features**:
- Rounded corners (12px)
- Color-coded by variant
- Optional remove button
- Compact for inline use

### Badge Component

```typescript
// Status badges
<Badge variant="default">New</Badge>
<Badge variant="secondary">Beta</Badge>
<Badge variant="destructive">Urgent</Badge>
<Badge variant="outline">Draft</Badge>
```

**Key Features**:
- Smaller than chips (for counts, status indicators)
- Pill-shaped (fully rounded)
- Color-coded by variant

### Bottom Sheet / Modal

Uses `Drawer` component from shadcn/ui:

```typescript
<Drawer>
  <DrawerTrigger>Open</DrawerTrigger>
  <DrawerContent>
    <DrawerHeader>
      <DrawerTitle>Title</DrawerTitle>
    </DrawerHeader>
    {/* Content */}
    <DrawerFooter>
      <Button>Save</Button>
    </DrawerFooter>
  </DrawerContent>
</Drawer>
```

**Key Features**:
- iOS-style bottom sheet on mobile
- Modal overlay on desktop
- Smooth slide-up animation
- Large corner radius (20px)
- Handle indicator for drag-to-dismiss

---

## Usage Guidelines

### Do's ✅

1. **Always use semantic tokens**
   ```tsx
   // ✅ Good
   <div className="bg-primary text-primary-foreground">
   
   // ❌ Bad
   <div className="bg-[#2E7D6A] text-white">
   ```

2. **Use component variants**
   ```tsx
   // ✅ Good
   <Card variant="emphasis">
   
   // ❌ Bad
   <Card className="border-2 border-primary/20 bg-primary/5">
   ```

3. **Leverage spacing scale**
   ```tsx
   // ✅ Good
   <div className="space-y-lg">
   
   // ❌ Bad
   <div className="space-y-6">
   ```

4. **Use typography scale**
   ```tsx
   // ✅ Good
   <h2 className="text-title">Section Header</h2>
   
   // ❌ Bad
   <h2 className="text-[17px] font-semibold">Section Header</h2>
   ```

### Don'ts ❌

1. Don't use arbitrary colors
2. Don't create custom shadows outside the scale
3. Don't use arbitrary spacing values
4. Don't mix design systems (stick to one button style)

---

## SwiftUI Mapping

For future native iOS implementation:

### Colors
```swift
extension Color {
    static let primary = Color("Primary")           // #2E7D6A
    static let primaryForeground = Color.white
    static let secondary = Color("Secondary")        // #6A7DFF
    static let background = Color("Background")      // #F8FAFB
    static let surface = Color("Surface")            // #FFFFFF
    static let success = Color("Success")            // matches primary
    static let warning = Color("Warning")            // #F5A623
    static let destructive = Color("Destructive")    // #D64545
}
```

### Corner Radius
```swift
extension CGFloat {
    static let radiusXS: CGFloat = 8
    static let radiusSM: CGFloat = 12
    static let radiusMD: CGFloat = 16
    static let radiusLG: CGFloat = 20
    static let radiusXL: CGFloat = 24
}
```

### Spacing
```swift
extension CGFloat {
    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 16
    static let spacingLG: CGFloat = 24
    static let spacingXL: CGFloat = 32
    static let spacing2XL: CGFloat = 48
}
```

### Typography
```swift
extension Font {
    static let headline = Font.system(size: 22, weight: .bold)
    static let title = Font.system(size: 17, weight: .semibold)
    static let body = Font.system(size: 15, weight: .regular)
    static let caption = Font.system(size: 13, weight: .regular)
    static let label = Font.system(size: 11, weight: .medium)
}
```

### Shadows
```swift
extension View {
    func shadowSM() -> some View {
        self.shadow(color: Color.black.opacity(0.04), radius: 1, y: 1)
    }
    
    func shadowMD() -> some View {
        self.shadow(color: Color.black.opacity(0.08), radius: 6, y: 4)
    }
    
    func shadowLG() -> some View {
        self.shadow(color: Color.black.opacity(0.12), radius: 12, y: 8)
    }
}
```

---

## File Locations

- **Tokens**: `src/index.css` (CSS variables)
- **Tailwind Config**: `tailwind.config.ts` (Tailwind extensions)
- **Button**: `src/components/ui/button.tsx`
- **Card**: `src/components/ui/card.tsx`
- **Chip**: `src/components/ui/chip.tsx`
- **Badge**: `src/components/ui/badge.tsx`
- **Drawer/Modal**: `src/components/ui/drawer.tsx`

---

## Version

Design System v1.0 - November 2025
