# ADR 002: React Query for State Management

## Status
Accepted

## Context
The React web application needed an effective way to manage server state, caching, and synchronization. Traditional state management solutions like Redux were considered, but the app's needs were more focused on server state than complex client-side state.

## Decision
We chose React Query (TanStack Query) for managing server state and API interactions in the React application.

## Rationale
- **Server State Focus**: React Query excels at managing asynchronous server state, caching, and synchronization
- **Automatic Caching**: Built-in intelligent caching with stale-while-revalidate strategy
- **Background Updates**: Automatic refetching when data becomes stale or on window focus
- **Error Handling**: Robust error handling with retry logic and error boundaries integration
- **Developer Experience**: Simple API with hooks that integrate seamlessly with React
- **Performance**: Optimistic updates and background synchronization improve perceived performance
- **Type Safety**: Full TypeScript support with proper typing for queries and mutations

## Consequences
- **Positive**:
  - Simplified state management for server data
  - Automatic caching and synchronization
  - Better user experience with loading states and error handling
  - Reduced boilerplate compared to Redux for server state

- **Negative**:
  - Learning curve for developers unfamiliar with React Query
  - Additional dependency that needs maintenance
  - Not suitable for complex client-side state logic

## Implementation
- All API calls go through React Query hooks (`useQuery`, `useMutation`)
- Custom hooks wrap React Query for specific data operations
- Error boundaries catch and display query errors
- Loading states are handled at component level with React Query's `isLoading` states
- Cache invalidation is handled through query keys and invalidation strategies

## Alternatives Considered
- **Redux Toolkit**: Too complex for primarily server state management
- **Zustand**: Good alternative, but React Query's server state features were more compelling
- **SWR**: Similar to React Query, but React Query had better TypeScript support and feature set
- **Apollo Client**: Overkill since we're not using GraphQL

## Related Decisions
- ADR 001: MVVM Pattern for SwiftUI Architecture
- ADR 003: Offline-First Architecture
- ADR 005: Cross-Platform Consistency Patterns
