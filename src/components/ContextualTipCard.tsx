import { useState } from 'react';
import { Card, CardContent } from '@/components/ui/card';
import { X, Lightbulb } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { ContextualTip } from '@/lib/contextualTips';

interface ContextualTipCardProps {
  tip: ContextualTip;
  onDismiss?: (tipId: string) => void;
}

export function ContextualTipCard({ tip, onDismiss }: ContextualTipCardProps) {
  const [isDismissed, setIsDismissed] = useState(false);

  if (isDismissed) return null;

  const handleDismiss = () => {
    setIsDismissed(true);
    if (onDismiss) {
      onDismiss(tip.id);
    }
  };

  return (
    <Card className="bg-primary/5 border-primary/20">
      <CardContent className="p-4">
        <div className="flex items-start gap-3">
          <div className="flex-shrink-0 mt-0.5">
            <Lightbulb className="w-5 h-5 text-primary" />
          </div>
          <div className="flex-1 min-w-0">
            <div className="flex items-start justify-between gap-2">
              <p className="text-sm text-foreground leading-relaxed">
                <span className="mr-2">{tip.icon}</span>
                {tip.content}
              </p>
              {onDismiss && (
                <Button
                  variant="ghost"
                  size="sm"
                  className="h-6 w-6 p-0 flex-shrink-0"
                  onClick={handleDismiss}
                >
                  <X className="h-4 w-4" />
                </Button>
              )}
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
