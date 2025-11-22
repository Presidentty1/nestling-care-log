# Development Guidelines

## Import Organization

### Standard Import Order
1. **React imports** (useState, useEffect, etc.)
2. **External libraries** (date-fns, lucide-react, etc.)
3. **Internal UI components** (@/components/ui/*)
4. **Internal utilities** (@/lib/*)
5. **Internal services** (@/services/*)
6. **Internal types** (@/types/*)
7. **Internal store/state** (@/store/*)

### Example
```typescript
// React imports
import { useState, useEffect } from 'react';

// External libraries
import { format } from 'date-fns';
import { Calendar } from 'lucide-react';

// UI components
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';

// Internal utilities
import { dateUtils } from '@/lib/sharedUtils';
import { logger } from '@/lib/logger';

// Services
import { eventsService } from '@/services/eventsService';

// Types
import type { EventRecord } from '@/types/events';

// Store
import { useAppStore } from '@/store/appStore';
```

### Type Imports
Use `import type` for type-only imports to improve bundle size:

```typescript
// ✅ Good
import type { EventRecord } from '@/types/events';
import { eventsService } from '@/services/eventsService';

// ❌ Avoid
import { EventRecord, eventsService } from '@/services/eventsService';
```

## File Naming Conventions

### Components
- **PascalCase**: `Button.tsx`, `UserProfile.tsx`
- **Directories**: lowercase with hyphens: `user-profile/`
- **Index files**: Use `index.ts` for directory exports

### Services
- **camelCase**: `eventsService.ts`, `userPreferencesService.ts`

### Utilities
- **camelCase**: `dateUtils.ts`, `validationUtils.ts`

### Types
- **PascalCase interfaces**: `UserProfile`, `EventRecord`
- **camelCase files**: `events.ts`, `user.ts`

## Module Boundaries

### Service Layer
- Services should only depend on utilities and external libraries
- Services should not import React hooks or components
- Services should be pure functions where possible

### Component Layer
- Components should only import services, not implement business logic
- Components should be focused on UI rendering and user interaction
- Business logic should be in custom hooks or services

### Utility Layer
- Utilities should be pure functions
- No side effects or external dependencies
- Easy to test in isolation

## Error Handling

### User-Facing Errors
```typescript
try {
  await someOperation();
} catch (error) {
  logger.error('Operation failed', error, 'ComponentName');
  toast.error('User-friendly error message');
}
```

### Internal Errors
```typescript
try {
  await someOperation();
} catch (error) {
  logger.error('Operation failed', error, 'ServiceName');
  throw new Error('Technical error message');
}
```

## State Management

### Local State
Use React hooks for component-local state:
```typescript
const [value, setValue] = useState(initialValue);
```

### Global State
Use Zustand store for app-wide state:
```typescript
const { user, setUser } = useAppStore();
```

### Server State
Use React Query for server state:
```typescript
const { data, isLoading } = useQuery(['events', babyId], () => eventsService.getTodayEvents(babyId));
```

## Testing

### Unit Tests
- Test pure functions and utilities
- Mock external dependencies
- Focus on business logic

### Integration Tests
- Test service interactions
- Mock network requests
- Verify data flow

### E2E Tests
- Test complete user journeys
- Minimal mocking
- Focus on critical paths

## Performance

### React Optimization
```typescript
// Memoize expensive components
export const ExpensiveComponent = memo(function ExpensiveComponent({ data }) {
  return <div>{/* expensive render */}</div>;
});

// Memoize expensive calculations
const processedData = useMemo(() => expensiveCalculation(data), [data]);

// Memoize event handlers
const handleClick = useCallback(() => {
  doSomething(data);
}, [data]);
```

### Bundle Optimization
- Use dynamic imports for code splitting
- Lazy load routes and heavy components
- Minimize bundle size with tree shaking

## Code Style

### TypeScript
- Use strict mode
- Prefer interfaces over types for objects
- Use branded types for domain-specific strings
- Avoid `any` - use `unknown` if type is truly dynamic

### Naming
- **Variables**: camelCase (`userName`, `isLoading`)
- **Functions**: camelCase (`getUser`, `calculateTotal`)
- **Components**: PascalCase (`UserCard`, `EventList`)
- **Constants**: UPPER_SNAKE_CASE (`MAX_RETRY_ATTEMPTS`)

### Comments
```typescript
// Single line comments for implementation details

/**
 * Multi-line comments for complex logic
 * Explain why, not what
 */

// TODO: Implementation notes
// FIXME: Known issues
```

## Git Workflow

### Commit Messages
```
feat: add user authentication
fix: resolve login timeout issue
docs: update API documentation
refactor: extract validation utilities
test: add unit tests for user service
```

### Branch Naming
```
feature/user-authentication
bugfix/login-timeout
hotfix/critical-security-issue
```

## Deployment

### Environment Variables
- Use `.env.example` for required variables
- Never commit secrets
- Use environment-specific configs

### Build Process
- Run tests before deployment
- Lint and format code
- Generate build artifacts
- Deploy to staging first

## Security

### Input Validation
- Validate all user inputs
- Sanitize data before processing
- Use parameterized queries

### Authentication
- Store tokens securely
- Implement token refresh
- Handle session expiration

### Data Protection
- Encrypt sensitive data
- Implement proper access controls
- Follow privacy regulations
