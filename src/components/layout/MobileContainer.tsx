import type { ReactNode } from 'react';
import { cn } from '@/lib/utils';

interface MobileContainerProps {
  children: ReactNode;
  className?: string;
  noPadding?: boolean;
  noBottomPadding?: boolean;
}

/**
 * Standard mobile container with safe areas, max-width, and consistent padding
 * Use this as the root container for all page content
 */
export function MobileContainer({ 
  children, 
  className,
  noPadding = false,
  noBottomPadding = false 
}: MobileContainerProps) {
  return (
    <div 
      className={cn(
        "min-h-screen bg-background",
        !noBottomPadding && "pb-20", // Space for mobile nav
        "safe-area-inset-bottom",
        className
      )}
    >
      <div 
        className={cn(
          "max-w-2xl mx-auto",
          !noPadding && "p-4"
        )}
      >
        {children}
      </div>
    </div>
  );
}
