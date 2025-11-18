# Design Tokens for iOS Migration

This document maps Nestling's web design tokens to iOS equivalents for consistent visual design during native migration.

## Color Palette

### Primary Colors
```swift
// Web: --primary: 168 46% 34%
static let primary = Color(hue: 168/360, saturation: 0.46, brightness: 0.34)
// UIKit: UIColor(hue: 168/360, saturation: 0.46, brightness: 0.34, alpha: 1.0)

// Web: --primary-soft: 168 46% 88%
static let primarySoft = Color(hue: 168/360, saturation: 0.46, brightness: 0.88)
```

### Event Colors
```swift
static let eventFeed = Color(hue: 199/360, saturation: 0.89, brightness: 0.48)
static let eventSleep = Color(hue: 237/360, saturation: 0.51, brightness: 0.55)
static let eventDiaper = Color(hue: 43/360, saturation: 0.96, brightness: 0.51)
static let eventTummyTime = Color(hue: 291/360, saturation: 0.47, brightness: 0.51)
```

### Semantic Colors
```swift
static let success = Color(hue: 142/360, saturation: 0.76, brightness: 0.36)
static let warning = Color(hue: 38/360, saturation: 0.92, brightness: 0.50)
static let danger = Color(hue: 0/360, saturation: 0.84, brightness: 0.60)
static let info = Color(hue: 199/360, saturation: 0.89, brightness: 0.48)
```

### Background & Surface
```swift
static let background = Color(.systemBackground)
static let surface = Color(.secondarySystemBackground)
static let border = Color(.separator)
```

## Typography

### Font Sizes
```swift
enum FontSize {
    static let h1: CGFloat = 28  // Large title
    static let h2: CGFloat = 24  // Title 1
    static let h3: CGFloat = 20  // Title 2
    static let body: CGFloat = 16  // Body
    static let caption: CGFloat = 14  // Callout
    static let tiny: CGFloat = 12  // Footnote
}
```

### Font Weights
```swift
// Use SF Pro (system font) with appropriate weights
.font(.system(size: FontSize.h1, weight: .bold))
.font(.system(size: FontSize.h2, weight: .semibold))
.font(.system(size: FontSize.body, weight: .regular))
```

### Dynamic Type Support
```swift
// Enable automatic text scaling
Text("Hello")
    .font(.system(size: FontSize.body))
    .dynamicTypeSize(.medium ... .xxxLarge)
```

## Spacing

### Padding Scale
```swift
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
}
```

### Safe Areas
```swift
// Always respect safe areas for notch/home indicator
.padding(.top, geometry.safeAreaInsets.top)
.padding(.bottom, geometry.safeAreaInsets.bottom + 70) // Extra for tab bar
```

## Border Radius

```swift
enum CornerRadius {
    static let sm: CGFloat = 4
    static let md: CGFloat = 8
    static let lg: CGFloat = 12
    static let xl: CGFloat = 16
    static let pill: CGFloat = 9999  // Fully rounded
}
```

## Shadows

```swift
// Subtle shadow for cards
.shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)

// Medium shadow for elevated elements
.shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)

// Strong shadow for modals
.shadow(color: .black.opacity(0.16), radius: 20, x: 0, y: 8)
```

## Animation Durations

```swift
enum AnimationDuration {
    static let instant: Double = 0.15
    static let fast: Double = 0.2
    static let normal: Double = 0.3
    static let slow: Double = 0.5
}

// Spring animation for natural feel
.animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)
```

## Touch Targets

```swift
// Minimum touch target size (Apple HIG)
static let minTouchTarget: CGFloat = 44

// Ensure all interactive elements meet minimum
Button("Action") { }
    .frame(minWidth: 44, minHeight: 44)
```

## Usage Examples

### Card Component
```swift
struct NestlingCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            content
        }
        .padding(Spacing.lg)
        .background(Color.surface)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
    }
}
```

### Button Component
```swift
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: FontSize.body, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.primary)
                .cornerRadius(CornerRadius.lg)
        }
    }
}
```

### Event Pill
```swift
struct EventPill: View {
    let type: EventType
    let count: Int
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: type.icon)
                .font(.system(size: 20))
            Text("\(count)")
                .font(.system(size: FontSize.body, weight: .semibold))
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(type.color.opacity(0.1))
        .foregroundColor(type.color)
        .cornerRadius(CornerRadius.pill)
    }
}
```

## Dark Mode Support

```swift
// Semantic colors automatically adapt to dark mode
// For custom colors, define both variants:
extension Color {
    static let customBackground = Color(
        light: Color(hue: 0, saturation: 0, brightness: 0.98),
        dark: Color(hue: 0, saturation: 0, brightness: 0.12)
    )
}
```

## Notes for iOS Migration

1. **Use SF Symbols** for icons instead of Lucide React icons
   - Map common icons (e.g., `Milk` → `drop.fill`, `Moon` → `moon.fill`)

2. **Native Components** over custom implementations
   - Use `NavigationView`, `TabView`, `Sheet` for navigation
   - Use native pickers, date pickers, forms

3. **Accessibility**
   - All colors have sufficient contrast (WCAG AA)
   - All interactive elements ≥44pt touch target
   - Support Dynamic Type (text scaling)
   - Add VoiceOver labels to all controls

4. **Performance**
   - Use `LazyVStack` for long lists (timeline)
   - Avoid complex view hierarchies
   - Use `@StateObject` and `@ObservedObject` appropriately

5. **Haptics**
   - Use `UIImpactFeedbackGenerator` for button taps
   - Use `UINotificationFeedbackGenerator` for success/error states
   - Match web haptic patterns (light/medium/heavy)
