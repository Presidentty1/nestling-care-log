import { useQuery } from '@tanstack/react-query';
import { patternInsightsService } from '@/services/patternInsightsService';
import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { TrendingUp, AlertCircle, CheckCircle } from 'lucide-react';

interface PatternInsightsProps {
  babyId: string;
}

export function PatternInsights({ babyId }: PatternInsightsProps) {
  const { data: patterns, isLoading } = useQuery({
    queryKey: ['behavior-patterns', babyId],
    queryFn: async () => {
      return await patternInsightsService.getBehaviorPatterns(babyId);
    },
  });

  if (isLoading) {
    return (
      <Card className="p-6">
        <p className="text-muted-foreground text-center">Loading patterns...</p>
      </Card>
    );
  }

  if (!patterns || patterns.length === 0) {
    return (
      <Card className="p-6 text-center">
        <AlertCircle className="h-12 w-12 mx-auto mb-4 text-muted-foreground" />
        <p className="text-muted-foreground">
          No patterns detected yet. Keep tracking crying episodes to discover patterns!
        </p>
      </Card>
    );
  }

  return (
    <div className="space-y-4">
      {patterns.map((pattern: any) => (
        <Card key={pattern.id} className="p-4">
          <div className="flex items-start justify-between mb-2">
            <div className="flex items-start gap-3">
              <TrendingUp className="h-5 w-5 text-primary mt-0.5" />
              <div>
                <h4 className="font-medium capitalize">{pattern.pattern_type.replace('_', ' ')}</h4>
                <p className="text-sm text-muted-foreground mt-1">{pattern.description}</p>
              </div>
            </div>
            {pattern.confidence && (
              <Badge variant="secondary">
                {Math.round(pattern.confidence)}% confidence
              </Badge>
            )}
          </div>

          <div className="flex items-center gap-4 mt-3 text-sm text-muted-foreground">
            <div className="flex items-center gap-1">
              <CheckCircle className="h-4 w-4" />
              <span>{pattern.occurrences} occurrences</span>
            </div>
            {pattern.last_occurrence && (
              <span>
                Last: {new Date(pattern.last_occurrence).toLocaleDateString()}
              </span>
            )}
          </div>

          {pattern.metadata && (
            <div className="mt-3 p-3 bg-muted rounded text-sm">
              <strong>Insight:</strong> {pattern.metadata.insight || 'Pattern detected'}
            </div>
          )}
        </Card>
      ))}
    </div>
  );
}