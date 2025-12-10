import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import type { Baby } from '@/lib/types';
import { babyService } from '@/services/babyService';
import { sleepTrainingService } from '@/services/sleepTrainingService';
import { useEffect } from 'react';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { BabySwitcher } from '@/components/BabySwitcher';
import { MobileNav } from '@/components/MobileNav';
import { MedicalDisclaimer } from '@/components/MedicalDisclaimer';
import { ArrowLeft, Plus, Moon, TrendingUp } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useToast } from '@/hooks/use-toast';
import { Badge } from '@/components/ui/badge';

export default function SleepTraining() {
  const navigate = useNavigate();
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const [selectedBabyId, setSelectedBabyId] = useState<string | null>(null);
  const [isSwitcherOpen, setIsSwitcherOpen] = useState(false);

  const { data: babies } = useQuery({
    queryKey: ['babies'],
    queryFn: async () => {
      return await babyService.getUserBabies();
    },
  });

  const { data: sessions } = useQuery({
    queryKey: ['sleep-training-sessions', selectedBabyId],
    queryFn: async () => {
      if (!selectedBabyId) return [];
      return await sleepTrainingService.getSessions(selectedBabyId);
    },
    enabled: !!selectedBabyId,
  });

  const { data: regressions } = useQuery({
    queryKey: ['sleep-regressions', selectedBabyId],
    queryFn: async () => {
      if (!selectedBabyId) return [];
      return await sleepTrainingService.getRegressions(selectedBabyId);
    },
    enabled: !!selectedBabyId,
  });

  if (babies && babies.length > 0 && !selectedBabyId) {
    setSelectedBabyId(babies[0].id);
  }

  const activeSession = sessions?.find((s: any) => s.status === 'active');
  const unresolvedRegressions = regressions?.filter((r: any) => !r.resolved_at);

  return (
    <div className='min-h-screen bg-background pb-20'>
      <div className='sticky top-0 z-10 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60 border-b'>
        <div className='container mx-auto p-4'>
          <div className='flex items-center justify-between mb-4'>
            <div className='flex items-center gap-4'>
              <Button onClick={() => navigate(-1)} variant='ghost' size='sm'>
                <ArrowLeft className='h-4 w-4' />
              </Button>
              <div>
                <h1 className='text-2xl font-bold'>Sleep Training</h1>
                <p className='text-sm text-muted-foreground'>Improve sleep patterns</p>
              </div>
            </div>
            <Button onClick={() => navigate('/sleep-training/new-session')}>
              <Plus className='mr-2 h-4 w-4' />
              New Session
            </Button>
          </div>
          {babies && babies.length > 1 && (
            <Button
              variant='ghost'
              size='sm'
              onClick={() => setIsSwitcherOpen(true)}
              className='flex items-center gap-2'
            >
              <span>👶</span>
              <span>{babies.find(b => b.id === selectedBabyId)?.name || 'Select Baby'}</span>
            </Button>
          )}
        </div>
      </div>

      <div className='container mx-auto p-4 space-y-4'>
        {activeSession && (
          <Card className='p-4 border-orange-500 bg-orange-50 dark:bg-orange-950'>
            <div className='flex items-start gap-3'>
              <Moon className='h-5 w-5 text-orange-600 mt-0.5' />
              <div>
                <h3 className='font-semibold'>Possible Sleep Regression Detected</h3>
                <p className='text-sm text-muted-foreground mt-1'>
                  {unresolvedRegressions[0].regression_type?.replace('_', ' ')} -{' '}
                  {unresolvedRegressions[0].severity} severity
                </p>
                <Button
                  variant='link'
                  className='p-0 h-auto mt-2'
                  onClick={() => navigate('/sleep-regressions')}
                >
                  Learn more →
                </Button>
              </div>
            </div>
          </Card>
        )}

        {activeSession && (
          <Card className='p-6'>
            <div className='flex items-start justify-between mb-4'>
              <div>
                <Badge className='mb-2'>Active</Badge>
                <h3 className='font-semibold text-lg capitalize'>
                  {activeSession.method.replace('_', ' ')} Method
                </h3>
                <p className='text-sm text-muted-foreground'>
                  Started {new Date(activeSession.start_date).toLocaleDateString()}
                </p>
              </div>
              <Button onClick={() => navigate(`/sleep-training/session/${activeSession.id}`)}>
                View Progress
              </Button>
            </div>
            {activeSession.notes && <p className='text-sm mt-2'>{activeSession.notes}</p>}
          </Card>
        )}

        <Tabs defaultValue='sessions' className='space-y-4'>
          <TabsList className='grid w-full grid-cols-3'>
            <TabsTrigger value='sessions'>Sessions</TabsTrigger>
            <TabsTrigger value='analysis'>Analysis</TabsTrigger>
            <TabsTrigger value='methods'>Methods</TabsTrigger>
          </TabsList>

          <TabsContent value='sessions' className='space-y-4'>
            {sessions && sessions.length > 0 ? (
              sessions.map((session: any) => (
                <Card key={session.id} className='p-4'>
                  <div className='flex justify-between items-start'>
                    <div>
                      <h3 className='font-medium capitalize'>{session.method.replace('_', ' ')}</h3>
                      <p className='text-sm text-muted-foreground'>
                        {new Date(session.start_date).toLocaleDateString()}
                      </p>
                    </div>
                    <Badge variant={session.status === 'active' ? 'default' : 'secondary'}>
                      {session.status}
                    </Badge>
                  </div>
                  <Button
                    variant='ghost'
                    className='w-full mt-3'
                    onClick={() => navigate(`/sleep-training/session/${session.id}`)}
                  >
                    View Details →
                  </Button>
                </Card>
              ))
            ) : (
              <Card className='p-8 text-center'>
                <Moon className='h-12 w-12 mx-auto mb-4 text-muted-foreground' />
                <p className='text-muted-foreground'>No sleep training sessions yet</p>
                <Button className='mt-4' onClick={() => navigate('/sleep-training/new-session')}>
                  Start Your First Session
                </Button>
              </Card>
            )}
          </TabsContent>

          <TabsContent value='analysis' className='space-y-4'>
            <Card className='p-6'>
              <h3 className='font-semibold mb-4'>Sleep Pattern Analysis</h3>
              <p className='text-sm text-muted-foreground'>
                Track your progress and identify patterns in your baby's sleep behavior.
              </p>
              <Button className='mt-4' onClick={() => navigate('/wake-window-calculator')}>
                <TrendingUp className='mr-2 h-4 w-4' />
                Calculate Wake Windows
              </Button>
            </Card>
          </TabsContent>

          <TabsContent value='methods' className='space-y-4'>
            <Card className='p-6'>
              <h3 className='font-semibold mb-2'>Ferber Method</h3>
              <p className='text-sm text-muted-foreground'>
                Graduated extinction with timed check-ins at increasing intervals.
              </p>
            </Card>
            <Card className='p-6'>
              <h3 className='font-semibold mb-2'>Chair Method</h3>
              <p className='text-sm text-muted-foreground'>
                Gradually move further from baby's bed each night.
              </p>
            </Card>
            <Card className='p-6'>
              <h3 className='font-semibold mb-2'>Pick Up/Put Down</h3>
              <p className='text-sm text-muted-foreground'>
                Pick up when crying, put down when calm. Repeat as needed.
              </p>
            </Card>
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
