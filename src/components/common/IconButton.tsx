import { Button } from '@/components/ui/button';
import type { LucideIcon } from 'lucide-react';
import { forwardRef } from 'react';

interface IconButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  icon: LucideIcon;
  label: string;
  variant?: 'default' | 'ghost' | 'outline' | 'secondary' | 'destructive' | 'link';
  size?: 'default' | 'sm' | 'lg' | 'icon';
}

export const IconButton = forwardRef<HTMLButtonElement, IconButtonProps>(
  ({ icon: Icon, label, variant = 'ghost', size = 'icon', className, ...props }, ref) => {
    return (
      <Button
        ref={ref}
        variant={variant}
        size={size}
        aria-label={label}
        className={`min-w-[44px] min-h-[44px] ${className || ''}`}
        {...props}
      >
        <Icon className='h-5 w-5' />
      </Button>
    );
  }
);

IconButton.displayName = 'IconButton';
