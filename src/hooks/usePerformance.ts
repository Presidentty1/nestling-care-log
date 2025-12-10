import { useEffect, useRef, useCallback } from 'react';
import { track } from '@/analytics/analytics';

interface PerformanceMetrics {
  renderCount: number;
  averageRenderTime: number;
  totalRenderTime: number;
  lastRenderTime: number;
  memoryUsage?: number;
}

/**
 * Enhanced performance monitoring hook
 */
export function usePerformance(componentName: string, trackMetrics = false) {
  const renderCount = useRef(0);
  const renderTimes = useRef<number[]>([]);
  const lastRenderTime = useRef(Date.now());
  const startTime = useRef(performance.now());

  useEffect(() => {
    const now = performance.now();
    const renderTime = now - startTime.current;
    startTime.current = now;

    renderCount.current += 1;
    renderTimes.current.push(renderTime);

    // Keep only last 10 render times for memory efficiency
    if (renderTimes.current.length > 10) {
      renderTimes.current.shift();
    }

    // Track performance metrics if enabled and component is slow
    if (trackMetrics && renderTime > 16) {
      // 16ms = 60fps
      track('component_slow_render', {
        component: componentName,
        render_time: Math.round(renderTime),
        render_count: renderCount.current,
      });
    }

    if (renderTime > 16) {
      // More than one frame (16ms at 60fps)
      console.warn(`[Performance] ${componentName} render took ${renderTime.toFixed(2)}ms`);
    }
  });

  // Memory usage tracking (if available)
  const getMemoryUsage = useCallback(() => {
    if ('memory' in performance) {
      const memory = (performance as any).memory;
      return {
        used: memory.usedJSHeapSize,
        total: memory.totalJSHeapSize,
        limit: memory.jsHeapSizeLimit,
      };
    }
    return null;
  }, []);

  const getMetrics = useCallback((): PerformanceMetrics => {
    const totalTime = renderTimes.current.reduce((a, b) => a + b, 0);
    const averageTime = renderTimes.current.length > 0 ? totalTime / renderTimes.current.length : 0;
    const memoryUsage = getMemoryUsage();

    return {
      renderCount: renderCount.current,
      averageRenderTime: averageTime,
      totalRenderTime: totalTime,
      lastRenderTime: renderTimes.current[renderTimes.current.length - 1] || 0,
      memoryUsage: memoryUsage?.used,
    };
  }, [getMemoryUsage]);

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      if (trackMetrics && renderCount.current > 0) {
        const metrics = getMetrics();
        track('component_unmount', {
          component: componentName,
          total_renders: metrics.renderCount,
          avg_render_time: Math.round(metrics.averageRenderTime),
        });
      }
    };
  }, [componentName, trackMetrics, getMetrics]);

  return {
    renderCount: renderCount.current,
    getMetrics,
    getMemoryUsage,
  };
}

/**
 * Performance monitoring for route changes
 */
export function useRoutePerformance(routeName: string) {
  const startTime = useRef(performance.now());
  const interactionCount = useRef(0);

  useEffect(() => {
    startTime.current = performance.now();
    interactionCount.current = 0;

    // Track route view performance
    const trackRoutePerformance = () => {
      const loadTime = performance.now() - startTime.current;
      track('route_performance', {
        route: routeName,
        load_time: Math.round(loadTime),
        interactions: interactionCount.current,
      });
    };

    // Track on route change or unmount
    const handleVisibilityChange = () => {
      if (document.hidden) {
        trackRoutePerformance();
      }
    };

    document.addEventListener('visibilitychange', handleVisibilityChange);

    return () => {
      document.removeEventListener('visibilitychange', handleVisibilityChange);
      trackRoutePerformance();
    };
  }, [routeName]);

  const trackInteraction = useCallback(() => {
    interactionCount.current += 1;
  }, []);

  return { trackInteraction };
}

/**
 * Memory leak detection
 */
export function useMemoryLeakDetection(componentName: string) {
  const renderCount = useRef(0);
  const warningThreshold = 50; // Warn after 50 renders without cleanup

  useEffect(() => {
    renderCount.current += 1;

    if (renderCount.current > warningThreshold) {
      console.warn(
        `${componentName} has rendered ${renderCount.current} times. Possible memory leak.`
      );
      track('potential_memory_leak', {
        component: componentName,
        render_count: renderCount.current,
      });
    }
  });

  return renderCount.current;
}

/**
 * Enhanced Web Vitals reporting with analytics tracking
 */
export function reportWebVitals() {
  if (typeof window !== 'undefined' && 'PerformanceObserver' in window) {
    // Largest Contentful Paint
    const lcpObserver = new PerformanceObserver(list => {
      const entries = list.getEntries();
      const lastEntry = entries[entries.length - 1];
      const lcp = lastEntry.startTime;

      track('web_vitals_lcp', {
        value: Math.round(lcp),
        rating: lcp > 4000 ? 'poor' : lcp > 2500 ? 'needs-improvement' : 'good',
      });

      console.log('[WebVitals] LCP:', lcp.toFixed(2), 'ms');
    });

    try {
      lcpObserver.observe({ entryTypes: ['largest-contentful-paint'] });
    } catch (e) {
      // Ignore if not supported
    }

    // First Input Delay
    const fidObserver = new PerformanceObserver(list => {
      const entries = list.getEntries();
      entries.forEach((entry: any) => {
        const fid = entry.processingStart - entry.startTime;

        track('web_vitals_fid', {
          value: Math.round(fid),
          rating: fid > 300 ? 'poor' : fid > 100 ? 'needs-improvement' : 'good',
        });

        console.log('[WebVitals] FID:', fid.toFixed(2), 'ms');
      });
    });

    try {
      fidObserver.observe({ entryTypes: ['first-input'] });
    } catch (e) {
      // Ignore if not supported
    }

    // Cumulative Layout Shift
    let clsValue = 0;
    const clsObserver = new PerformanceObserver(list => {
      for (const entry of list.getEntries() as any[]) {
        if (!entry.hadRecentInput) {
          clsValue += entry.value;
        }
      }

      track('web_vitals_cls', {
        value: Math.round(clsValue * 1000) / 1000, // Round to 3 decimal places
        rating: clsValue > 0.25 ? 'poor' : clsValue > 0.1 ? 'needs-improvement' : 'good',
      });

      console.log('[WebVitals] CLS:', clsValue.toFixed(4));
    });

    try {
      clsObserver.observe({ entryTypes: ['layout-shift'] });
    } catch (e) {
      // Ignore if not supported
    }
  }
}
