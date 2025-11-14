import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { BabySelector } from '@/components/BabySelector';
import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Baby } from '@/lib/types';
import { TrendingUp, Lightbulb, CheckCircle2 } from 'lucide-react';
import { format } from 'date-fns';

export default function Insights() {
  const [selectedBaby, setSelectedBaby] = useState<Baby | null>(null);

  const { data: patterns } = useQuery({
    queryKey: ['pattern-insights', selectedBaby?.id],
    queryFn: async () => {
      if (!selectedBaby) return [];
      const { data } = await supabase
        .from('pattern_insights')
        .select('*')
        .eq('baby_id', selectedBaby.id)
        .is('acknowledged_at', null)
        .order('detected_at', { ascending: false });
      return data || [];
    },
    enabled: !!selectedBaby,
  });

  const { data: correlations } = useQuery({
    queryKey: ['correlations', selectedBaby?.id],
    queryFn: async () => {
      if (!selectedBaby) return [];
      const { data } = await supabase
        .from('correlation_analysis')
        .select('*')
        .eq('baby_id', selectedBaby.id)
        .order('created_at', { ascending: false })
        .limit(5);
      return data || [];
    },
    enabled: !!selectedBaby,
  });

  const getConfidenceColor = (confidence: number) => {
    if (confidence >= 0.8) return 'bg-green-100 text-green-800';
    if (confidence >= 0.6) return 'bg-yellow-100 text-yellow-800';
    return 'bg-orange-100 text-orange-800';
  };

  const getCorrelationColor = (strength: number) => {
    const abs = Math.abs(strength);
    if (abs >= 0.7) return 'bg-purple-100 text-purple-800';
    if (abs >= 0.4) return 'bg-blue-100 text-blue-800';
    return 'bg-gray-100 text-gray-800';
  };

  return (
    <div className="min-h-screen bg-background p-4">
      <div className="max-w-4xl mx-auto space-y-6">
        <div className="flex items-center justify-between">
          <h1 className="text-3xl font-bold">Insights & Patterns</h1>
          <BabySelector value={selectedBaby} onChange={setSelectedBaby} />
        </div>

        {!selectedBaby && (
          <Card className="p-6 text-center text-muted-foreground">
            Select a baby to view insights
          </Card>
        )}

        {selectedBaby && (
          <>
            <div className="space-y-4">
              <h2 className="text-xl font-semibold flex items-center gap-2">
                <TrendingUp className="w-5 h-5" />
                Detected Patterns
              </h2>

              {patterns && patterns.length > 0 ? (
                patterns.map((pattern) => (
                  <Card key={pattern.id} className="p-6">
                    <div className="flex items-start justify-between mb-4">
                      <div>
                        <h3 className="font-semibold text-lg">{pattern.insight_title}</h3>
                        <p className="text-sm text-muted-foreground">
                          Detected {format(new Date(pattern.detected_at), 'MMM d, yyyy')}
                        </p>
                      </div>
                      <Badge className={getConfidenceColor(pattern.confidence || 0)}>
                        {Math.round((pattern.confidence || 0) * 100)}% confidence
                      </Badge>
                    </div>

                    <p className="text-muted-foreground mb-4">{pattern.insight_description}</p>

                    <Badge variant="outline" className="capitalize">
                      {pattern.pattern_type}
                    </Badge>
                  </Card>
                ))
              ) : (
                <Card className="p-6 text-center text-muted-foreground">
                  <Lightbulb className="w-12 h-12 mx-auto mb-2 opacity-50" />
                  <p>No patterns detected yet. Keep logging data to discover insights!</p>
                </Card>
              )}
            </div>

            <div className="space-y-4">
              <h2 className="text-xl font-semibold flex items-center gap-2">
                <CheckCircle2 className="w-5 h-5" />
                Correlations
              </h2>

              {correlations && correlations.length > 0 ? (
                correlations.map((correlation) => (
                  <Card key={correlation.id} className="p-6">
                    <div className="flex items-start justify-between mb-4">
                      <div>
                        <h3 className="font-semibold">
                          {correlation.variable_a} ↔ {correlation.variable_b}
                        </h3>
                        <p className="text-sm text-muted-foreground">
                          Based on {correlation.sample_size} data points over{' '}
                          {correlation.analysis_period_days} days
                        </p>
                      </div>
                      <Badge className={getCorrelationColor(correlation.correlation_strength || 0)}>
                        {correlation.correlation_strength > 0 ? '+' : ''}
                        {correlation.correlation_strength?.toFixed(2)}
                      </Badge>
                    </div>

                    {correlation.insight && (
                      <p className="text-sm text-muted-foreground">{correlation.insight}</p>
                    )}
                  </Card>
                ))
              ) : (
                <Card className="p-6 text-center text-muted-foreground">
                  Not enough data to identify correlations yet.
                </Card>
              )}
            </div>
          </>
        )}
      </div>
    </div>
  );
}