import type { ReactNode } from 'react';
import { Component } from 'react';
import { Button } from '@/components/ui/button';
import { AlertTriangle } from 'lucide-react';

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
}

export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error('ErrorBoundary caught:', error, errorInfo);
  }

  handleReset = () => {
    this.setState({ hasError: false, error: null });
    window.location.href = '/home';
  };

  render() {
    if (this.state.hasError) {
      return (
        this.props.fallback || (
          <div className='min-h-screen flex items-center justify-center p-4 bg-background'>
            <div className='text-center max-w-md'>
              <AlertTriangle className='w-16 h-16 mx-auto mb-4 text-destructive' />
              <h1 className='text-2xl font-bold mb-2'>Oops! Something went wrong</h1>
              <p className='text-muted-foreground mb-6'>
                Don't worry — your baby's logs are safe. Try refreshing the page.
              </p>
              <div className='space-y-2'>
                <Button onClick={this.handleReset} className='w-full'>
                  Return to Home
                </Button>
                <Button
                  variant='outline'
                  onClick={() => window.location.reload()}
                  className='w-full'
                >
                  Refresh Page
                </Button>
              </div>
              {import.meta.env.DEV && this.state.error && (
                <pre className='mt-4 p-4 bg-muted rounded text-xs text-left overflow-auto max-h-40'>
                  {this.state.error.toString()}
                </pre>
              )}
            </div>
          </div>
        )
      );
    }

    return this.props.children;
  }
}
