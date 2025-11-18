# Web Architecture Documentation

## Overview

Nestling web app is a React + TypeScript application built with Vite, using Supabase as the backend. The app follows a local-first architecture with offline support via IndexedDB.

## Technology Stack

- **Framework**: React 18 + TypeScript
- **Build Tool**: Vite
- **Styling**: Tailwind CSS + shadcn/ui components
- **State Management**: 
  - Zustand for global state (`src/store/appStore.ts`)
  - React Query for server state (`src/lib/queryClient.ts`)
- **Routing**: React Router v6
- **Backend**: Supabase (PostgreSQL + Edge Functions)
- **Local Storage**: IndexedDB via LocalForage
- **Testing**: Vitest (unit) + Playwright (E2E)

## Project Structure

```
src/
├── App.tsx                 # Root component, routing setup
├── main.tsx               # Entry point
├── components/             # Reusable UI components
│   ├── sheets/           # Event logging forms
│   ├── today/            # Home dashboard components
│   ├── ui/               # shadcn/ui components
│   └── ...
├── pages/                 # Route components
│   ├── Home.tsx          # Main dashboard
│   ├── History.tsx       # Event history
│   ├── Settings/         # Settings pages
│   └── ...
├── services/             # Business logic
│   ├── eventsService.ts  # Event CRUD operations
│   ├── babyService.ts    # Baby management
│   └── ...
├── hooks/                # Custom React hooks
│   ├── useAuth.ts        # Authentication
│   ├── useEventLogger.ts # Event logging
│   └── ...
├── store/                # Zustand store
│   └── appStore.ts       # Global state
├── lib/                  # Utilities
│   ├── queryClient.ts    # React Query setup
│   ├── utils.ts          # Helper functions
│   └── ...
├── types/                # TypeScript types
├── integrations/         # External integrations
│   └── supabase/         # Supabase client
└── analytics/            # Analytics abstraction
    └── analytics.ts      # Event tracking
```

## Data Flow

### Event Logging Flow

1. **User Action**: User clicks "Feed" quick action or opens form
2. **Component**: `QuickActions` or `EventSheet` component
3. **Hook**: `useEventLogger` hook handles form state
4. **Service**: `eventsService.createEvent()` sends to Supabase
5. **Local Storage**: Event also saved to IndexedDB for offline support
6. **State Update**: React Query invalidates cache, UI updates
7. **Analytics**: Event tracked via `track('event_logged')`

### Authentication Flow

1. **User Signs Up/In**: `useAuth` hook handles auth
2. **Supabase Auth**: Email/password via Supabase Auth
3. **Profile Creation**: Profile created in `profiles` table
4. **Bootstrap**: `bootstrap-user` edge function creates family + default baby
5. **Session Storage**: Session stored in localStorage
6. **Analytics**: User identified via `identify(userId)`

### Data Fetching

- **React Query**: Used for all Supabase queries
- **Cache Strategy**: Stale-while-revalidate
- **Offline Support**: IndexedDB fallback when offline
- **Optimistic Updates**: UI updates immediately, syncs in background

## Key Components

### Home Page (`src/pages/Home.tsx`)

- Displays current baby
- Summary cards (feeds, sleep, diapers)
- Timeline of today's events
- Quick action buttons
- Nap prediction card

### Event Forms (`src/components/sheets/`)

- `FeedForm.tsx`: Feed logging (breast/bottle, amount, side)
- `DiaperForm.tsx`: Diaper logging (wet/dirty/both)
- `SleepForm.tsx`: Sleep logging (start/end times)
- `TummyTimeForm.tsx`: Tummy time logging (duration)

### Services

#### `eventsService.ts`

- `createEvent()`: Create new event
- `updateEvent()`: Update existing event
- `deleteEvent()`: Delete event
- `getTodayEvents()`: Fetch today's events
- `getEventsByDate()`: Fetch events for specific date
- `calculateSummary()`: Calculate daily summary stats

#### `babyService.ts`

