import type { ReactNode } from 'react';
import React from 'react';
import { ResilientErrorBoundary } from '../ResilientErrorBoundary';

interface RouteErrorBoundaryProps {
  children: ReactNode;
  routeName: string;
  onGoHome?: () => void;
}

/**
 * Error boundary specifically for route groups with route-specific error handling
 */
export function RouteErrorBoundary({ children, routeName, onGoHome }: RouteErrorBoundaryProps) {
  return (
    <ResilientErrorBoundary
      context={`route-${routeName}`}
      onGoHome={onGoHome}
    >
      {children}
    </ResilientErrorBoundary>
  );
}

/**
 * Error boundary for settings routes
 */
export function SettingsErrorBoundary({ children, onGoHome }: { children: ReactNode; onGoHome?: () => void }) {
  return (
    <RouteErrorBoundary routeName="settings" onGoHome={onGoHome}>
      {children}
    </RouteErrorBoundary>
  );
}

/**
 * Error boundary for main app routes (home, history, etc.)
 */
export function MainAppErrorBoundary({ children, onGoHome }: { children: ReactNode; onGoHome?: () => void }) {
  return (
    <RouteErrorBoundary routeName="main-app" onGoHome={onGoHome}>
      {children}
    </RouteErrorBoundary>
  );
}

/**
 * Error boundary for feature routes (labs, analytics, etc.)
 */
export function FeatureErrorBoundary({ children, onGoHome }: { children: ReactNode; onGoHome?: () => void }) {
  return (
    <RouteErrorBoundary routeName="features" onGoHome={onGoHome}>
      {children}
    </RouteErrorBoundary>
  );
}

/**
 * Error boundary for onboarding flow
 */
export function OnboardingErrorBoundary({ children, onGoHome }: { children: ReactNode; onGoHome?: () => void }) {
  return (
    <RouteErrorBoundary routeName="onboarding" onGoHome={onGoHome}>
      {children}
    </RouteErrorBoundary>
  );
}




