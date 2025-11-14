import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Milk, Moon, Baby, Clock } from 'lucide-react';
import { EventType } from '@/lib/types';

interface QuickActionsProps {
  onActionSelect: (type: EventType) => void;
}

export function QuickActions({ onActionSelect }: QuickActionsProps) {
  const actions = [
    { type: 'feed' as EventType, label: 'Feed', icon: Milk, color: 'bg-blue-500' },
    { type: 'sleep' as EventType, label: 'Sleep', icon: Moon, color: 'bg-purple-500' },
    { type: 'diaper' as EventType, label: 'Diaper', icon: Baby, color: 'bg-green-500' },
    { type: 'tummy_time' as EventType, label: 'Tummy Time', icon: Clock, color: 'bg-orange-500' },
  ];

  return (
    <Card className="p-4">
      <h3 className="font-medium mb-3 text-sm">Quick Actions</h3>
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
        {actions.map((action) => (
          <Button
            key={action.type}
            onClick={() => onActionSelect(action.type)}
            variant="outline"
            className="flex flex-col items-center gap-2 h-auto py-4"
          >
            <div className={`p-2 rounded-full ${action.color} bg-opacity-10`}>
              <action.icon className="h-5 w-5" />
            </div>
            <span className="text-xs">{action.label}</span>
          </Button>
        ))}
      </div>
    </Card>
  );
}