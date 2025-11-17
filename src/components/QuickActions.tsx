import { Button } from '@/components/ui/button';
import { Milk, Moon, Baby, Clock } from 'lucide-react';
import { EventType } from '@/types/events';
import { formatDistanceToNow } from 'date-fns';
import { EventRecord } from '@/services/eventsService';

interface QuickActionsProps {
  onActionSelect: (type: EventType) => void;
  onQuickLog?: (type: EventType) => void;
  recentEvents?: EventRecord[];
}

export function QuickActions({ onActionSelect, onQuickLog, recentEvents = [] }: QuickActionsProps) {
  const actions = [
    { type: 'feed' as EventType, label: 'Feed', icon: Milk },
    { type: 'sleep' as EventType, label: 'Sleep', icon: Moon },
    { type: 'diaper' as EventType, label: 'Diaper', icon: Baby },
    { type: 'tummy_time' as EventType, label: 'Tummy', icon: Clock },
  ];

  const getTimeSince = (type: EventType): string => {
    const lastEvent = recentEvents.find(e => e.type === type);
    if (!lastEvent) return '—';
    
    const eventTime = lastEvent.end_time || lastEvent.start_time;
    return formatDistanceToNow(new Date(eventTime), { addSuffix: true });
  };

  const handleClick = (type: EventType) => {
    if (onQuickLog) {
      onQuickLog(type);
    } else {
      onActionSelect(type);
    }
  };

  const handleLongPress = (type: EventType) => {
    onActionSelect(type);
  };

  return (
    <div className="grid grid-cols-2 gap-4">
      {actions.map((action) => (
        <Button
          key={action.type}
          onClick={() => handleClick(action.type)}
          onContextMenu={(e) => {
            e.preventDefault();
            handleLongPress(action.type);
          }}
          variant="outline"
          className="h-[112px] flex flex-col items-center justify-center gap-2 rounded-md border-2 hover:bg-primary/5 hover:border-primary active:scale-[0.98] transition-all duration-100"
          style={{ minHeight: '44px', minWidth: '44px' }}
        >
          <action.icon className="h-8 w-8 text-primary" strokeWidth={2} />
          <span className="text-[15px] leading-[20px] font-medium">{action.label}</span>
          <span className="text-xs text-muted-foreground">{getTimeSince(action.type)}</span>
        </Button>
      ))}
    </div>
  );
}
