import { QueryClient, focusManager, onlineManager } from '@tanstack/react-query';
import { track } from '@/analytics/analytics';

// Performance-optimized QueryClient configuration
export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 5, // 5 minutes - reduce refetches
      gcTime: 1000 * 60 * 30, // 30 minutes - balance memory usage
      retry: (failureCount, error: any) => {
        // Don't retry on 4xx errors (client errors)
        if (error?.status >= 400 && error?.status < 500) {
          return false;
        }
        // Retry up to 3 times for network/server errors
        return failureCount < 3;
      },
      retryDelay: (attemptIndex) => Math.min(1000 * 2 ** attemptIndex, 30000),
      refetchOnWindowFocus: false, // Disable to improve performance
      refetchOnReconnect: true,
      refetchOnMount: true,
      networkMode: 'offlineFirst', // Enable offline support
    },
    mutations: {
      retry: (failureCount, error: any) => {
        // Don't retry mutations on client errors
        if (error?.status >= 400 && error?.status < 500) {
          return false;
        }
        return failureCount < 2;
      },
      retryDelay: 1000,
      networkMode: 'offlineFirst',
    },
  },
});

// Performance monitoring
if (typeof window !== 'undefined') {
  // Track query cache size for monitoring
  let cacheSize = 0;
  const CACHE_KEY = 'nestling-react-query-cache';

  // Monitor cache size changes
  const updateCacheSize = () => {
    const cache = queryClient.getQueryCache().getAll();
    const newSize = JSON.stringify(cache).length;
    if (Math.abs(newSize - cacheSize) > 10000) { // Only track significant changes
      cacheSize = newSize;
      track('cache_size_change', {
        size_kb: Math.round(newSize / 1024),
        query_count: cache.length
      });
    }
  };

  // Load persisted cache on init (but limit size)
  const persistedCache = localStorage.getItem(CACHE_KEY);
  if (persistedCache) {
    try {
      const parsed = JSON.parse(persistedCache);
      // Only restore cache if it's not too old (24 hours) and reasonable size
      const cacheAge = Date.now() - (parsed.timestamp || 0);
      const cacheSize = JSON.stringify(parsed).length;

      if (cacheAge < 24 * 60 * 60 * 1000 && cacheSize < 5 * 1024 * 1024) { // 24h, 5MB
        queryClient.setQueryData(['cached'], parsed);
        console.log('Restored query cache:', Math.round(cacheSize / 1024), 'KB');
      } else {
        localStorage.removeItem(CACHE_KEY);
      }
    } catch (e) {
      console.error('Failed to load query cache:', e);
      localStorage.removeItem(CACHE_KEY);
    }
  }

  // Persist cache on changes (debounced)
  let saveTimeout: NodeJS.Timeout;
  const saveCache = () => {
    clearTimeout(saveTimeout);
    saveTimeout = setTimeout(() => {
      try {
        const cache = queryClient.getQueryCache().getAll();
        const cacheData = {
          timestamp: Date.now(),
          data: cache
        };
        localStorage.setItem(CACHE_KEY, JSON.stringify(cacheData));
        updateCacheSize();
      } catch (e) {
        console.warn('Failed to save query cache:', e);
      }
    }, 1000); // Debounce saves
  };

  // Listen to cache changes
  queryClient.getQueryCache().subscribe(saveCache);

  // Clean up old cache on app start
  setTimeout(() => {
    const oldCache = localStorage.getItem(CACHE_KEY);
    if (oldCache) {
      try {
        const parsed = JSON.parse(oldCache);
        const age = Date.now() - (parsed.timestamp || 0);
        if (age > 7 * 24 * 60 * 60 * 1000) { // 7 days
          localStorage.removeItem(CACHE_KEY);
          console.log('Cleaned up old cache');
        }
      } catch (e) {
        localStorage.removeItem(CACHE_KEY);
      }
    }
  }, 5000); // Wait for app to stabilize
}

// Configure focus and online managers for better performance
if (typeof window !== 'undefined') {
  // Only refetch on window focus if app was hidden for more than 5 minutes
  let lastHiddenTime = 0;
  focusManager.setEventListener((onFocus) => {
    const cleanup = onFocus(() => {
      const now = Date.now();
      const timeSinceHidden = now - lastHiddenTime;
      if (timeSinceHidden > 5 * 60 * 1000) { // 5 minutes
        queryClient.invalidateQueries();
      }
    });

    return () => {
      window.addEventListener('visibilitychange', () => {
        if (document.hidden) {
          lastHiddenTime = Date.now();
        }
      });
      cleanup();
    };
  });

  // Custom online manager for better offline detection
  onlineManager.setEventListener((setOnline) => {
    const cleanup = () => {
      window.addEventListener('online', () => setOnline(true));
      window.addEventListener('offline', () => setOnline(false));
    };
    cleanup();

    return () => {
      window.removeEventListener('online', () => setOnline(true));
      window.removeEventListener('offline', () => setOnline(false));
    };
  });
}
