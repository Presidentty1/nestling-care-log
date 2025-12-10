# Architecture Overview

## Technology Stack

### Frontend

- **Framework**: React 18 with TypeScript
- **Build Tool**: Vite
- **Styling**: Tailwind CSS with custom design tokens
- **UI Components**: shadcn/ui (Radix UI primitives)
- **State Management**: Zustand for global state, React Query for server state
- **Routing**: React Router v6

### Backend (Lovable Cloud / Supabase)

- **Authentication**: Supabase Auth with email/password
- **Database**: PostgreSQL with Row Level Security (RLS)
- **Edge Functions**: Deno-based serverless functions
- **Storage**: Supabase Storage for media files
- **Real-time**: Supabase Realtime for live updates

## Application Entry Points

- **Main Entry**: `src/main.tsx` - Renders root `App` component with error boundary and caregiver mode class management
- **App Component**: `src/App.tsx` - Sets up routing, auth, query client, and lazy loading
- **Root Route**: `/` redirects to `/home` (no Index.tsx page exists)
- **Router**: React Router v6 with `BrowserRouter` in `App.tsx`
- **Auth Guard**: `AuthGuard` component wraps protected routes, redirects to `/auth` if not authenticated

## Route Structure

### Core Routes (P0 MVP - Eager Loaded)

| Path                        | Component                           | Purpose                                                 | Auth Required |
| --------------------------- | ----------------------------------- | ------------------------------------------------------- | ------------- |
| `/`                         | Redirect                            | Redirects to `/home`                                    | No            |
| `/auth`                     | `Auth.tsx`                          | Sign up / Sign in with email/password                   | No            |
| `/onboarding`               | `Onboarding.tsx`                    | Initial baby profile setup                              | Yes           |
| `/home`                     | `Home.tsx`                          | Main dashboard: timeline, quick actions, nap prediction | Yes           |
| `/history`                  | `History.tsx`                       | Day-by-day event history with filtering                 | Yes           |
| `/settings`                 | `Settings.tsx`                      | App settings hub                                        | Yes           |
| `/settings/babies`          | `Settings/ManageBabies.tsx`         | Add/edit baby profiles                                  | Yes           |
| `/settings/caregivers`      | `Settings/ManageCaregivers.tsx`     | Family sharing and invites                              | Yes           |
| `/settings/notifications`   | `Settings/NotificationSettings.tsx` | Notification preferences                                | Yes           |
| `/settings/privacy-data`    | `Settings/PrivacyData.tsx`          | Data export, deletion                                   | Yes           |
| `/settings/ai-data-sharing` | `Settings/AIDataSharing.tsx`        | AI consent toggle                                       | Yes           |

### Logging Sheets (Accessed via FAB or Quick Actions)

- Feed logging: `src/components/sheets/FeedForm.tsx` (via `EventSheet` component)
- Diaper logging: `src/components/sheets/DiaperForm.tsx` (via `EventSheet` component)
- Sleep logging: `src/components/sheets/SleepForm.tsx` (via `EventSheet` component)
- Tummy time: `src/components/sheets/TummyTimeForm.tsx` (via `EventSheet` component)

### Additional Features (Phase 2+ - Lazy Loaded)

