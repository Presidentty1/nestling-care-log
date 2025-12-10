import { useState } from 'react';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Milk, Moon, Baby, Check, Sparkles } from 'lucide-react';
import { cn } from '@/lib/utils';

export function InteractiveLandingDemo() {
  const [selectedAction, setSelectedAction] = useState<string | null>(null);
  const [showPrediction, setShowPrediction] = useState(false);
  const [logs, setLogs] = useState<string[]>([]);

  const actions = [
    {
      id: 'feed',
      label: 'Feed',
      icon: Milk,
      color: 'text-event-feed',
      bgColor: 'bg-event-feed/10',
      borderColor: 'border-event-feed/30',
    },
    {
      id: 'sleep',
      label: 'Sleep',
      icon: Moon,
      color: 'text-event-sleep',
      bgColor: 'bg-event-sleep/10',
      borderColor: 'border-event-sleep/30',
    },
    {
      id: 'diaper',
      label: 'Diaper',
      icon: Baby,
      color: 'text-event-diaper',
      bgColor: 'bg-event-diaper/10',
      borderColor: 'border-event-diaper/30',
    },
  ];

  const handleActionClick = (actionId: string) => {
    setSelectedAction(actionId);
    setTimeout(() => {
      setLogs(prev => [...prev, actionId]);
      setShowPrediction(true);
      setTimeout(() => {
        setSelectedAction(null);
      }, 300);
    }, 500);
  };

  const handleReset = () => {
    setLogs([]);
    setShowPrediction(false);
    setSelectedAction(null);
  };

  return (
    <Card className='border-2 border-primary/20 overflow-hidden shadow-xl'>
      <CardContent className='p-6 bg-gradient-to-br from-background to-primary/5'>
        <div className='text-center mb-4'>
          <p className='text-sm font-medium text-muted-foreground mb-1'>
            Try it yourself - tap to log
          </p>
          <p className='text-xs text-muted-foreground'>See how fast it is</p>
        </div>

        {/* Quick Actions Demo */}
        <div className='grid grid-cols-3 gap-3 mb-4'>
          {actions.map(action => (
            <button
              key={action.id}
              onClick={() => handleActionClick(action.id)}
              disabled={selectedAction !== null}
              className={cn(
                'h-24 rounded-lg border-2 flex flex-col items-center justify-center gap-2 font-medium transition-all duration-300',
                selectedAction === action.id
                  ? `${action.borderColor} ${action.bgColor} scale-105`
                  : 'border-border hover:border-primary/30 hover:scale-105',
                selectedAction && selectedAction !== action.id && 'opacity-50'
              )}
            >
              <action.icon className={cn('h-6 w-6', action.color)} />
              <span className='text-sm'>{action.label}</span>
            </button>
          ))}
        </div>

        {/* Timeline Preview */}
        {logs.length > 0 && (
          <div className='mb-4 animate-fade-in'>
            <p className='text-xs text-muted-foreground mb-2'>Your timeline:</p>
            <div className='space-y-2'>
              {logs
                .slice(-3)
                .reverse()
                .map((log, index) => {
                  const action = actions.find(a => a.id === log);
                  return (
                    <div
                      key={index}
                      className='flex items-center gap-2 p-2 rounded-lg bg-surface border border-border animate-slide-in-up'
                    >
                      {action && <action.icon className={cn('h-4 w-4', action.color)} />}
                      <span className='text-sm capitalize'>{log}</span>
                      <span className='text-xs text-muted-foreground ml-auto'>Just now</span>
                      <Check className='h-4 w-4 text-primary' />
                    </div>
                  );
                })}
            </div>
          </div>
        )}

        {/* AI Prediction Preview */}
        {showPrediction && (
          <div className='p-4 rounded-lg bg-primary/10 border-2 border-primary/30 animate-scale-in'>
            <div className='flex items-start gap-3'>
              <div className='w-10 h-10 rounded-lg bg-primary/20 flex items-center justify-center shrink-0'>
                <Sparkles className='h-5 w-5 text-primary' />
              </div>
              <div className='flex-1 text-left'>
                <p className='text-sm font-semibold mb-1'>AI Prediction</p>
                <p className='text-xs text-muted-foreground'>
                  Next {logs[logs.length - 1]} in 2-3 hours
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Stats */}
        <div className='mt-4 pt-4 border-t border-border/50 flex items-center justify-between'>
          <div className='text-left'>
            <p className='text-xs text-muted-foreground'>Logs today</p>
            <p className='text-lg font-bold text-primary'>{logs.length}</p>
          </div>
          <Button variant='ghost' size='sm' onClick={handleReset} className='text-xs'>
            Reset Demo
          </Button>
        </div>

        <p className='text-xs text-center text-muted-foreground mt-4'>
          ⚡ That's it! Just tap and go. No complicated forms.
        </p>
      </CardContent>
    </Card>
  );
}