- `getUserBabies()`: Fetch user's babies
- `addBaby()`: Create new baby
- `updateBaby()`: Update baby
- `deleteBaby()`: Delete baby

## State Management

### Global State (Zustand)

`src/store/appStore.ts` manages:
- `activeBabyId`: Currently selected baby
- `caregiverMode`: Accessibility mode toggle
- `guestMode`: Guest mode state

### Server State (React Query)

React Query manages:
- Events data (cached, auto-refreshed)
- Babies data
- Predictions
- Settings

## Supabase Integration

### Client Setup

`src/integrations/supabase/client.ts`:
- Auto-generated Supabase client
- Uses environment variables: `VITE_SUPABASE_URL`, `VITE_SUPABASE_PUBLISHABLE_KEY`
- Session stored in localStorage

### Database Tables

- `profiles`: User profiles
- `families`: Family groups
- `family_members`: User-family relationships
- `babies`: Baby profiles
- `events`: All care events (feeds, sleep, diapers, etc.)
- `app_settings`: User preferences

### Edge Functions

- `bootstrap-user`: Creates family + default baby on signup
- `generate-predictions`: AI-powered predictions
- `ai-assistant`: AI chat for parenting questions
- `analyze-cry-pattern`: Cry analysis (beta)

## Routing

### Core Routes (Eager Loaded)

- `/` → Redirects to `/home`
- `/auth` → Sign up / Sign in
- `/onboarding` → First-time setup
- `/home` → Main dashboard
- `/history` → Event history
- `/settings` → Settings hub

### Feature Routes (Lazy Loaded)

- `/predictions` → Smart predictions
- `/ai-assistant` → AI chat
- `/analytics` → Charts and insights
- `/growth` → Growth tracking
- `/health` → Health records
- `/milestones` → Milestone tracking

## Offline Support

- **IndexedDB**: All events cached locally via LocalForage
- **Sync Queue**: Offline changes queued, synced when online
- **Offline Indicator**: Shows connection status
- **Conflict Resolution**: Last-write-wins strategy

## Analytics

See `ANALYTICS_SPEC_WEB.md` for complete event taxonomy.

Key events tracked:
- `event_logged`, `event_edited`, `event_deleted`
- `settings_changed`
- `user_signed_up`, `user_signed_in`
- `page_viewed`
- `quick_action_used`

## Testing

### Unit Tests (Vitest)

Located in `tests/`:
- Component tests: `tests/components/`
- Utility tests: `tests/*.test.ts`
- Service tests: `tests/dataService.test.ts`

### E2E Tests (Playwright)

Located in `tests/e2e/`:
- `mvp-critical-path.spec.ts`: Core user flows
- `events.spec.ts`: Event logging
- `history.spec.ts`: History navigation
- `onboarding.spec.ts`: Onboarding flow

## Performance Optimizations

- **Code Splitting**: Lazy loading for feature routes
- **React Query**: Automatic caching and background refetching
- **Memoization**: `React.memo` for expensive components
- **Virtual Scrolling**: For long event lists (future)

## Security

- **Row Level Security (RLS)**: Enforced at database level
- **Auth Guards**: Protected routes require authentication
- **Input Validation**: Zod schemas for form validation
- **XSS Prevention**: React's built-in escaping

## Deployment

- **Build**: `npm run build` → `dist/` directory
- **Hosting**: Vercel/Netlify (static hosting)
- **Edge Functions**: Deployed to Supabase
- **Environment Variables**: Configured in hosting platform

## Development Workflow

1. **Local Dev**: `npm run dev` → http://localhost:5173
2. **Testing**: `npm run test` (unit), `npm run test:e2e` (E2E)
3. **Linting**: `npm run lint`
4. **Build**: `npm run build`

## Future Improvements

- [ ] Add React Query DevTools
- [ ] Implement virtual scrolling for timeline
- [ ] Add service worker for offline-first
- [ ] Optimize bundle size (code splitting)
- [ ] Add error boundary for better error handling


