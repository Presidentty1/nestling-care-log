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

- **Main Entry**: `src/main.tsx` - Renders root `App` component with error boundary
- **App Component**: `src/App.tsx` - Sets up routing, auth, and query client
- **Root Route**: `src/pages/Index.tsx` - Landing/auth gate, redirects to Home or Auth

## Route Structure

### Core Routes (P0 MVP)

| Path | Component | Purpose |
|------|-----------|---------|
| `/` | `Index.tsx` | Landing page, redirects authenticated users to `/home` |
| `/auth` | `Auth.tsx` | Sign up / Sign in with email/password |
| `/home` | `Home.tsx` | Main dashboard: timeline, quick actions, nap prediction |
| `/history` | `History.tsx` | Day-by-day event history with filtering |
| `/nap-predictor` | `NapPredictor.tsx` | Next nap window prediction with feedback |
| `/ai-assistant` | `AIAssistant.tsx` | AI chat for parenting questions |

### Logging Sheets (Accessed via FAB or Quick Actions)
- Feed logging: `src/components/sheets/FeedForm.tsx`
- Diaper logging: `src/components/sheets/DiaperForm.tsx`
- Sleep logging: `src/components/sheets/SleepForm.tsx`
- Tummy time: `src/components/sheets/TummyTimeForm.tsx`

### Additional Features (Phase 2+)

| Path | Component | Purpose |
|------|-----------|---------|
| `/analytics` | `Analytics.tsx` | Charts and insights (feeding, sleep patterns) |
| `/insights` | `Insights.tsx` | Pattern analysis and recommendations |
| `/milestones` | `Milestones.tsx` | Developmental milestone tracking |
| `/growth-tracker` | `GrowthTracker.tsx` | Weight, length, head circumference charts |
| `/health-records` | `HealthRecords.tsx` | Vaccines, medications, doctor visits |
| `/cry-insights` | `CryInsights.tsx` | Cry pattern analysis (prototype) |
| `/sleep-training` | `SleepTraining.tsx` | Sleep training session management |
| `/journal` | `Journal.tsx` | Daily journal entries with photos |
| `/photo-gallery` | `PhotoGallery.tsx` | Photo gallery with albums |
| `/parent-wellness` | `ParentWellness.tsx` | Parent mood, water intake tracking |
| `/settings` | `Settings.tsx` | App settings and preferences |
| `/settings/manage-babies` | `Settings/ManageBabies.tsx` | Add/edit babies |
| `/settings/manage-caregivers` | `Settings/ManageCaregivers.tsx` | Family sharing and invites |
| `/settings/notifications` | `Settings/NotificationSettings.tsx` | Notification preferences |
| `/settings/privacy-data` | `Settings/PrivacyData.tsx` | Data export, deletion |

## Supabase Integration

### Authentication
- **Implementation**: `src/hooks/useAuth.ts`
- **Flow**: Email/password sign up → auto-confirm → profile creation → family bootstrapping
- **Session**: Stored in localStorage, auto-refresh enabled
- **Bootstrap**: `bootstrap-user` edge function creates family and default baby on first sign up

### Database Tables (Primary)

#### Core Data
- `profiles` - User profile information
- `families` - Family groups for multi-caregiver support
- `family_members` - User-to-family relationships with roles
- `babies` - Baby profiles (name, DOB, settings)
- `events` - All baby events (feeds, diapers, sleep, tummy time)

#### AI & Predictions
- `ai_conversations` - Chat conversation threads
- `ai_messages` - Individual chat messages
- `predictions` - AI-generated predictions (nap times, feeding)
- `nap_feedback` - User feedback on nap prediction accuracy

#### Extended Features
- `growth_records` - Weight, length, head circumference
- `health_records` - Vaccines, illnesses, medications
- `milestones` - Developmental milestones
- `journal_entries` - Daily journal with photos
- `cry_logs` - Cry tracking with AI categorization
- `parent_wellness_logs` - Parent mood and water intake

### Edge Functions

| Function | Purpose | Called From |
|----------|---------|-------------|
| `bootstrap-user` | Creates family and default baby on signup | Auth trigger |
| `ai-assistant` | Handles AI chat via Lovable AI (Gemini) | `useAIChat` hook |
| `calculate-nap-window` | Calculates next nap prediction | `napPredictorService.ts` |
| `generate-predictions` | General prediction generation | `Predictions.tsx` |
| `analyze-cry-pattern` | Analyzes cry audio (prototype) | `CryRecorder.tsx` |
| `generate-weekly-summary` | Creates weekly recap | `WeeklyReports.tsx` |
| `generate-monthly-recap` | Creates monthly recap | `WeeklyReports.tsx` |
| `invite-caregiver` | Sends caregiver invite emails | `CaregiverManagement.tsx` |
| `process-voice-command` | Parses voice logs (future) | `VoiceLogModal.tsx` |

### Storage Buckets
- `journal-media` - Journal photos and videos (private)
- `videos` - Generated recap videos (private)

### Real-time Subscriptions
- Events table: Live updates for multi-caregiver sync
- Implementation: `src/hooks/useRealtimeEvents.ts`

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

- `src/services/eventsService.ts` - CRUD operations for baby events
- `src/services/babyService.ts` - Baby profile management
- `src/services/napPredictorService.ts` - Nap window calculations
- `src/services/dataService.ts` - IndexedDB fallback (legacy)
- `src/services/analyticsService.ts` - Event aggregation and analysis
- `src/services/notificationManager.ts` - Local notification scheduling

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
