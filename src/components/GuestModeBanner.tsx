import { useNavigate } from 'react-router-dom';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Button } from '@/components/ui/button';
import { Cloud, X } from 'lucide-react';
import { useState } from 'react';

export function GuestModeBanner() {
  const navigate = useNavigate();
  const [dismissed, setDismissed] = useState(false);

  if (dismissed) return null;

  return (
    <Alert className="border-primary/50 bg-primary/5 relative">
      <button
        onClick={() => setDismissed(true)}
        className="absolute top-2 right-2 p-1 hover:bg-background/50 rounded transition-colors"
        aria-label="Dismiss"
      >
        <X className="h-4 w-4" />
      </button>
      <Cloud className="h-4 w-4 text-primary" />
      <AlertDescription className="flex items-center justify-between gap-4 pr-8">
        <span className="text-sm">
          Sign up to sync your data across devices and unlock AI features
        </span>
        <Button 
          size="sm" 
          onClick={() => navigate('/auth')}
          className="shrink-0"
        >
          Sign Up
        </Button>
      </AlertDescription>
    </Alert>
  );
}
