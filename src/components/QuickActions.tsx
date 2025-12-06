import { Button } from '@/components/ui/button';
import { Milk, Moon, Baby, Clock } from 'lucide-react';
import type { EventType } from '@/types/events';
import { formatDistanceToNow } from 'date-fns';
import type { EventRecord } from '@/services/eventsService';
import { useState, useRef, useEffect } from 'react';
import { track } from '@/analytics/analytics';
import { getPressEffect } from '@/lib/animations';

interface QuickActionsProps {
  onActionSelect: (type: EventType) => void;
  onQuickLog?: (type: EventType) => void;
  recentEvents?: EventRecord[];
}

export function QuickActions({ onActionSelect, onQuickLog, recentEvents = [] }: QuickActionsProps) {
  const [longPressType, setLongPressType] = useState<EventType | null>(null);
  const longPressTimerRef = useRef<NodeJS.Timeout | null>(null);

  const actions = [
    { type: 'feed' as EventType, label: 'Feed', icon: Milk, color: 'text-event-feed', borderColor: 'border-event-feed/20', bgColor: 'bg-event-feed/5' },
    { type: 'sleep' as EventType, label: 'Sleep', icon: Moon, color: 'text-event-sleep', borderColor: 'border-event-sleep/20', bgColor: 'bg-event-sleep/5' },
    { type: 'diaper' as EventType, label: 'Diaper', icon: Baby, color: 'text-event-diaper', borderColor: 'border-event-diaper/20', bgColor: 'bg-event-diaper/5' },
    { type: 'tummy_time' as EventType, label: 'Tummy', icon: Clock, color: 'text-event-tummy', borderColor: 'border-event-tummy/20', bgColor: 'bg-event-tummy/5' },
  ];

  const getTimeSince = (type: EventType): string => {
    const lastEvent = recentEvents.find(e => e.type === type);
    if (!lastEvent) return '—';
    
    const eventTime = lastEvent.end_time || lastEvent.start_time;
    return formatDistanceToNow(new Date(eventTime), { addSuffix: true });
  };

  const handleClick = (type: EventType) => {
    try {
      // Track analytics
      track('quick_action_used', {
        action_type: type,
        method: onQuickLog ? 'quick_log' : 'open_form'
      });
      
      if (onQuickLog) {
        onQuickLog(type);
      } else {
        onActionSelect(type);
      }
    } catch (error) {
      console.error('Quick action error:', error);
      // Fallback to opening the form
      onActionSelect(type);
    }
  };

  const handleLongPress = (type: EventType) => {
    onActionSelect(type);
  };

  const handleTouchStart = (type: EventType) => {
    longPressTimerRef.current = setTimeout(() => {
      setLongPressType(type);
      handleLongPress(type);
    }, 500);
  };

  const handleTouchEnd = () => {
    if (longPressTimerRef.current) {
      clearTimeout(longPressTimerRef.current);
      longPressTimerRef.current = null;
    }
    setLongPressType(null);
  };

  useEffect(() => {
    return () => {
      if (longPressTimerRef.current) {
        clearTimeout(longPressTimerRef.current);
      }
    };
  }, []);

  return (
    <div className="space-y-2">
      {onQuickLog && (
        <p className="text-xs text-muted-foreground text-center">
          Tap to quick log • Hold for details
        </p>
      )}
      <div className="grid grid-cols-2 gap-4">
        {actions.map((action) => (
          <Button
            key={action.type}
            onClick={() => handleClick(action.type)}
            onTouchStart={() => handleTouchStart(action.type)}
            onTouchEnd={handleTouchEnd}
            onTouchCancel={handleTouchEnd}
            onContextMenu={(e) => {
              e.preventDefault();
              handleLongPress(action.type);
            }}
            variant="outline"
            className={`
              h-[112px] flex flex-col items-center justify-center gap-2 rounded-md border-2 
              ${action.borderColor} ${action.bgColor} 
              hover:${action.bgColor} hover:${action.borderColor} hover:shadow-md
              ${getPressEffect()}
              transition-all duration-200
              ${longPressType === action.type ? 'scale-[0.96] shadow-inner' : 'hover:scale-[1.02]'}
            `}
            style={{ minHeight: '44px', minWidth: '44px' }}
          >
            <action.icon className={`h-8 w-8 ${action.color}`} strokeWidth={2} />
            <span className="text-[15px] leading-[20px] font-medium">{action.label}</span>
            <span className="text-xs text-muted-foreground">{getTimeSince(action.type)}</span>
          </Button>
        ))}
      </div>
    </div>
  );
}
