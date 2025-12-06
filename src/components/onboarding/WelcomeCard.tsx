import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Sparkles } from 'lucide-react';
import { MESSAGING } from '@/lib/messaging';
import type { EventType } from '@/types/events';

interface WelcomeCardProps {
  onLogFirstEvent: (type: EventType) => void;
}

export function WelcomeCard({ onLogFirstEvent }: WelcomeCardProps) {
  return (
    <Card className="border-2 border-primary/30 bg-gradient-to-br from-primary/5 to-primary/10 shadow-lg animate-fade-in">
      <CardContent className="p-6">
        <div className="flex items-start gap-4">
          <div className="w-14 h-14 rounded-xl bg-primary/20 flex items-center justify-center shrink-0">
            <Sparkles className="h-7 w-7 text-primary" />
          </div>
          <div className="flex-1">
            <h3 className="text-xl font-semibold mb-2">
              {MESSAGING.firstTime.welcome.title}
            </h3>
            <p className="text-sm text-muted-foreground mb-4">
              {MESSAGING.firstTime.welcome.subtitle}
            </p>
            <Button
              size="lg"
              onClick={() => onLogFirstEvent('feed')}
              className="w-full"
            >
              {MESSAGING.firstTime.welcome.cta}
            </Button>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

