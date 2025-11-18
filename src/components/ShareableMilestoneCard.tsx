import { format } from 'date-fns';
import { Card } from '@/components/ui/card';
import { Sparkles } from 'lucide-react';

interface Baby {
  name: string;
  date_of_birth: string;
}

interface Milestone {
  title: string;
  description?: string | null;
  achieved_at: string | null;
}

interface ShareableMilestoneCardProps {
  baby: Baby;
  milestone: Milestone;
  cardId: string;
}

export function ShareableMilestoneCard({ baby, milestone, cardId }: ShareableMilestoneCardProps) {
  const achievedDate = milestone.achieved_at ? new Date(milestone.achieved_at) : new Date();
  const babyAge = Math.floor(
    (achievedDate.getTime() - new Date(baby.date_of_birth).getTime()) / 
    (1000 * 60 * 60 * 24 * 30.44)
  );

  return (
    <div 
      id={cardId}
      className="w-[600px] h-[600px] bg-gradient-to-br from-primary/10 to-primary/5 p-12 flex items-center justify-center"
      style={{ fontFamily: 'system-ui, -apple-system, sans-serif' }}
    >
      <Card className="w-full h-full flex flex-col items-center justify-center p-8 text-center space-y-6 border-none shadow-2xl bg-white">
        <div className="w-24 h-24 rounded-full bg-primary/10 flex items-center justify-center">
          <Sparkles className="w-12 h-12 text-primary" />
        </div>
        
        <div>
          <h2 className="text-4xl font-bold mb-3">{milestone.title}</h2>
          <p className="text-xl text-muted-foreground">
            {baby.name} • {babyAge} months old
          </p>
        </div>
        
        {milestone.description && (
          <p className="text-lg text-muted-foreground max-w-md px-4">
            {milestone.description}
          </p>
        )}
        
        <p className="text-base font-medium text-primary">
          {format(achievedDate, 'MMMM d, yyyy')}
        </p>
        
        <div className="pt-6 border-t border-border/30 w-full">
          <p className="text-sm text-muted-foreground font-medium">
            Tracked with Nestling
          </p>
        </div>
      </Card>
    </div>
  );
}
