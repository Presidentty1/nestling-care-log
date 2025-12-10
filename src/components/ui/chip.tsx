import * as React from 'react';
import { cva, type VariantProps } from 'class-variance-authority';
import { cn } from '@/lib/utils';

const chipVariants = cva(
  'inline-flex items-center justify-center gap-1.5 rounded-sm px-3 py-1.5 text-caption font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2',
  {
    variants: {
      variant: {
        default: 'bg-primary/10 text-primary border border-primary/20',
        secondary: 'bg-secondary/10 text-secondary border border-secondary/20',
        success: 'bg-success/10 text-success border border-success/20',
        warning: 'bg-warning/10 text-warning-foreground border border-warning/20',
        destructive: 'bg-destructive/10 text-destructive border border-destructive/20',
        muted: 'bg-muted/30 text-muted-foreground border border-border',
        outline: 'border border-border text-foreground hover:bg-muted/30',
      },
      size: {
        sm: 'px-2 py-0.5 text-xs',
        md: 'px-3 py-1.5 text-caption',
        lg: 'px-4 py-2 text-body',
      },
    },
    defaultVariants: {
      variant: 'default',
      size: 'md',
    },
  }
);

export interface ChipProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof chipVariants> {
  removable?: boolean;
  onRemove?: () => void;
}

function Chip({ className, variant, size, removable, onRemove, children, ...props }: ChipProps) {
  return (
    <div className={cn(chipVariants({ variant, size }), className)} {...props}>
      {children}
      {removable && onRemove && (
        <button
          type='button'
          onClick={onRemove}
          className='ml-1 rounded-xs hover:bg-black/10 dark:hover:bg-white/10 p-0.5 transition-colors'
          aria-label='Remove'
        >
          <svg
            width='12'
            height='12'
            viewBox='0 0 12 12'
            fill='none'
            xmlns='http://www.w3.org/2000/svg'
          >
            <path
              d='M9 3L3 9M3 3L9 9'
              stroke='currentColor'
              strokeWidth='1.5'
              strokeLinecap='round'
              strokeLinejoin='round'
            />
          </svg>
        </button>
      )}
    </div>
  );
}

export { Chip, chipVariants };
