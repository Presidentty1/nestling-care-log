# Web Architecture Documentation

## Overview

Nuzzle is a React-based baby care tracking application with a local-first architecture, built for offline support and multi-device synchronization. This document describes the web application architecture in detail.

## Technology Stack

### Frontend Core
- **Framework**: React 18.3+ with TypeScript 5.8+
- **Build Tool**: Vite 5.4+ (fast HMR, optimized builds)
- **Routing**: React Router v6.30+ (client-side routing)
- **Styling**: Tailwind CSS 3.4+ with custom design tokens
- **UI Components**: shadcn/ui (Radix UI primitives)

### State Management
- **Global State**: Zustand 5.0+ (`src/store/appStore.ts`)
  - Baby selection, caregiver mode, UI preferences
- **Server State**: TanStack React Query 5.83+ (`src/lib/queryClient.ts`)
  - Data fetching, caching, synchronization
  - Optimistic updates for mutations
  - Automatic background refetching

### Backend Services
- **Database**: Supabase (PostgreSQL with RLS)
- **Authentication**: Supabase Auth (email/password)
- **Edge Functions**: Deno-based serverless functions
- **Storage**: Supabase Storage (photos, media)
- **Real-time**: Supabase Realtime subscriptions

### Development Tools
- **Testing**: Vitest 4.0+ (unit), Playwright 1.56+ (E2E)
- **Linting**: ESLint 9.32+ with TypeScript ESLint
- **Type Checking**: TypeScript compiler
- **Package Manager**: npm

## Application Structure

### Entry Points

```
src/
├── main.tsx              # Application entry, error boundaries
├── App.tsx               # Root component, routing setup
├── index.css             # Global styles, design tokens
└── vite-env.d.ts         # Vite type definitions
```

### Directory Organization

```
src/
├── pages/                # Route components (page-level)
│   ├── Home.tsx         # Main dashboard
│   ├── History.tsx       # Event history
│   ├── Settings.tsx      # Settings hub
│   └── ...
├── components/           # Reusable UI components
│   ├── ui/              # shadcn/ui primitives
│   ├── sheets/          # Event logging forms
│   ├── today/           # Home page components
│   └── ...
├── hooks/                # Custom React hooks
│   ├── useAuth.ts       # Authentication
│   ├── useRealtimeEvents.ts  # Real-time sync
│   └── ...
├── services/             # Business logic layer
│   ├── eventsService.ts # Event CRUD
│   ├── babyService.ts   # Baby profile management
│   └── ...
├── lib/                  # Utilities and helpers
│   ├── queryClient.ts   # React Query setup
│   ├── napPredictor.ts  # Nap prediction logic
│   └── ...
├── store/                # Zustand store
│   ├── appStore.ts      # Global state
│   └── selectors.ts     # Store selectors
├── types/                # TypeScript type definitions
└── integrations/        # Third-party integrations
    └── supabase/        # Supabase client
```

## Routing Architecture

### Route Structure

**Public Routes:**
- `/` → Redirects to `/home` or `/auth`
- `/auth` → Authentication (sign up/sign in)
- `/accept-invite/:token` → Accept caregiver invitation
- `/privacy` → Privacy policy
- `/feedback` → User feedback form

**Protected Routes (Require Authentication):**
- `/home` → Main dashboard
- `/history` → Event history with date picker
- `/onboarding` → Initial baby profile setup
- `/settings/*` → Settings pages
- `/predictions` → AI predictions
- `/analytics` → Charts and insights
- `/growth` → Growth tracking
- `/health` → Health records
- `/milestones` → Milestone tracking
- `/journal` → Journal entries
- `/labs` → Experimental features

### Route Protection

```typescript
// AuthGuard component wraps protected routes
<Route element={<AuthGuard />}>
  <Route path="/home" element={<Home />} />
  {/* ... other protected routes */}
</Route>
```

**AuthGuard Logic:**
1. Check for active session via `useAuth()`
2. If no session, redirect to `/auth`
3. If session exists but no baby profile, redirect to `/onboarding`

## State Management Architecture

### Global State (Zustand)

**Store Location**: `src/store/appStore.ts`

**State Structure:**
```typescript
interface AppState {
  selectedBabyId: string | null;
  isCaregiverMode: boolean;
  // UI preferences, theme, etc.
}
```

**Usage:**
```typescript
import { useAppStore } from '@/store/appStore';

const selectedBaby = useAppStore(state => state.selectedBabyId);
```

