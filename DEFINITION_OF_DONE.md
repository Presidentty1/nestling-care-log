# Definition of Done (iOS - Nestling)

Scope: iOS SwiftUI app in `ios/Nuzzle/Nestling.xcodeproj`. Update this checklist after each feature or AC sweep.

## Current Status

- Functional ACs: in progress (CloudKit event upload/download + LWW merge added)
- UX/UI ACs: in progress (a11y/polish audit still pending)
- Performance metrics: not instrumented (TTFP, log-save latency)
- Accessibility: partial (added labels; full audit pending)
- Sync: partial (upload + download/merge + status pill; still need full conflict matrix)
- Notifications: partial (quiet hours guard + 30m dedupe; needs full matrix)
- AI guardrails: partial (assistant safety copy; cry insights guarded)
- Analytics: improved (onboarding start, nap prediction shown; ensure first-log remains)
- App Store checks: partial (permission strings/placeholders need confirmation)
- Code quality: lint/format not run in this pass
- Tests: xcodebuild test failed (missing test host path); needs fix and rerun

## Checklist

- [ ] Functional AC met
- [ ] UX / UI AC met
- [ ] Performance metrics captured (TTFP, time-to-log-save)
- [ ] Accessibility confirmed (Dynamic Type, VoiceOver, 44pt targets, contrast)
- [ ] Sync tested (offline → online, conflict handling, CloudKit success/error paths)
- [ ] Notifications tested (on/off, snooze, deep link, quiet hours, duplicates)
- [ ] AI guardrails tested (no diagnoses, beta labels, pediatric escalation, no stored audio)
- [ ] Analytics integrated (wrappers used, no PII, expected props, single-fire)
- [ ] App Store readiness (permissions strings, no placeholders, paywall/pricing, icons/names)
- [ ] Code lint/format passed
- [ ] Test suite passed (unit/UI)