| Path                          | Component                     | Purpose                                        | Auth Required | Status     |
| ----------------------------- | ----------------------------- | ---------------------------------------------- | ------------- | ---------- |
| `/labs`                       | `Labs.tsx`                    | Experimental features hub (Cry Insights entry) | No            | ✅ Working |
| `/smart-predictions`          | Redirect                      | Redirects to `/predictions`                    | Yes           | ✅ Working |
| `/predictions`                | `Predictions.tsx`             | Smart Predictions (next feed/nap)              | Yes           | ✅ Working |
| `/cry-insights`               | `CryInsights.tsx`             | Cry pattern analysis (prototype)               | Yes           | ⚠️ Beta    |
| `/ai-assistant`               | `AIAssistant.tsx`             | AI chat for parenting questions                | Yes           | ✅ Working |
| `/analytics`                  | `Analytics.tsx`               | Charts and insights (feeding, sleep patterns)  | Yes           | ✅ Working |
| `/growth`                     | `GrowthTracker.tsx`           | Weight, length, head circumference charts      | Yes           | ✅ Working |
| `/health`                     | `HealthRecords.tsx`           | Vaccines, medications, doctor visits           | Yes           | ✅ Working |
| `/milestones`                 | `Milestones.tsx`              | Developmental milestone tracking               | Yes           | ✅ Working |
| `/photos`                     | `PhotoGallery.tsx`            | Photo gallery with albums                      | Yes           | ✅ Working |
| `/sleep-training`             | `SleepTraining.tsx`           | Sleep training session management              | Yes           | ✅ Working |
| `/sleep-training/new-session` | `NewSleepTrainingSession.tsx` | Create training plans                          | Yes           | ✅ Working |
| `/journal`                    | `Journal.tsx`                 | Daily journal entries with photos              | Yes           | ✅ Working |
| `/journal/new`                | `JournalEntry.tsx`            | Create new journal entry                       | Yes           | ✅ Working |
| `/journal/entry/:id`          | `JournalEntry.tsx`            | View/edit journal entry                        | Yes           | ✅ Working |
| `/activity-feed`              | `ActivityFeed.tsx`            | Family activity log                            | Yes           | ✅ Working |
| `/parent-wellness`            | `ParentWellness.tsx`          | Parent mood, water intake tracking             | Yes           | ✅ Working |
| `/settings/shortcuts`         | `ShortcutsSettings.tsx`       | Keyboard shortcuts configuration               | Yes           | ✅ Working |
| `/referrals`                  | `Referrals.tsx`               | Referral program UI                            | No            | ✅ Working |
| `/accessibility`              | `Accessibility.tsx`           | Accessibility settings                         | No            | ✅ Working |
| `/feedback`                   | `Feedback.tsx`                | User feedback form                             | No            | ✅ Working |
| `/privacy`                    | `Privacy.tsx`                 | Privacy policy                                 | No            | ✅ Working |
| `/achievements`               | `Achievements.tsx`            | Logging streaks and badges                     | Yes           | ✅ Working |

**Status Legend:**

- ✅ Working - Feature is functional
- ⚠️ Beta - Feature exists but may have issues or incomplete functionality
- ❌ Broken - Feature is broken or routes to 404

**Note**: Route `/smart-predictions` does NOT exist - use `/predictions` instead. The Labs page (`/labs`) shows a placeholder button for Cry Insights that just displays a toast message.

## Supabase Integration

**Client Configuration**: `src/integrations/supabase/client.ts`

- Auto-generated file (do not edit directly)
- Uses environment variables: `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY`
- Session stored in localStorage with auto-refresh enabled

### Authentication

- **Implementation**: `src/hooks/useAuth.ts`
- **Flow**: Email/password sign up → auto-confirm → profile creation → family bootstrapping
- **Session**: Stored in localStorage, auto-refresh enabled
- **Bootstrap**: `bootstrap-user` edge function creates family and default baby on first sign up

### Database Tables (Primary)

#### Core Data

- `profiles` - User profile information (includes `ai_data_sharing_enabled` for consent)
- `families` - Family groups for multi-caregiver support
- `family_members` - User-to-family relationships with roles
- `babies` - Baby profiles (name, DOB, settings)
- `events` - All baby events (feeds, diapers, sleep, tummy time)

#### AI & Predictions

- `ai_conversations` - Chat conversation threads
- `ai_messages` - Individual chat messages
- `predictions` - AI-generated predictions (nap times, feeding)
- `nap_feedback` - User feedback on nap prediction accuracy
- `cry_logs` - Cry analysis sessions
- `behavior_patterns` - Detected behavioral patterns

#### Extended Features

- `growth_records` - Weight, length, head circumference
- `health_records` - Vaccines, illnesses, medications
- `milestones` - Developmental milestones
- `journal_entries` - Daily journal with photos
- `cry_logs` - Cry tracking with AI categorization
- `parent_wellness_logs` - Parent mood and water intake

### Edge Functions

| Function                  | Purpose                                   | Called From               | AI Consent  |
| ------------------------- | ----------------------------------------- | ------------------------- | ----------- |
| `bootstrap-user`          | Creates family and default baby on signup | Auth trigger              | N/A         |
| `ai-assistant`            | Handles AI chat via Lovable AI (Gemini)   | `useAIChat` hook          | ✅ Required |
| `calculate-nap-window`    | Calculates next nap prediction            | `napPredictorService.ts`  | N/A         |
| `generate-predictions`    | General prediction generation             | `Predictions.tsx`         | ✅ Required |
| `analyze-cry-pattern`     | Analyzes cry audio (prototype)            | `CryRecorder.tsx`         | ✅ Required |
| `generate-weekly-summary` | Creates weekly recap                      | `WeeklyReports.tsx`       | N/A         |
| `generate-monthly-recap`  | Creates monthly recap                     | `WeeklyReports.tsx`       | N/A         |
| `invite-caregiver`        | Sends caregiver invite emails             | `CaregiverManagement.tsx` | N/A         |
| `process-voice-command`   | Parses voice logs                         | `VoiceLogModal.tsx`       | N/A         |

