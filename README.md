# Nestling (iOS) 🍼

Native-first baby care logging app for iOS with offline support, quick logging, and AI-assisted insights. The legacy web React app is archived in branch `archive/web-app`; `main` now focuses on SwiftUI.

## ✨ Core Features

- Offline-first logging for feeds, sleep, diapers, tummy time
- Smart nap and feed suggestions (Pro/AI)
- Flexible logging (quick actions, timers, manual entry)
- Visual timeline and history
- Multi-baby support
- Caregiver mode and accessibility
- Privacy-first: local data with optional sync

## 📱 iOS Quick Start

Prerequisites: macOS with Xcode 15+, iOS 16+ simulator or device, Apple Developer account for device testing.

1. Open the iOS project: `ios/Nuzzle/Nestling.xcodeproj`
2. Select the `Nestling` target and run on simulator or device
3. Update signing team/profile in Xcode if needed

## 🗂️ Repository Layout

- `ios/` – SwiftUI app, widgets, intents, tests
- `docs/` – iOS-focused docs (tokens, guidelines, ADRs)
- `supabase/` – Edge functions and backend schemas
- `tests/` – Supplemental tests

Web React code previously under `src/` has been removed from `main` (archived in branch `archive/web-app`).

## 🎨 Design System (SwiftUI)

Design tokens live in `ios/Nuzzle/Nestling/App/DesignSystem.swift` with semantic colors, spacing, typography, radii, shadows, and pressable interactions. iOS token documentation: `docs/DESIGN_TOKENS_IOS.md`.

## 📚 Key Docs

- iOS architecture: `ios/IOS_ARCHITECTURE.md`, `docs/IOS_MIGRATION_GUIDE.md`
- Environment & secrets: `docs/ENVIRONMENT_VARIABLES.md`
- Coding standards & quality: `docs/DEVELOPMENT_GUIDELINES.md`, `docs/CODE_QUALITY.md`
- App Store prep: `ios/APP_STORE_CHECKLIST.md`, `docs/APP_STORE_ASSETS_GUIDE.md`

## 🚦 Current Workstreams

- Finalize Nuzzle → Nestling rename (bundle IDs, targets)
- Dashboard and 2-tap logging polish
- AI features (predictions, cry insights, assistant) with paywalls
- Accessibility, performance, and QA for launch
