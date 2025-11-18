# MVP Checklist

This checklist tracks the completion status of core features for both web and iOS platforms.

## Web App

### Core Features (P0)

- [x] **Authentication**
  - [x] Sign up / Sign in
  - [x] Session persistence
  - [x] Protected routes

- [x] **Baby Management**
  - [x] Create baby profile
  - [x] Edit baby profile
  - [x] Delete baby
  - [x] Switch active baby

- [x] **Event Logging**
  - [x] Log feed (bottle/breast, amount, side)
  - [x] Log diaper (wet/dirty/both)
  - [x] Log sleep (start/end times)
  - [x] Log tummy time (duration)
  - [x] Edit event
  - [x] Delete event

- [x] **Home Dashboard**
  - [x] Summary cards (feeds, sleep, diapers)
  - [x] Today's timeline
  - [x] Quick actions
  - [x] Nap prediction

- [x] **History**
  - [x] Date picker
  - [x] View events by date
  - [x] Navigate days

- [x] **Settings**
  - [x] Units preference (ml/oz)
  - [x] AI data sharing toggle
  - [x] Notification settings
  - [x] Baby management
  - [x] Data export (CSV/JSON)

### Testing & Quality

- [x] **Unit Tests**
  - [x] Utility functions
  - [x] Service logic
  - [x] Component tests (partial)

- [x] **E2E Tests**
  - [x] Critical path
  - [x] Event logging
  - [x] History navigation
  - [x] Onboarding

- [x] **Analytics**
  - [x] Analytics abstraction
  - [x] Event tracking (partial)
  - [x] Page tracking

- [x] **Documentation**
  - [x] Architecture docs
  - [x] Test plan
  - [x] Analytics spec

### Backend

- [x] **Database**
  - [x] Schema migrations
  - [x] RLS policies
  - [x] Seed scripts

- [x] **Edge Functions**
  - [x] Bootstrap user
  - [x] Generate predictions
  - [x] AI assistant
  - [x] Cry analysis

## iOS App

### Core Features (P0)

- [x] **App Structure**
  - [x] SwiftUI app entry
  - [x] Tab navigation
  - [x] App environment

- [x] **Domain Models**
  - [x] Baby model
  - [x] Event model
  - [x] AppSettings model
  - [x] Prediction model

- [x] **Data Persistence**
  - [x] DataStore protocol
  - [x] JSONBackedDataStore
  - [x] InMemoryDataStore (for tests/previews)
  - [x] Core Data option (available)

- [x] **Home Screen**
  - [x] Baby selector
  - [x] Summary cards
  - [x] Quick actions
  - [x] Timeline

- [x] **History Screen**
  - [x] Date picker
  - [x] Timeline by date
  - [x] Edit/delete events

- [x] **Event Forms**
  - [x] Feed form
  - [x] Diaper form
  - [x] Sleep form
  - [x] Tummy time form

- [x] **Settings**
  - [x] Units toggle
  - [x] AI data sharing toggle
  - [x] Notification settings
  - [x] Baby management
  - [x] Privacy/data export

- [x] **Predictions**
  - [x] Local predictions engine
  - [x] Predictions view
  - [x] Medical disclaimer

### Modern iOS Features

- [x] **UX Polish**
  - [x] Bottom sheet detents
  - [x] Pull-to-refresh
  - [x] Swipe actions
  - [x] Context menus
  - [x] Searchable timelines
  - [x] Haptics

- [x] **Accessibility**
  - [x] VoiceOver labels
  - [x] Dynamic Type support
  - [x] Large touch targets

- [x] **Widgets & Shortcuts**
  - [x] Home screen widgets
  - [x] Lock screen widgets
  - [x] App Intents (Siri shortcuts)
  - [x] Live Activities (sleep timer)

- [x] **Advanced Features**
  - [x] Dynamic Island
  - [x] Keyboard shortcuts
  - [x] Spotlight indexing
  - [x] Deep links

### Testing & Quality

- [x] **Unit Tests**
  - [x] DataStore tests
  - [x] Date utilities tests
  - [x] Predictions engine tests

