import type { ReactNode } from 'react';
import React, { Component } from 'react';
import { ErrorState } from './common/ErrorState';
import { Button } from './ui/button';
import { AlertTriangle, Wifi, WifiOff, RefreshCw, Home } from 'lucide-react';
import { track } from '@/analytics/analytics';
import { useNetworkStatus } from '@/hooks/useNetworkStatus';

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
  onRetry?: () => void;
  onGoHome?: () => void;
  context?: string;
}

interface State {
  hasError: boolean;
  error?: Error;
  errorInfo?: React.ErrorInfo;
  retryCount: number;
  lastErrorTime?: Date;
}

export class ResilientErrorBoundary extends Component<Props, State> {
  private retryTimeoutId?: NodeJS.Timeout;
  private maxRetries = 3;
  private retryDelays = [1000, 2000, 5000]; // Progressive delays

  constructor(props: Props) {
    super(props);
    this.state = {
      hasError: false,
      retryCount: 0
    };
  }

  static getDerivedStateFromError(error: Error): Partial<State> {
    return {
      hasError: true,
      error,
      lastErrorTime: new Date()
    };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    this.setState({ errorInfo });

    // Track error in analytics
    track('error_boundary_caught', {
      error_message: error.message,
      error_stack: error.stack,
      component_stack: errorInfo.componentStack,
      context: this.props.context || 'unknown',
      retry_count: this.state.retryCount
    });

    console.error('Error boundary caught error:', error, errorInfo);
  }

  componentWillUnmount() {
    if (this.retryTimeoutId) {
      clearTimeout(this.retryTimeoutId);
    }
  }

  handleRetry = () => {
    const { retryCount } = this.state;
    const { onRetry } = this.props;

    if (retryCount >= this.maxRetries) {
      return;
    }

    // Increment retry count
    this.setState(prevState => ({
      retryCount: prevState.retryCount + 1
    }));

    // Call parent's retry handler
    if (onRetry) {
      const delay = this.retryDelays[retryCount] || 5000;
      this.retryTimeoutId = setTimeout(() => {
        onRetry();
        // Reset error state after retry
        this.setState({
          hasError: false,
          error: undefined,
          errorInfo: undefined
        });
      }, delay);
    }
  };

  handleReset = () => {
    this.setState({
      hasError: false,
      error: undefined,
      errorInfo: undefined,
      retryCount: 0
    });
  };

  render() {
    if (this.state.hasError) {
      const { error } = this.state;
      const { onGoHome, context } = this.props;

      // Custom fallback if provided
      if (this.props.fallback) {
        return this.props.fallback;
      }

      // Network-related errors
      if (error?.message.includes('network') || error?.message.includes('fetch')) {
        return (
          <div className="min-h-screen flex items-center justify-center p-4">
            <ErrorState
              title="Connection Problem"
              message="Unable to connect to our servers. Please check your internet connection and try again."
              onRetry={this.handleRetry}
              retrying={!!this.retryTimeoutId}
            />
          </div>
        );
      }

      // Authentication errors
      if (error?.message.includes('auth') || error?.message.includes('unauthorized')) {
        return (
          <div className="min-h-screen flex items-center justify-center p-4">
            <div className="max-w-md w-full">
              <ErrorState
                title="Authentication Required"
                message="Your session has expired. Please sign in again to continue."
              />
              <div className="mt-4 flex gap-2">
                <Button onClick={onGoHome} className="flex-1">
                  <Home className="mr-2 h-4 w-4" />
                  Go Home
                </Button>
              </div>
            </div>
          </div>
        );
      }

      // Default error with retry options
      const canRetry = this.state.retryCount < this.maxRetries;
      const isRetrying = !!this.retryTimeoutId;

      return (
        <div className="min-h-screen flex items-center justify-center p-4">
          <div className="max-w-md w-full">
            <ErrorState
              title="Something went wrong"
              message={`We encountered an unexpected error${context ? ` in ${context}` : ''}. ${canRetry ? 'Would you like us to try again?' : 'Please try refreshing the page.'}`}
              onRetry={canRetry ? this.handleRetry : undefined}
              retrying={isRetrying}
            />

            <div className="mt-4 flex gap-2">
              {canRetry && (
                <Button
                  variant="outline"
                  onClick={this.handleReset}
                  className="flex-1"
                >
                  <AlertTriangle className="mr-2 h-4 w-4" />
                  Dismiss
                </Button>
              )}

              {onGoHome && (
                <Button onClick={onGoHome} variant="outline" className="flex-1">
                  <Home className="mr-2 h-4 w-4" />
                  Go Home
                </Button>
              )}
            </div>

            {this.state.retryCount > 0 && (
              <p className="text-xs text-muted-foreground mt-2 text-center">
                Attempt {this.state.retryCount} of {this.maxRetries}
              </p>
            )}
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}

// Hook for using error boundary functionality in functional components
export function useErrorRecovery() {
  const isOnline = useNetworkStatus();

  const handleNetworkError = (error: Error, context: string) => {
    track('network_error_handled', {
      error_message: error.message,
      context,
      is_online: isOnline
    });

    if (!isOnline) {
      return {
        title: "You're offline",
        message: "This feature requires an internet connection. Your changes will be saved and synced when you're back online.",
        actionText: "Got it"
      };
    }

    return {
      title: "Connection issue",
      message: "Unable to connect right now. Please check your internet and try again.",
      actionText: "Retry"
    };
  };

  return { handleNetworkError };
}

