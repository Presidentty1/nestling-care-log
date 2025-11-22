# ADR 005: Cross-Platform Consistency Patterns

## Status
Accepted

## Context
The application runs on both web (React) and mobile (iOS) platforms, requiring consistent behavior, naming conventions, and architectural patterns across platforms.

## Decision
We established consistent patterns and conventions across React and SwiftUI platforms while respecting each platform's idioms.

## Rationale
- **User Experience**: Consistent behavior across platforms reduces confusion
- **Developer Experience**: Shared patterns make it easier to work across platforms
- **Maintainability**: Consistent naming and structure simplifies codebase navigation
- **Code Sharing**: Where possible, share logic between platforms
- **Platform Appropriateness**: Respect each platform's conventions and capabilities

## Consequences
- **Positive**:
  - Predictable user experience across platforms
  - Easier onboarding for developers working on multiple platforms
  - Reduced cognitive load when switching between platforms
  - Consistent API contracts where applicable

- **Negative**:
  - Need to balance platform-specific optimizations with consistency
  - Potential compromises in platform-specific best practices
  - Additional complexity in maintaining consistency

## Implementation
- **Naming Conventions**: Consistent naming for features, components, and services
- **Error Handling**: Similar error handling patterns with platform-appropriate implementations
- **State Management**: MVVM (iOS) and React Query (Web) with similar data flow concepts
- **Service Layer**: Consistent service APIs and singleton patterns
- **Type Definitions**: Shared type definitions where data models overlap
- **UI Patterns**: Consistent interaction patterns adapted to each platform

## Key Consistency Rules
- Feature names match between platforms (e.g., `HomeView` / `Home.tsx`)
- Service methods have consistent signatures
- Error types and handling patterns are similar
- Data models share common interfaces
- Navigation patterns follow platform conventions

## Alternatives Considered
- **Complete Code Sharing**: Not feasible due to UI and platform differences
- **Platform-Specific Patterns Only**: Would lead to inconsistent user experience
- **Web-First Approach**: Would compromise iOS user experience
- **iOS-First Approach**: Would compromise web user experience

## Related Decisions
- ADR 001: MVVM Pattern for SwiftUI Architecture
- ADR 002: React Query for State Management
- ADR 007: Capacitor for Cross-Platform Mobile
