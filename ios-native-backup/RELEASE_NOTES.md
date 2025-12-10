# Release Notes - Productionization Sprint

## Version 1.0.0

### Major Features

#### Core Data Migration

- Migrated from JSON-only storage to Core Data for improved performance
- Added data migration service for seamless JSON → Core Data transition
- Implemented App Groups for shared storage with Widgets extension

#### Onboarding Experience

- Multi-step onboarding flow with welcome, baby setup, preferences, AI consent, and notifications intro
- First-run experience guides users through initial setup
- Onboarding state persists across app launches

#### Predictions Engine

- On-device predictions engine using deterministic heuristics
- Wake window calculator based on baby's age
- Feed spacing calculator for next feed predictions
- No networking required - all calculations are local

#### Cry Insights (Beta)

- Local audio recording with AVAudioSession
- Rule-based cry classification (NO ML, NO medical claims)
- Privacy-focused: recordings deleted immediately after analysis
- Prominent medical disclaimers

#### Widgets & Live Activities

- WidgetKit widgets for Next Nap, Next Feed, and Today Summary
- Live Activity support for active sleep tracking (placeholder)
- App Groups integration for shared data

#### App Intents

- Shortcuts and Siri integration
- Quick logging via voice commands
- Support for Feed, Sleep, Diaper, and Tummy Time logging

#### Local Notifications

- UNUserNotificationCenter integration
- Feed reminders, nap window alerts, diaper reminders
- Quiet hours support
- Permission management UI

#### Deep Links

- Custom URL scheme: `nestling://`
- Support for logging actions, opening views, sleep start/stop
- Navigation coordinator for routing

#### Privacy & Security

- Face ID / Touch ID authentication (opt-in)
- App privacy blur in app switcher
- Caregiver mode with simplified UI
- Privacy settings view

#### Exports & Backups

- CSV export (enhanced)
- JSON export
- PDF export with formatted reports
- Complete backup system (ZIP with JSON + PDF)
- Restore from backup functionality

#### Achievements & Streaks

- Streak tracking service
- Achievement system with badges
- Celebratory UI for unlocked achievements
- Opt-in only, never guilt-inducing

#### Performance

- OSLog integration with categories
- Signpost logging for performance measurement
- Background context optimization for Core Data
- Memory audit recommendations

#### UI Tests

- Onboarding flow tests
- Quick actions tests
- Predictions gating tests
- Export flow tests
- Screenshot attachments

#### Localization

- English (en) - complete
- Spanish (es) - initial support
- Unit conversion support (ml ↔ oz)
- Date/time localization

#### Branding

- App icon asset catalog structure
- Accent color definition
- About screen with version info
- Links to privacy policy, terms, support

### Technical Improvements

- **Architecture**: MVVM with Domain layer, dependency injection via AppEnvironment
- **Data Layer**: Core Data with migration support, JSON fallback
- **Testing**: Unit tests for DataStore, DateUtils, UI tests for critical flows
- **Performance**: Signposts, OSLog categories, background contexts
- **Accessibility**: VoiceOver labels, Dynamic Type support, Dark Mode

### Known Limitations

- Live Activities require iOS 16.1+ (placeholder implementation)
- Widget data refresh relies on timeline policy (App Groups integration needed for real-time updates)
- Cry Insights uses rule-based classification (no ML model)
- Backup restore requires manual file picker (to be implemented)

### Migration Notes

- Existing JSON data can be migrated to Core Data via Settings → Data Migration
- Onboarding will show on first launch after update
- Notification permissions must be granted for reminders to work

### Next Steps (P2)

- Real-time widget updates via App Groups
- Enhanced Live Activities with Dynamic Island support
- Improved cry classification (with user consent and proper ML)
- Cloud sync integration (Supabase)
- Push notifications
- Enhanced caregiver mode features
