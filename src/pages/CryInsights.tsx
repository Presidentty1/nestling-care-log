import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { Baby } from '@/lib/types';
import { useEffect } from 'react';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { BabySwitcher } from '@/components/BabySwitcher';
import { CryTimer } from '@/components/CryTimer';
import { PatternInsights } from '@/components/PatternInsights';
import { MobileNav } from '@/components/MobileNav';
import { CryRecorder } from '@/components/CryRecorder';
import { CryAnalysisResult } from '@/components/CryAnalysisResult';
import { ArrowLeft, Clock, TrendingUp } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useToast } from '@/hooks/use-toast';

export default function CryInsights() {
  const navigate = useNavigate();
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const [selectedBabyId, setSelectedBabyId] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState('timer');
  const [analysisResult, setAnalysisResult] = useState<any>(null);
  const [isSwitcherOpen, setIsSwitcherOpen] = useState(false);

  const { data: babies } = useQuery({
    queryKey: ['babies'],
    queryFn: async () => {
      const { data: familyMembers } = await supabase
        .from('family_members')
        .select('family_id')
        .eq('user_id', (await supabase.auth.getUser()).data.user?.id);

      if (!familyMembers || familyMembers.length === 0) return [];

      const { data: babies } = await supabase
        .from('babies')
        .select('*')
        .in('family_id', familyMembers.map(fm => fm.family_id));

      return babies as Baby[];
    },
  });

  const { data: cryLogs } = useQuery({
    queryKey: ['cry-logs', selectedBabyId],
    queryFn: async () => {
      if (!selectedBabyId) return [];
      const { data } = await supabase
        .from('cry_logs')
        .select('*')
        .eq('baby_id', selectedBabyId)
        .order('start_time', { ascending: false })
        .limit(20);
      return data || [];
    },
    enabled: !!selectedBabyId,
  });

  if (babies && babies.length > 0 && !selectedBabyId) {
    setSelectedBabyId(babies[0].id);
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
      <div className="sticky top-0 z-10 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60 border-b">
        <div className="container mx-auto p-4">
          <div className="flex items-center gap-4 mb-4">
            <Button onClick={() => navigate(-1)} variant="ghost" size="sm">
              <ArrowLeft className="h-4 w-4" />
            </Button>
            <div>
              <h1 className="text-2xl font-bold">Cry Insights</h1>
              <p className="text-sm text-muted-foreground">AI-powered cry pattern analysis</p>
            </div>
          </div>
          <Button
            variant="ghost"
            size="sm"
            onClick={() => setIsSwitcherOpen(true)}
            className="flex items-center gap-2"
          >
            <span>👶</span>
            <span>{babies?.find(b => b.id === selectedBabyId)?.name || 'Select Baby'}</span>
          </Button>
        </div>
      </div>

      <div className="container mx-auto p-4">
        <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-4">
          <TabsList className="grid w-full grid-cols-3">
            <TabsTrigger value="timer">
              <Clock className="mr-2 h-4 w-4" />
              Record
            </TabsTrigger>
            <TabsTrigger value="history">History</TabsTrigger>
            <TabsTrigger value="patterns">
              <TrendingUp className="mr-2 h-4 w-4" />
              Patterns
            </TabsTrigger>
          </TabsList>

          <TabsContent value="timer" className="space-y-4">
            {!analysisResult ? (
              selectedBabyId && (
                <CryRecorder
                  babyId={selectedBabyId}
                  onAnalysisComplete={setAnalysisResult}
                />
              )
            ) : (
              <CryAnalysisResult
                result={analysisResult}
                onFeedback={(helpful) => {
                  toast({ title: helpful ? 'Thank you!' : 'We\'ll keep improving' });
                  setTimeout(() => setAnalysisResult(null), 2000);
                }}
              />
            )}
          </TabsContent>

          <TabsContent value="history" className="space-y-4">
            {cryLogs && cryLogs.length > 0 ? (
              cryLogs.map((log: any) => (
                <Card key={log.id} className="p-4">
                  <div className="flex justify-between items-start mb-2">
                    <div>
                      <p className="font-medium">{log.cry_type || 'Unknown type'}</p>
                      <p className="text-sm text-muted-foreground">
                        {new Date(log.start_time).toLocaleString()}
                      </p>
                    </div>
                    {log.confidence && (
                      <span className="text-xs bg-primary/10 text-primary px-2 py-1 rounded">
                        {Math.round(log.confidence)}% confidence
                      </span>
                    )}
                  </div>
                  {log.resolved_by && (
                    <p className="text-sm text-muted-foreground mt-2">
                      Resolved by: {log.resolved_by}
                    </p>
                  )}
                  {log.note && (
                    <p className="text-sm mt-2">{log.note}</p>
                  )}
                </Card>
              ))
            ) : (
              <Card className="p-8 text-center">
                <p className="text-muted-foreground">No cry logs yet. Start the timer to track crying episodes.</p>
              </Card>
            )}
          </TabsContent>

          <TabsContent value="patterns" className="space-y-4">
            {selectedBabyId && <PatternInsights babyId={selectedBabyId} />}
          </TabsContent>
        </Tabs>
      </div>

      <BabySwitcher
        babies={babies || []}
        selectedBabyId={selectedBabyId || ''}
        isOpen={isSwitcherOpen}
        onClose={() => setIsSwitcherOpen(false)}
        onSelect={setSelectedBabyId}
      />
      <MobileNav />
    </div>
  );
}