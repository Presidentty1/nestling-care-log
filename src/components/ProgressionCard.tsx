import { Card, CardContent } from '@/components/ui/card';
import { Progress } from '@/components/ui/progress';
import { Brain, TrendingUp, Sparkles, Lock } from 'lucide-react';

interface ProgressionCardProps {
  currentLogs: number;
}

export function ProgressionCard({ currentLogs }: ProgressionCardProps) {
  const milestones = [
    {
      logsRequired: 3,
      title: 'Basic Patterns',
      description: 'See feeding and sleep frequency',
      icon: TrendingUp,
      unlocked: currentLogs >= 3,
    },
    {
      logsRequired: 5,
      title: 'Smart Predictions',
      description: "AI learns your baby's unique patterns",
      icon: Brain,
      unlocked: currentLogs >= 5,
    },
    {
      logsRequired: 10,
      title: 'Advanced Insights',
      description: 'Pattern detection and recommendations',
      icon: Sparkles,
      unlocked: currentLogs >= 10,
    },
  ];

  const nextMilestone = milestones.find(m => !m.unlocked);
  
  if (!nextMilestone || currentLogs >= 10) {
    return null; // Don't show if all unlocked or no more milestones
  }

  const progress = (currentLogs / nextMilestone.logsRequired) * 100;
  const logsNeeded = nextMilestone.logsRequired - currentLogs;

  return (
    <Card className="border-2 border-primary/20 bg-gradient-to-br from-primary/5 to-primary/10 animate-fade-in">
      <CardContent className="p-4">
        <div className="flex items-start gap-3 mb-3">
          <div className="w-10 h-10 rounded-lg bg-primary/20 flex items-center justify-center shrink-0">
            <Lock className="h-5 w-5 text-primary" />
          </div>
          <div className="flex-1 min-w-0">
            <h3 className="font-semibold text-sm mb-1">
              Unlock: {nextMilestone.title}
            </h3>
            <p className="text-xs text-muted-foreground mb-2">
              {nextMilestone.description}
            </p>
            <div className="space-y-1">
              <div className="flex items-center justify-between text-xs">
                <span className="text-muted-foreground">
                  {currentLogs} / {nextMilestone.logsRequired} logs
                </span>
                <span className="font-medium text-primary">
                  {logsNeeded} more to unlock
                </span>
              </div>
              <Progress value={progress} className="h-2" />
            </div>
          </div>
        </div>

        {/* Preview of all milestones */}
        <div className="mt-4 pt-4 border-t border-border/50">
          <p className="text-xs text-muted-foreground mb-2">Coming soon:</p>
          <div className="space-y-2">
            {milestones.map((milestone) => (
              <div
                key={milestone.logsRequired}
                className={`flex items-center gap-2 text-xs ${
                  milestone.unlocked ? 'text-primary' : 'text-muted-foreground'
                }`}
              >
                <milestone.icon className="h-3 w-3" />
                <span>{milestone.title}</span>
                {milestone.unlocked && <span className="text-xs">✓</span>}
              </div>
            ))}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

