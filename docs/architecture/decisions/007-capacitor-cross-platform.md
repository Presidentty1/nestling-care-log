# ADR 007: Capacitor for Cross-Platform Mobile Development

## Status
Accepted

## Context
The application needed to run on both web and mobile platforms. Native iOS development was already planned, but a solution was needed to reuse web code and maintain feature parity.

## Decision
We chose Capacitor as the cross-platform runtime to package the React web application as a native mobile app.

## Rationale
- **Code Reuse**: Single codebase for web and mobile with platform-specific customizations
- **Web Technologies**: Use familiar React, TypeScript, and web development tools
- **Native Performance**: Access to native device APIs through Capacitor plugins
- **Ecosystem**: Large community and plugin ecosystem
- **Distribution**: Submit to app stores as native apps
- **Web Parity**: Ensure consistent features and behavior across platforms
- **Development Speed**: Faster iteration with web development workflow

## Consequences
- **Positive**:
  - Single codebase for multiple platforms
  - Familiar web development tools and ecosystem
  - Native app store distribution
  - Access to device hardware through plugins
  - Consistent user experience across platforms

- **Negative**:
  - Performance limitations compared to fully native apps
  - Dependency on Capacitor plugin ecosystem
  - Additional complexity for platform-specific features
  - App store review process for each platform

## Implementation
- **Shared Codebase**: React application runs on web and mobile
- **Platform Detection**: Runtime platform detection for conditional features
- **Native Plugins**: Capacitor plugins for camera, notifications, haptics
- **Build Process**: Separate build pipelines for web and mobile
- **App Store**: Native app submissions through Capacitor build process
- **Feature Flags**: Platform-specific feature toggles

## Platform-Specific Considerations
- **iOS**: Native iOS features through Capacitor iOS
- **Web**: Progressive Web App capabilities
- **Performance**: Optimize for mobile performance constraints
- **UI/UX**: Platform-appropriate design patterns and interactions

## Alternatives Considered
- **React Native**: Would require rewriting existing React code
- **Flutter**: Different programming language and ecosystem
- **Cordova/PhoneGap**: Older technology with smaller ecosystem
- **Web Only**: Would miss mobile app store opportunities
- **Native Only**: Duplicate development effort for iOS

## Related Decisions
- ADR 002: React Query for State Management
- ADR 005: Cross-Platform Consistency Patterns
- ADR 006: Supabase as Backend Service




