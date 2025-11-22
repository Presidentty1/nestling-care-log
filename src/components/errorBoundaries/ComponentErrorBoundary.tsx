import type { ReactNode } from 'react';
import React from 'react';
import { ResilientErrorBoundary } from '../ResilientErrorBoundary';

interface ComponentErrorBoundaryProps {
  children: ReactNode;
  componentName: string;
  fallback?: ReactNode;
  onRetry?: () => void;
}

/**
 * Error boundary for individual components within pages
 * Provides component-level error isolation without breaking the entire page
 */
export function ComponentErrorBoundary({
  children,
  componentName,
  fallback,
  onRetry
}: ComponentErrorBoundaryProps) {
  return (
    <ResilientErrorBoundary
      context={`component-${componentName}`}
      fallback={fallback}
      onRetry={onRetry}
    >
      {children}
    </ResilientErrorBoundary>
  );
}

/**
 * Lightweight error boundary for non-critical UI components
 * Shows a minimal error state instead of breaking the page
 */
export function SafeComponentBoundary({
  children,
  componentName,
  fallback
}: {
  children: ReactNode;
  componentName: string;
  fallback?: ReactNode;
}) {
  const defaultFallback = (
    <div className="p-2 border border-destructive/20 rounded bg-destructive/5">
      <p className="text-xs text-destructive">
        Component "{componentName}" failed to load
      </p>
    </div>
  );

  return (
    <ComponentErrorBoundary
      componentName={componentName}
      fallback={fallback || defaultFallback}
    >
      {children}
    </ComponentErrorBoundary>
  );
}

/**
 * Error boundary specifically for data display components
 * Handles cases where data fetching fails but shows partial content
 */
export function DataComponentBoundary({
  children,
  componentName,
  onRetry,
  showPartialData = true
}: {
  children: ReactNode;
  componentName: string;
  onRetry?: () => void;
  showPartialData?: boolean;
}) {
  const fallback = (
    <div className="p-4 border border-warning/20 rounded bg-warning/5">
      <div className="flex items-center gap-2">
        <div className="w-2 h-2 bg-warning rounded-full animate-pulse" />
        <p className="text-sm text-warning">
          Unable to load {componentName}
        </p>
      </div>
      {onRetry && (
        <button
          onClick={onRetry}
          className="mt-2 text-xs text-primary hover:underline"
        >
          Try again
        </button>
      )}
    </div>
  );

  return (
    <ComponentErrorBoundary
      componentName={componentName}
      fallback={showPartialData ? null : fallback}
      onRetry={onRetry}
    >
      {children}
    </ComponentErrorBoundary>
  );
}
