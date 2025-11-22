/**
 * Centralized logging service for Nestling
 * Provides structured logging with different levels and conditional output based on environment
 */

export enum LogLevel {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3,
}

interface LogEntry {
  level: LogLevel;
  message: string;
  data?: any;
  timestamp: Date;
  context?: string;
}

class Logger {
  private minLevel: LogLevel;

  constructor() {
    // In production, only show warnings and errors
    // In development, show all levels
    this.minLevel = process.env.NODE_ENV === 'production' ? LogLevel.WARN : LogLevel.DEBUG;
  }

  private shouldLog(level: LogLevel): boolean {
    return level >= this.minLevel;
  }

  private formatMessage(level: LogLevel, message: string, data?: any, context?: string): string {
    const levelName = LogLevel[level].padEnd(5);
    const contextStr = context ? `[${context}] ` : '';
    const timestamp = new Date().toISOString();
    return `${timestamp} ${levelName} ${contextStr}${message}`;
  }

  private log(level: LogLevel, message: string, data?: any, context?: string): void {
    if (!this.shouldLog(level)) return;

    const formattedMessage = this.formatMessage(level, message, data, context);

    switch (level) {
      case LogLevel.DEBUG:
        console.debug(formattedMessage, data || '');
        break;
      case LogLevel.INFO:
        console.info(formattedMessage, data || '');
        break;
      case LogLevel.WARN:
        console.warn(formattedMessage, data || '');
        break;
      case LogLevel.ERROR:
        console.error(formattedMessage, data || '');
        // Send to Sentry in production
        if (process.env.NODE_ENV === 'production' && typeof window !== 'undefined') {
          import('@sentry/react').then(({ captureException, captureMessage }) => {
            if (data instanceof Error) {
              captureException(data);
            } else {
              captureMessage(message, 'error');
            }
          }).catch(() => {
            // Sentry not available, continue with console logging
          });
        }
        break;
    }
  }

  debug(message: string, data?: any, context?: string): void {
    this.log(LogLevel.DEBUG, message, data, context);
  }

  info(message: string, data?: any, context?: string): void {
    this.log(LogLevel.INFO, message, data, context);
  }

  warn(message: string, data?: any, context?: string): void {
    this.log(LogLevel.WARN, message, data, context);
  }

  error(message: string, error?: Error | any, context?: string): void {
    this.log(LogLevel.ERROR, message, error, context);
  }

  // Convenience methods for specific contexts
  api(message: string, data?: any): void {
    this.log(LogLevel.INFO, message, data, 'API');
  }

  auth(message: string, data?: any): void {
    this.log(LogLevel.INFO, message, data, 'AUTH');
  }

  data(message: string, data?: any): void {
    this.log(LogLevel.DEBUG, message, data, 'DATA');
  }

  ui(message: string, data?: any): void {
    this.log(LogLevel.DEBUG, message, data, 'UI');
  }
}

// Export singleton instance
export const logger = new Logger();

// Export for testing
export { Logger };
