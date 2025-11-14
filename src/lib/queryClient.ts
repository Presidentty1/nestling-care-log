import { QueryClient } from '@tanstack/react-query';

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 5, // 5 minutes
      gcTime: 1000 * 60 * 60 * 24, // 24 hours
      retry: 3,
      refetchOnWindowFocus: true,
      refetchOnReconnect: true,
    },
    mutations: {
      retry: 2,
      retryDelay: 1000,
    },
  },
});

// Store query cache in localStorage for offline support
if (typeof window !== 'undefined') {
  const CACHE_KEY = 'nestling-react-query-cache';
  
  // Load persisted cache on init
  const persistedCache = localStorage.getItem(CACHE_KEY);
  if (persistedCache) {
    try {
      const parsed = JSON.parse(persistedCache);
      queryClient.setQueryData(['cached'], parsed);
    } catch (e) {
      console.error('Failed to load query cache:', e);
    }
  }
  
  // Persist cache on changes
  window.addEventListener('beforeunload', () => {
    const cache = queryClient.getQueryCache().getAll();
    localStorage.setItem(CACHE_KEY, JSON.stringify(cache));
  });
}