- [x] **UI Tests**
  - [x] Onboarding flow
  - [x] Quick actions
  - [x] Deep links
  - [x] Predictions

- [x] **Documentation**
  - [x] Architecture docs
  - [x] Xcode setup guide
  - [x] Test plan

### Setup Requirements

- [ ] **Xcode Project**
  - [ ] Create `.xcodeproj` file (manual)
  - [ ] Add files to targets (manual)
  - [ ] Configure code signing (manual)
  - [ ] Link Core Data model (manual)

## Backend (Supabase)

### Database

- [x] **Schema**
  - [x] Core tables (babies, events, families)
  - [x] Extended tables (growth, health, milestones, etc.)
  - [x] Indexes for performance

- [x] **Security**
  - [x] RLS enabled on all tables
  - [x] Family-scoped policies
  - [x] Role-based access (admin/member/viewer)

- [x] **Migrations**
  - [x] 17 migration files
  - [x] Versioned migrations
  - [x] Seed script

### Edge Functions

- [x] **Core Functions**
  - [x] bootstrap-user
  - [x] generate-predictions
  - [x] calculate-nap-window
  - [x] ai-assistant
  - [x] analyze-cry-pattern

- [x] **Additional Functions**
  - [x] generate-weekly-summary
  - [x] invite-caregiver
  - [x] process-voice-command

## CI/CD

- [x] **Web CI**
  - [x] GitHub Actions workflow
  - [x] Unit tests
  - [x] E2E tests
  - [x] Build verification

- [x] **iOS CI**
  - [x] GitHub Actions workflow
  - [x] Build verification (when project exists)
  - [x] Test execution (when project exists)

## Documentation

- [x] **Architecture**
  - [x] Web architecture (`ARCHITECTURE_WEB.md`)
  - [x] iOS architecture (`ios/IOS_ARCHITECTURE.md`)
  - [x] Data model (`DATA_MODEL.md`)

- [x] **Operations**
  - [x] DB operations (`DB_OPERATIONS.md`)
  - [x] DB security (`DB_SECURITY.md`)
  - [x] Test plans (web + iOS)

- [x] **Setup Guides**
  - [x] Xcode setup (`ios/XCODE_SETUP.md`)
  - [x] Quick start (`ios/QUICK_START.md`)

- [x] **Specifications**
  - [x] Analytics spec (`ANALYTICS_SPEC_WEB.md`)
  - [x] Design system (`DESIGN_SYSTEM.md`)

## P1 Items (Post-MVP)

### Web

- [ ] Expand component test coverage
- [ ] Add visual regression tests
- [ ] Performance monitoring (Lighthouse CI)
- [ ] Production analytics integration

### iOS

- [ ] Test on physical device
- [ ] Configure App Groups (for widgets)
- [ ] Enable real notifications
- [ ] Add Supabase sync layer

### Backend

- [ ] Add database backup automation
- [ ] Monitor RLS policy performance
- [ ] Add rate limiting to edge functions

## P2 Items (Future)

### Web

- [ ] Service worker for offline-first
- [ ] Virtual scrolling for long timelines
- [ ] Advanced analytics dashboard

### iOS

- [ ] Complete Cry Analysis ML integration
- [ ] Test widgets on device
- [ ] Add Pro subscription checks
- [ ] Performance optimization for large datasets

### Backend

- [ ] Add database replication
- [ ] Implement audit logging
- [ ] Add data retention policies

## Summary

### ✅ Complete

- **Web**: Core features, tests, analytics, docs
- **iOS**: Code complete, needs Xcode project setup
- **Backend**: Schema, migrations, RLS, edge functions
- **CI**: Workflows for web and iOS

### ⏳ Remaining

- **iOS**: Xcode project creation (manual, ~10 minutes)
- **P1**: Device testing, App Groups, notifications, Supabase sync
- **P2**: ML features, performance optimizations

### 🎯 Ready For

- **Web Beta**: ✅ Ready
- **iOS TestFlight**: ⏳ After Xcode project setup
- **App Store**: ⏳ After P1 items complete