### Server State (React Query)

**Query Client**: `src/lib/queryClient.ts`

**Key Features:**
- Automatic caching (5 minutes default)
- Background refetching
- Optimistic updates
- Offline support via persistence

**Query Keys:**
```typescript
// Events
['events', babyId, date]
['events', babyId, 'today']

// Babies
['babies', familyId]
['baby', babyId]

// Predictions
['predictions', babyId]
```

**Mutation Pattern:**
```typescript
const mutation = useMutation({
  mutationFn: eventsService.createEvent,
  onMutate: async (newEvent) => {
    // Optimistic update
    await queryClient.cancelQueries(['events']);
    const previous = queryClient.getQueryData(['events']);
    queryClient.setQueryData(['events'], (old) => [...old, newEvent]);
    return { previous };
  },
  onError: (err, newEvent, context) => {
    // Rollback on error
    queryClient.setQueryData(['events'], context.previous);
  },
  onSettled: () => {
    // Refetch after mutation
    queryClient.invalidateQueries(['events']);
  },
});
```

## Data Flow

### Event Logging Flow

```
User Action (Quick Action Button)
  ↓
Component (QuickActions.tsx)
  ↓
Hook (useEventLogger.ts)
  ↓
Service (eventsService.ts)
  ↓
React Query Mutation
  ↓
Supabase Client (supabase.from('events').insert())
  ↓
Database (with RLS check)
  ↓
Real-time Subscription (useRealtimeEvents)
  ↓
UI Update (automatic via React Query)
```

### Offline Support

**Strategy:**
1. **React Query Persistence**: Cached data stored in IndexedDB
2. **Offline Queue**: Mutations queued when offline (`src/lib/offlineQueue.ts`)
3. **Network Detection**: `useNetworkStatus` hook monitors connectivity
4. **Automatic Sync**: Queue processed when connection restored

**Implementation:**
```typescript
// Network status detection
const { isOnline } = useNetworkStatus();

// Offline queue
const queue = useOfflineQueue();
if (!isOnline) {
  queue.add(mutation);
} else {
  queue.process();
}
```

## Component Architecture

### Component Hierarchy

```
App.tsx
  ├── AuthGuard
  │   └── Protected Routes
  │       ├── Home.tsx
  │       │   ├── BabySelector
  │       │   ├── NapPredictionCard
  │       │   ├── QuickActions
  │       │   └── EventTimeline
  │       └── History.tsx
  │           ├── DatePickerView
  │           └── DaySummary
  └── Public Routes
      └── Auth.tsx
```

### Component Patterns

**1. Container/Presentational Pattern**
- **Container**: Fetches data, manages state (`Home.tsx`)
- **Presentational**: Displays UI (`QuickActions.tsx`, `EventTimeline.tsx`)

**2. Custom Hooks Pattern**
- Business logic extracted to hooks
- Components focus on rendering
- Example: `useEventLogger`, `useRealtimeEvents`

**3. Compound Components**
- Related components grouped together
- Example: `EventTimeline` + `EventDialog`

## Service Layer

### Service Responsibilities

**Events Service** (`src/services/eventsService.ts`):
- CRUD operations for events
- Date filtering and aggregation
- Validation and error handling

**Baby Service** (`src/services/babyService.ts`):
- Baby profile management
- Family association
- Age calculations

**Nap Predictor Service** (`src/services/napPredictorService.ts`):
- Wake window calculations
- Nap timing predictions
- Pattern analysis

### Service Pattern

```typescript
// Standard service structure
export const eventsService = {
  // Query functions (for React Query)
  getEvents: async (babyId: string, date: Date) => {
    const { data, error } = await supabase
      .from('events')
      .select('*')
      .eq('baby_id', babyId)
      .gte('start_time', startOfDay(date))
      .lte('start_time', endOfDay(date));
    
    if (error) throw error;
    return data;
  },
  
  // Mutation functions (for React Query)
  createEvent: async (event: CreateEventInput) => {
    const { data, error } = await supabase
      .from('events')
      .insert(event)
      .select()
      .single();
    
    if (error) throw error;
    return data;
  },
};
```

## Supabase Integration

### Client Setup

**Location**: `src/integrations/supabase/client.ts`

**Configuration:**
```typescript
export const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY,
  {
    auth: {
      storage: localStorage,
      persistSession: true,
      autoRefreshToken: true,
    }
  }
);
```

