import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { format, subDays } from 'date-fns';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { ArrowLeft, TrendingUp, Lock, Sparkles } from 'lucide-react';
import { useQuery } from '@tanstack/react-query';
import { useAuth } from '@/hooks/useAuth';
import { usePro } from '@/hooks/usePro';
import { dataService } from '@/services/dataService';
import { SleepAnalysis } from '@/components/analytics/SleepAnalysis';
import { FeedingAnalysis } from '@/components/analytics/FeedingAnalysis';
import { PatternVisualization } from '@/components/analytics/PatternVisualization';
import { BabySwitcher } from '@/components/BabySwitcher';
import { DoctorReport } from '@/components/DoctorReport';
import type { Baby } from '@/services/babyService';

export default function Patterns() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const { isPro, loading: proLoading } = usePro();
  const [selectedBabyId, setSelectedBabyId] = useState<string | null>(null);
  const [dateRange, setDateRange] = useState<'week'>('week'); // Fixed to week for simplicity

  const { data: babies, isLoading: babiesLoading } = useQuery({
    queryKey: ['babies'],
    queryFn: async () => {
      const { data: familyMembers } = await (await import('@/integrations/supabase/client')).supabase
        .from('family_members')
        .select('family_id')
        .eq('user_id', user?.id);

      if (!familyMembers || familyMembers.length === 0) return [];

      const { data: babies } = await (await import('@/integrations/supabase/client')).supabase
        .from('babies')
        .select('*')
        .in('family_id', familyMembers.map(fm => fm.family_id));

      return babies as Baby[];
    },
    enabled: !!user,
  });

  useEffect(() => {
    if (babies && babies.length > 0 && !selectedBabyId) {
      setSelectedBabyId(babies[0].id);
    }
  }, [babies, selectedBabyId]);

  if (proLoading || babiesLoading) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center p-4">
        <div className="space-y-3 text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto"></div>
          <p className="text-body text-muted-foreground">Loading patterns...</p>
        </div>
      </div>
    );
  }

  if (!isPro) {
    return (
      <div className="min-h-screen bg-background pb-20">
        <div className="max-w-2xl mx-auto px-4 pt-4 pb-4">
          <Button onClick={() => navigate(-1)} variant="ghost" className="mb-4">
            <ArrowLeft className="mr-2 h-4 w-4" />
            Back
          </Button>

          <div className="space-y-6">
            <div className="text-center">
              <div className="w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center mx-auto mb-4">
                <TrendingUp className="h-8 w-8 text-primary" />
              </div>
              <h1 className="text-2xl font-bold mb-2">See Your Baby's Patterns</h1>
              <p className="text-muted-foreground">
                Unlock insights into sleep, feeding, and diaper patterns over the past week.
              </p>
            </div>

            <Card className="bg-gradient-to-br from-primary/10 via-primary/5 to-background border-primary/20">
              <CardHeader>
                <CardTitle className="text-lg flex items-center gap-2">
                  <Sparkles className="h-5 w-5 text-primary" />
                  Nestling Pro Required
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-3">
                  <div className="flex items-start gap-3">
                    <div className="w-2 h-2 bg-primary rounded-full mt-2 flex-shrink-0" />
                    <div>
                      <p className="font-medium">Sleep patterns</p>
                      <p className="text-sm text-muted-foreground">Average night sleep and nap timing trends</p>
                    </div>
                  </div>
                  <div className="flex items-start gap-3">
                    <div className="w-2 h-2 bg-primary rounded-full mt-2 flex-shrink-0" />
                    <div>
                      <p className="font-medium">Feeding insights</p>
                      <p className="text-sm text-muted-foreground">Volume trends and spacing patterns</p>
                    </div>
                  </div>
                  <div className="flex items-start gap-3">
                    <div className="w-2 h-2 bg-primary rounded-full mt-2 flex-shrink-0" />
                    <div>
                      <p className="font-medium">Diaper analytics</p>
                      <p className="text-sm text-muted-foreground">Daily counts and unusual patterns</p>
                    </div>
                  </div>
                  <div className="flex items-start gap-3">
                    <div className="w-2 h-2 bg-primary rounded-full mt-2 flex-shrink-0" />
                    <div>
                      <p className="font-medium">Doctor reports</p>
                      <p className="text-sm text-muted-foreground">Shareable summaries for pediatric visits</p>
                    </div>
                  </div>
                </div>

                <div className="pt-2">
                  <p className="text-sm text-muted-foreground mb-3">
                    <strong className="text-primary">$39.99/yr</strong> (founder launch special)
                    <br />
                    <span className="text-xs">Also available: $4.99/mo • $79.99 lifetime</span>
                  </p>
                  <Button className="w-full" onClick={() => navigate('/settings')}>
                    Upgrade to Pro
                  </Button>
                </div>
              </CardContent>
            </Card>

            {/* Blurred preview */}
            <div className="relative">
              <div className="absolute inset-0 bg-background/80 backdrop-blur-sm z-10 rounded-lg flex items-center justify-center">
                <div className="flex items-center gap-2 text-muted-foreground">
                  <Lock className="h-4 w-4" />
                  <span className="text-sm">Upgrade to unlock patterns</span>
                </div>
              </div>
              <Card className="opacity-50">
                <CardHeader>
                  <CardTitle>Last 7 Days Overview</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    <div className="h-32 bg-muted rounded animate-pulse" />
                    <div className="h-24 bg-muted rounded animate-pulse" />
                    <div className="h-20 bg-muted rounded animate-pulse" />
                  </div>
                </CardContent>
              </Card>
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (!babies || babies.length === 0) {
    return (
      <div className="min-h-screen bg-background p-4">
        <Button onClick={() => navigate(-1)} variant="ghost" className="mb-4">
          <ArrowLeft className="mr-2 h-4 w-4" />
          Back
        </Button>
        <Card className="p-8 text-center">
          <p className="text-muted-foreground">No babies found. Please add a baby first.</p>
        </Card>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background pb-20">
      <div className="max-w-2xl mx-auto px-4 pt-4 pb-4">
        <div className="flex items-center justify-between mb-6">
          <Button onClick={() => navigate(-1)} variant="ghost">
            <ArrowLeft className="mr-2 h-4 w-4" />
            Back
          </Button>
          <Badge variant="secondary" className="flex items-center gap-1">
            <Sparkles className="h-3 w-3" />
            Pro
          </Badge>
        </div>

        <div className="mb-6">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h1 className="text-2xl font-bold mb-2">Patterns</h1>
              <p className="text-muted-foreground">Insights from the last 7 days</p>
            </div>
            {babies && babies.length > 0 && selectedBabyId && (
              <DoctorReport baby={babies.find(b => b.id === selectedBabyId)!} />
            )}
          </div>
        </div>

        <div className="space-y-6">
          {selectedBabyId && (
            <>
              <SleepAnalysis babyId={selectedBabyId} dateRange={dateRange} />
              <FeedingAnalysis babyId={selectedBabyId} dateRange={dateRange} />
              <PatternVisualization babyId={selectedBabyId} dateRange={dateRange} />
            </>
          )}
        </div>

        <BabySwitcher
          babies={babies}
          activeBabyId={selectedBabyId}
          onSelect={setSelectedBabyId}
          onAddNew={() => navigate('/onboarding')}
        />
      </div>
    </div>
  );
}
