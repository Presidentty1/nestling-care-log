import { ReactNode } from 'react';

/**
 * Common UI utilities and patterns
 */

export interface LoadingState {
  isLoading: boolean;
  error?: string | null;
  data?: any;
}

export const uiUtils = {
  /**
   * Standard loading spinner component
   */
  LoadingSpinner: ({ size = 'md', className = '' }: { size?: 'sm' | 'md' | 'lg'; className?: string }) => {
    const sizeClasses = {
      sm: 'h-4 w-4',
      md: 'h-6 w-6',
      lg: 'h-8 w-8'
    };

    return (
      <div className={`animate-spin rounded-full border-2 border-gray-300 border-t-primary ${sizeClasses[size]} ${className}`} />
    );
  },

  /**
   * Standard empty state component
   */
  EmptyState: ({
    icon,
    title,
    description,
    action
  }: {
    icon?: ReactNode;
    title: string;
    description?: string;
    action?: ReactNode;
  }) => (
    <div className="flex flex-col items-center justify-center py-12 px-4 text-center">
      {icon && <div className="mb-4 text-muted-foreground">{icon}</div>}
      <h3 className="text-lg font-semibold text-foreground mb-2">{title}</h3>
      {description && (
        <p className="text-sm text-muted-foreground mb-6 max-w-md">{description}</p>
      )}
      {action && <div>{action}</div>}
    </div>
  ),

  /**
   * Standard error state component
   */
  ErrorState: ({
    title = 'Something went wrong',
    message,
    onRetry,
    retrying = false
  }: {
    title?: string;
    message: string;
    onRetry?: () => void;
    retrying?: boolean;
  }) => (
    <div className="flex flex-col items-center justify-center py-12 px-4 text-center">
      <div className="mb-4 text-destructive">
        <svg className="h-12 w-12" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.082 16.5c-.77.833.192 2.5 1.732 2.5z" />
        </svg>
      </div>
      <h3 className="text-lg font-semibold text-foreground mb-2">{title}</h3>
      <p className="text-sm text-muted-foreground mb-6 max-w-md">{message}</p>
      {onRetry && (
        <button
          onClick={onRetry}
          disabled={retrying}
          className="px-4 py-2 bg-primary text-primary-foreground rounded-md hover:bg-primary/90 disabled:opacity-50"
        >
          {retrying ? 'Retrying...' : 'Try Again'}
        </button>
      )}
    </div>
  ),

  /**
   * Standard success state component
   */
  SuccessState: ({
    icon,
    title,
    message,
    action
  }: {
    icon?: ReactNode;
    title: string;
    message?: string;
    action?: ReactNode;
  }) => (
    <div className="flex flex-col items-center justify-center py-12 px-4 text-center">
      {icon && <div className="mb-4 text-green-500">{icon}</div>}
      <h3 className="text-lg font-semibold text-foreground mb-2">{title}</h3>
      {message && (
        <p className="text-sm text-muted-foreground mb-6 max-w-md">{message}</p>
      )}
      {action && <div>{action}</div>}
    </div>
  ),

  /**
   * Button variant utilities
   */
  buttonVariants: {
    primary: 'bg-primary text-primary-foreground hover:bg-primary/90',
    secondary: 'bg-secondary text-secondary-foreground hover:bg-secondary/80',
    outline: 'border border-input bg-background hover:bg-accent hover:text-accent-foreground',
    ghost: 'hover:bg-accent hover:text-accent-foreground',
    link: 'text-primary underline-offset-4 hover:underline',
    destructive: 'bg-destructive text-destructive-foreground hover:bg-destructive/90'
  },

  /**
   * Common input styles
   */
  inputStyles: {
    base: 'flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50',
    error: 'border-destructive focus-visible:ring-destructive'
  },

  /**
   * Format number with appropriate units
   */
  formatAmount: (amount: number, unit: string = 'ml'): string => {
    if (unit === 'oz') {
      return `${(amount / 29.5735).toFixed(1)} oz`;
    }
    return `${amount} ml`;
  },

  /**
   * Format duration in human readable format
   */
  formatDuration: (minutes: number): string => {
    if (minutes < 60) {
      return `${minutes}m`;
    }

    const hours = Math.floor(minutes / 60);
    const remainingMinutes = minutes % 60;

    if (remainingMinutes === 0) {
      return `${hours}h`;
    }

    return `${hours}h ${remainingMinutes}m`;
  },

  /**
   * Get appropriate color for event type
   */
  getEventTypeColor: (type: string): string => {
    const colors = {
      feed: 'bg-blue-100 text-blue-800 border-blue-200',
      sleep: 'bg-purple-100 text-purple-800 border-purple-200',
      diaper: 'bg-green-100 text-green-800 border-green-200',
      tummy_time: 'bg-orange-100 text-orange-800 border-orange-200'
    };
    return colors[type as keyof typeof colors] || 'bg-gray-100 text-gray-800 border-gray-200';
  },

  /**
   * Truncate text with ellipsis
   */
  truncate: (text: string, maxLength: number): string => {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength - 3) + '...';
  }
};