**AI Consent Enforcement**: Edge functions marked with ✅ check the user's `ai_data_sharing_enabled` flag from the `profiles` table before processing. If disabled, they return an error message without calling external AI services.

### Storage Buckets

- `journal-media` - Journal photos and videos (private)
- `videos` - Generated recap videos (private)

### Real-time Subscriptions

- **Table**: `events`
- **Purpose**: Multi-caregiver sync - when one caregiver logs an event, others see it instantly
- **Implementation**: `src/hooks/useRealtimeEvents.ts`
- Subscribes to postgres_changes on the events table
- Filters by family_id to only receive relevant events

### AI Data Sharing & Consent

**Storage**: User consent is stored in `profiles.ai_data_sharing_enabled` (boolean, default true)

**Service**: `src/services/aiPreferencesService.ts` manages consent in both localStorage and Supabase

**Settings Page**: `/settings/ai-data-sharing` provides clear toggle with explanation of data usage

**Enforcement**:

- Edge functions check consent before processing (see table above)
- Frontend pages show disabled UI when consent is off:
  - `Predictions.tsx` - "Enable AI features" message with link
  - `CryInsights.tsx` - Disabled cry analysis with explanation
  - `AIAssistant.tsx` - Input disabled with inline message
- Disabled states include clear explanations and links to settings

**Medical Disclaimers**: Applied consistently across AI-powered pages using `<MedicalDisclaimer>` component with variants (`ai`, `sleep`, `predictions`)

## State Management

### Global State (Zustand)

- **Store**: `src/store/appStore.ts`
- **State**:
  - `activeBabyId` - Currently selected baby
  - `caregiverMode` - Simplified UI toggle
  - `babies` - Loaded baby profiles
  - Timer states for active sleep/feed tracking

### Server State (React Query)

- **Config**: `src/lib/queryClient.ts`
- **Persistence**: LocalForage for offline support
- **Queries**: Events, predictions, AI conversations, growth records
- **Mutations**: Create/update/delete events with optimistic updates

## Key Services

| Service                   | Purpose                                                  |
| ------------------------- | -------------------------------------------------------- |
| `eventsService.ts`        | CRUD operations for baby events (feed, diaper, sleep)    |
| `babyService.ts`          | Baby profile management                                  |
| `napPredictorService.ts`  | Calculate nap windows based on age/history               |
| `reminderService.ts`      | Schedule local notifications                             |
| `offlineQueue.ts`         | Queue mutations when offline                             |
| `dataService.ts`          | Export/import data (CSV, JSON, IndexedDB fallback)       |
| `aiPreferencesService.ts` | Manage AI data sharing consent (localStorage + Supabase) |
| `streakService.ts`        | Track daily logging streaks                              |
| `trialService.ts`         | Manage free trial state                                  |
| `guestModeService.ts`     | Handle guest/demo mode data                              |
| `analyticsService.ts`     | Event aggregation and analysis                           |
| `notificationManager.ts`  | Local notification scheduling                            |

## Design System

- **Documentation**: `DESIGN_SYSTEM.md`
- **Tokens**: `src/index.css` - CSS variables for colors, spacing, shadows
- **Config**: `tailwind.config.ts` - Extended Tailwind theme
- **Components**: `src/components/ui/` - Reusable UI primitives

## Data Flow

1. **User Action** (e.g., log feed) →
2. **Component** (`FeedForm.tsx`) →
3. **React Query Mutation** →
4. **Service Layer** (`eventsService.ts`) →
5. **Supabase Client** →
6. **Database** (with RLS check) →
7. **Real-time Update** →
8. **Other Devices** (via `useRealtimeEvents`)

## Offline Support

- IndexedDB via LocalForage (fallback, legacy)
- React Query persistence for cached data
- Offline queue: `src/lib/offlineQueue.ts` (future enhancement)
- Network status detection: `src/hooks/useNetworkStatus.ts`

## Security

- **Row Level Security (RLS)**: All tables have policies
- **Authentication**: Required for all user data access
- **Family Isolation**: Users can only access their family's data
- **Role-Based Access**: Admin vs. Member roles in `family_members`

## Build & Deployment

- **Dev Server**: `bun run dev` (port 8080)
- **Build**: `bun run build` - Outputs to `dist/`
- **Preview**: Automatic deployment on Lovable platform
- **Edge Functions**: Auto-deployed with code changes
