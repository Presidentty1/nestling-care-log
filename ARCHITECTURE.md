# Nestling Architecture

## Overview

Nestling is a progressive web app (PWA) for baby care tracking, built with a local-first architecture that works offline and syncs when online.

## Technology Stack

### Core
- **React 18** - UI library
- **TypeScript** - Type safety
- **Vite** - Build tool and dev server
- **Tailwind CSS** - Styling

### State Management
- **Zustand** - Global state
- **React Query** - Server state & caching
- **LocalForage** - IndexedDB wrapper

### UI Components
- **shadcn/ui** - Base components
- **Radix UI** - Accessible primitives
- **Lucide React** - Icons
- **Sonner** - Toast notifications

### Data Layer
- **IndexedDB** - Local database
- **LocalForage** - Storage abstraction
- **Supabase** (future) - Backend sync

### Testing
- **Vitest** - Unit tests
- **Playwright** - E2E tests
- **Testing Library** - Component tests

## Architecture Principles

### 1. Local-First

All data is stored locally first and syncs to backend when available:

```typescript
// Write to local storage immediately
const event = await dataService.addEvent(data);

// Queue for sync when online
await offlineQueue.enqueue({
  operation: 'create',
  entity: 'event',
  data: event
});
```

### 2. Offline-First

App works completely offline:
- All features available offline
- Sync queue for online operations
- Network status detection
- Graceful fallbacks

### 3. Progressive Enhancement

Features enhance when capabilities available:
- Web Notifications when permitted
- Service Worker when supported
- Push notifications (future)
- Native features with Capacitor

## Data Flow

```
User Input
    ↓
Component
    ↓
Validation (zod)
    ↓
Service Layer
    ↓
IndexedDB (immediate)
    ↓
Sync Queue (when online)
    ↓
Supabase (future)
```

## Directory Structure

```
src/
├── components/          # React components
│   ├── common/         # Reusable components
│   │   ├── ConfirmDialog.tsx
│   │   ├── EmptyState.tsx
│   │   ├── IconButton.tsx
│   │   └── SkeletonCard.tsx
│   ├── sheets/         # Bottom sheet forms
│   │   ├── EventSheet.tsx
│   │   ├── FeedForm.tsx
│   │   ├── SleepForm.tsx
│   │   ├── DiaperForm.tsx
│   │   ├── TummyTimeForm.tsx
│   │   └── SheetFrame.tsx
│   ├── today/          # Today screen
│   │   ├── SummaryChips.tsx
│   │   ├── TimelineList.tsx
│   │   ├── TimelineRow.tsx
│   │   └── NapPill.tsx
│   ├── history/        # History screen
│   │   ├── DayStrip.tsx
│   │   └── DaySummary.tsx
│   └── ui/             # Base UI (shadcn)
│
├── hooks/              # Custom React hooks
│   ├── useEventLogger.ts
│   ├── useActiveTimer.ts
│   ├── useKeyboardShortcuts.ts
│   └── usePerformance.ts
│
├── pages/              # Route pages
│   ├── OnboardingSimple.tsx
│   ├── Home.tsx
│   ├── History.tsx
│   ├── Settings/
│   │   ├── ManageBabies.tsx
│   │   ├── ManageCaregivers.tsx
│   │   ├── NotificationSettings.tsx
│   │   └── PrivacyData.tsx
│   └── ...
│
├── services/           # Business logic
│   ├── dataService.ts       # IndexedDB CRUD
│   ├── napService.ts        # Nap prediction
│   ├── notificationMonitor.ts # Notifications
│   ├── analyticsService.ts  # Analytics
│   ├── validation.ts        # Zod schemas
│   ├── time.ts             # Time utilities
│   ├── offlineQueue.ts     # Sync queue
│   └── dataMigration.ts    # Migrations
│
├── store/              # Global state
│   ├── appStore.ts    # Zustand store
│   └── selectors.ts   # Memoized selectors
│
├── types/              # TypeScript types
│   └── events.ts
│
├── lib/                # Libraries & utils
│   ├── utils.ts       # General utilities
│   ├── napPredictor.ts
│   └── ...
│
└── utils/              # Helper functions
    ├── time.ts
    └── units.ts
```

## Component Patterns

### Composition

Components are composed from smaller pieces:

```typescript
// SheetFrame - reusable shell
<SheetFrame title="Log Feed" onSave={handleSave}>
  <FeedForm />
</SheetFrame>

// TimelineRow - reusable row
<TimelineList>
  {events.map(event => (
    <TimelineRow key={event.id} event={event} />
  ))}
</TimelineList>
```

### Container/Presenter

Separate data logic from presentation:

```typescript
// Container (page)
function Home() {
  const { data: events } = useQuery('events', fetchEvents);
  return <TimelineList events={events} />;
}

// Presenter (component)
function TimelineList({ events }) {
  return events.map(event => <TimelineRow event={event} />);
}
```

### Custom Hooks

Extract reusable logic:

```typescript
// useEventLogger.ts
export function useEventLogger(babyId: string) {
  const [events, setEvents] = useState([]);
  
  const addEvent = useCallback(async (data) => {
    const event = await dataService.addEvent(data);
    setEvents(prev => [event, ...prev]);
  }, []);

  return { events, addEvent };
}
```

## Data Models

### Baby

```typescript
interface Baby {
  id: string;
  name: string;
  date_of_birth: string;  // ISO date
  timezone: string;        // IANA timezone
  units: 'metric' | 'imperial';
  sex?: 'male' | 'female' | 'other';
  createdAt: string;
  updatedAt: string;
}
```

