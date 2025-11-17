import { Button } from '@/components/ui/button';
import { Milk, Moon, Baby, Clock } from 'lucide-react';
import { EventType } from '@/types/events';

interface QuickActionsProps {
  onActionSelect: (type: EventType) => void;
}

export function QuickActions({ onActionSelect }: QuickActionsProps) {
  const actions = [
    { type: 'feed' as EventType, label: 'Feed', icon: Milk },
    { type: 'sleep' as EventType, label: 'Sleep', icon: Moon },
    { type: 'diaper' as EventType, label: 'Diaper', icon: Baby },
    { type: 'tummy_time' as EventType, label: 'Tummy', icon: Clock },
  ];

  return (
    <div className="grid grid-cols-2 gap-3">
      {actions.map((action) => (
        <Button
          key={action.type}
          onClick={() => onActionSelect(action.type)}
          variant="outline"
          className="h-[112px] flex flex-col items-center justify-center gap-3 rounded-md border-2 hover:bg-primary-100 hover:border-primary active:scale-[0.98] transition-all duration-100"
          style={{ minHeight: '44px', minWidth: '44px' }}
        >
          <action.icon className="h-8 w-8 text-primary" strokeWidth={2} />
          <span className="text-[15px] leading-[20px] font-medium">{action.label}</span>
        </Button>
      ))}
    </div>
  );
}