### Authentication Flow

1. **Sign Up**: `useAuth().signUp()` → Supabase Auth
2. **Profile Creation**: Auto-created via `bootstrap-user` edge function
3. **Family Bootstrap**: Family and default baby created automatically
4. **Session Management**: Stored in localStorage, auto-refresh enabled

### Real-time Subscriptions

**Implementation**: `src/hooks/useRealtimeEvents.ts`

```typescript
useEffect(() => {
  const channel = supabase
    .channel('events')
    .on('postgres_changes', {
      event: '*',
      schema: 'public',
      table: 'events',
      filter: `family_id=eq.${familyId}`,
    }, (payload) => {
      // Update React Query cache
      queryClient.setQueryData(['events'], (old) => {
        // Handle insert/update/delete
      });
    })
    .subscribe();
  
  return () => {
    supabase.removeChannel(channel);
  };
}, [familyId]);
```

## Performance Optimizations

### Code Splitting

**Lazy Loading:**
```typescript
// Route-level code splitting
const Analytics = lazy(() => import('@/pages/Analytics'));
const GrowthTracker = lazy(() => import('@/pages/GrowthTracker'));
```

**Component-level:**
- Heavy components loaded on demand
- Modal/sheet components lazy loaded

### React Query Optimizations

- **Stale Time**: 5 minutes (prevents unnecessary refetches)
- **Cache Time**: 10 minutes (keeps data in cache)
- **Refetch on Window Focus**: Disabled (reduces API calls)
- **Background Refetch**: Enabled (keeps data fresh)

### Rendering Optimizations

- **React.memo**: Expensive components memoized
- **useMemo**: Expensive calculations memoized
- **useCallback**: Event handlers memoized
- **Virtual Scrolling**: For long lists (future)

## Error Handling

### Error Boundaries

**Location**: `src/components/ErrorBoundary.tsx`

**Strategy:**
- Top-level error boundary in `main.tsx`
- Route-level boundaries for critical sections
- Graceful degradation with fallback UI

### Error Handling Pattern

```typescript
try {
  const data = await service.fetchData();
} catch (error) {
  if (error instanceof SupabaseError) {
    // Handle Supabase-specific errors
  } else {
    // Handle generic errors
  }
  // Show user-friendly error message
  toast.error('Failed to load data');
}
```

## Testing Architecture

### Unit Tests (Vitest)

**Location**: `tests/unit/`

**Coverage:**
- Service functions
- Utility functions
- Custom hooks
- Business logic

### E2E Tests (Playwright)

**Location**: `tests/e2e/`

**Coverage:**
- Critical user flows
- Authentication
- Event logging
- Data synchronization

## Build & Deployment

### Build Process

1. **Type Checking**: `tsc --noEmit`
2. **Linting**: `eslint .`
3. **Unit Tests**: `vitest run`
4. **Build**: `vite build`
5. **E2E Tests**: `playwright test` (optional in CI)

### Deployment

**Platforms:**
- Vercel (recommended)
- Netlify
- Any static hosting

**Environment Variables:**
- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_PUBLISHABLE_KEY`
- `VITE_SENTRY_DSN` (optional)

## Security Considerations

### Client-Side Security

- **No Secrets in Code**: All secrets via environment variables
- **RLS Policies**: Database-level security (Supabase)
- **Input Validation**: Zod schemas for form validation
- **XSS Prevention**: React's built-in escaping
- **CSRF Protection**: Supabase handles CSRF tokens

### Data Privacy

- **Local Storage**: Only non-sensitive data (preferences)
- **Session Storage**: Auth tokens (auto-refresh)
- **IndexedDB**: Cached data (encrypted in transit)
- **No PII in Logs**: Error tracking sanitized

## Future Architecture Considerations

### Planned Improvements

1. **Service Worker**: Offline-first PWA
2. **Web Workers**: Heavy computations off main thread
3. **GraphQL**: Consider for complex queries (future)
4. **Micro-frontends**: If app scales significantly
5. **Edge Computing**: Move more logic to edge functions

## Related Documentation

- `ARCHITECTURE.md` - General architecture overview
- `DESIGN_SYSTEM.md` - Design tokens and components
- `DATA_MODEL.md` - Database schema
- `TEST_PLAN_WEB.md` - Testing strategy
- `DEPLOYMENT.md` - Deployment guide
