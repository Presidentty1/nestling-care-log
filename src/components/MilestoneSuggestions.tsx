import { useState } from 'react';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { Baby } from '@/lib/types';
import { milestoneCategories, MilestoneTemplate } from '@/lib/milestoneCategories';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { CheckCircle2, Sparkles } from 'lucide-react';
import { differenceInMonths } from 'date-fns';
import { toast } from 'sonner';
import confetti from 'canvas-confetti';

interface MilestoneSuggestionsProps {
  baby: Baby;
  achievedMilestones: string[];
}

export function MilestoneSuggestions({ baby, achievedMilestones }: MilestoneSuggestionsProps) {
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const queryClient = useQueryClient();

  const babyAgeMonths = differenceInMonths(new Date(), new Date(baby.date_of_birth));

  const suggestedMilestones = milestoneCategories
    .flatMap(cat => 
      cat.milestones.map(m => ({ 
        ...m, 
        category: cat.type,
        categoryLabel: cat.label,
        icon: cat.icon 
      }))
    )
    .filter(m => 
      !achievedMilestones.includes(m.title) &&
      babyAgeMonths >= m.ageRangeMonths[0] - 1 &&
      babyAgeMonths <= m.ageRangeMonths[1] + 1
    )
    .sort((a, b) => {
      const aDistance = Math.abs(a.typicalAgeMonths - babyAgeMonths);
      const bDistance = Math.abs(b.typicalAgeMonths - babyAgeMonths);
      return aDistance - bDistance;
    })
    .slice(0, 5);

  const achieveMutation = useMutation({
    mutationFn: async (milestone: MilestoneTemplate & { category: string; categoryLabel: string; icon: string }) => {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');

      const { error } = await supabase.from('milestones').insert({
        baby_id: baby.id,
        title: milestone.title,
        description: milestone.description,
        category: milestone.category,
        achieved_at: new Date().toISOString(),
        created_by: user.id,
        expected_age_months: milestone.typicalAgeMonths,
      });

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['milestones'] });
      
      // Celebrate with confetti
      confetti({
        particleCount: 100,
        spread: 70,
        origin: { y: 0.6 }
      });

      toast.success('Milestone achieved! 🎉');
    },
    onError: (error) => {
      toast.error('Failed to log milestone: ' + error.message);
    },
  });

  if (suggestedMilestones.length === 0) {
    return null;
  }

  return (
    <Card className="border-primary/20 bg-gradient-to-br from-primary/5 to-primary/10">
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-lg">
          <Sparkles className="w-5 h-5 text-primary" />
          Expected for {baby.name}'s Age ({babyAgeMonths} months)
        </CardTitle>
        <p className="text-sm text-muted-foreground">
          Tap to mark as achieved, or skip if not applicable yet
        </p>
      </CardHeader>
      <CardContent className="space-y-3">
        {suggestedMilestones.map((milestone) => (
          <div 
            key={milestone.title}
            className="flex items-start gap-3 p-3 rounded-lg bg-background/50 hover:bg-background/80 transition-colors"
          >
            <span className="text-2xl mt-1">{milestone.icon}</span>
            <div className="flex-1 min-w-0">
              <div className="flex items-start justify-between gap-2">
                <div className="flex-1">
                  <h4 className="font-semibold text-sm">{milestone.title}</h4>
                  <p className="text-xs text-muted-foreground mt-1">
                    {milestone.description}
                  </p>
                  <div className="flex items-center gap-2 mt-2">
                    <Badge variant="secondary" className="text-xs">
                      {milestone.categoryLabel}
                    </Badge>
                    <span className="text-xs text-muted-foreground">
                      Typical: {milestone.typicalAgeMonths} months
                    </span>
                  </div>
                </div>
                <Button
                  size="sm"
                  variant="outline"
                  className="shrink-0"
                  onClick={() => achieveMutation.mutate(milestone)}
                  disabled={achieveMutation.isPending}
                >
                  <CheckCircle2 className="w-4 h-4 mr-1" />
                  Mark as Achieved
                </Button>
              </div>
            </div>
          </div>
        ))}
        
        <p className="text-xs text-muted-foreground italic pt-2">
          Remember: Every baby develops at their own pace. These are guidelines, not requirements.
        </p>
      </CardContent>
    </Card>
  );
}