### Event Record

```typescript
interface EventRecord {
  id: string;
  babyId: string;
  type: 'feed' | 'sleep' | 'diaper' | 'tummy';
  subtype?: string;
  startTime: string;      // ISO datetime
  endTime?: string;       // ISO datetime
  durationMin?: number;
  amount?: number;        // ml (canonical)
  unit?: 'ml' | 'oz';    // display unit
  note?: string;
  source: 'local' | 'synced';
  createdAt: string;
  updatedAt: string;
}
```

## State Management

### Global State (Zustand)

```typescript
// appStore.ts
interface AppState {
  activeBabyId: string | null;
  caregiverMode: boolean;
  setActiveBabyId: (id: string) => void;
  setCaregiverMode: (enabled: boolean) => void;
}
```

### Local State

Use useState for component-specific state:

```typescript
function FeedForm() {
  const [feedType, setFeedType] = useState<'breast' | 'bottle'>('bottle');
  const [amount, setAmount] = useState<number>(0);
}
```

### Derived State

Use selectors for computed values:

```typescript
// selectors.ts
export const getDayTotals = (events: EventRecord[]) => {
  return {
    feedCount: events.filter(e => e.type === 'feed').length,
    sleepMinutes: events
      .filter(e => e.type === 'sleep')
      .reduce((sum, e) => sum + (e.durationMin || 0), 0),
  };
};
```

## Service Layer

Services handle business logic and data persistence:

### Data Service

CRUD operations on IndexedDB:

```typescript
class DataService {
  async addEvent(event): Promise<EventRecord> { ... }
  async updateEvent(id, updates): Promise<EventRecord> { ... }
  async deleteEvent(id): Promise<void> { ... }
  async listEventsByDay(babyId, day): Promise<EventRecord[]> { ... }
}
```

### Nap Service

Nap window predictions:

```typescript
class NapService {
  predict(baby: Baby, lastSleep: EventRecord): NapPrediction { ... }
  calculateWakeWindow(ageMonths: number): WakeWindow { ... }
}
```

## Validation

Use Zod for type-safe validation:

```typescript
// validation.ts
export const eventSchema = z.object({
  type: z.enum(['feed', 'sleep', 'diaper', 'tummy']),
  startTime: z.string(),
  endTime: z.string().optional(),
}).refine(data => {
  if (data.endTime) {
    return new Date(data.endTime) >= new Date(data.startTime);
  }
  return true;
});

// Usage
const result = eventSchema.safeParse(formData);
if (!result.success) {
  // Handle validation errors
}
```

## Error Handling

### Graceful Degradation

```typescript
try {
  await dataService.addEvent(event);
  toast.success('Event logged!');
} catch (error) {
  console.error('Failed to save event:', error);
  toast.error('Could not save event. Your data stays on this device.');
}
```

### Error Boundaries

```typescript
<ErrorBoundary fallback={<ErrorFallback />}>
  <App />
</ErrorBoundary>
```

## Performance

### Memoization

```typescript
const sortedEvents = useMemo(() => {
  return events.sort((a, b) => 
    b.startTime.localeCompare(a.startTime)
  );
}, [events]);
```

### Virtual Scrolling

For large lists:

```typescript
<VirtualList
  items={events}
  itemHeight={72}
  renderItem={event => <TimelineRow event={event} />}
/>
```

### Code Splitting

```typescript
const Analytics = lazy(() => import('./pages/Analytics'));

<Suspense fallback={<Loading />}>
  <Analytics />
</Suspense>
```

## Accessibility

### Keyboard Navigation

```typescript
<button
  onClick={handleClick}
  onKeyDown={e => e.key === 'Enter' && handleClick()}
  aria-label="Log feed event"
/>
```

### Screen Readers

```typescript
<div role="region" aria-label="Today's timeline">
  {events.map(event => (
    <article aria-label={`${event.type} event at ${time}`}>
      ...
    </article>
  ))}
</div>
```

## Testing Strategy

### Unit Tests

Test pure functions and utilities:

```typescript
describe('formatDuration', () => {
  it('formats hours and minutes', () => {
    expect(formatDuration(90)).toBe('1h 30m');
  });
});
```

### Integration Tests

Test component interactions:

```typescript
describe('EventSheet', () => {
  it('validates and submits form', async () => {
    render(<EventSheet />);
    // Test implementation
  });
});
```

### E2E Tests

Test complete user flows:

```typescript
test('log a feed from start to finish', async ({ page }) => {
  await page.goto('/home');
  await page.click('button:has-text("Feed")');
  // Complete flow test
});
```

## Future Enhancements

### Supabase Integration

- Real-time sync
- Multi-device support
- Caregiver collaboration
- Cloud backup

### Native Features

- Push notifications
- Background sync
- Native camera
- Haptic feedback

### AI/ML

- Cry detection
- Sleep coaching
- Growth predictions
- Anomaly detection

## Deployment

### Build

```bash
npm run build
```

Outputs to `dist/` directory.

### Environment Variables

```env
VITE_SUPABASE_URL=...
VITE_SUPABASE_ANON_KEY=...
```

### Performance Targets

- LCP < 2.5s
- FID < 100ms
- CLS < 0.1
- Bundle size < 500KB

## Monitoring

Track key metrics:

- Error rate
- Load time
- API latency
- User engagement
- Offline usage

## Security

- All data encrypted in IndexedDB
- No PII sent to analytics
- Secure authentication (future)
- HTTPS only
- CSP headers
