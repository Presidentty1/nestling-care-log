import React from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Sparkles, Lock, Eye } from 'lucide-react';
import { track } from '@/analytics/analytics';

interface TasteOfProProps {
  feature: 'patterns' | 'doctor_report' | 'ai_insights' | 'caregiver_sync';
  title: string;
  description: string;
  previewContent: React.ReactNode;
  upgradeText?: string;
  onUpgrade?: () => void;
}

export function TasteOfPro({
  feature,
  title,
  description,
  previewContent,
  upgradeText = 'Unlock with Pro',
  onUpgrade,
}: TasteOfProProps) {
  const handleUpgrade = () => {
    track('taste_of_pro_upgrade_clicked', {
      feature,
      source: 'blurred_preview',
    });
    onUpgrade?.();
  };

  const handlePreviewClick = () => {
    track('taste_of_pro_preview_clicked', {
      feature,
    });
  };

  return (
    <Card className='relative overflow-hidden border-dashed border-2'>
      {/* Blurred overlay */}
      <div className='absolute inset-0 bg-background/80 backdrop-blur-sm z-10 flex items-center justify-center'>
        <div className='text-center space-y-4 p-6 max-w-sm'>
          <div className='flex items-center justify-center gap-2'>
            <Lock className='h-5 w-5 text-primary' />
            <Badge variant='secondary' className='bg-primary/10 text-primary'>
              <Sparkles className='h-3 w-3 mr-1' />
              Pro Feature
            </Badge>
          </div>

          <div>
            <h3 className='font-semibold text-lg mb-2'>{title}</h3>
            <p className='text-sm text-muted-foreground mb-4'>{description}</p>
          </div>

          <div className='space-y-2'>
            <Button onClick={handleUpgrade} className='w-full'>
              {upgradeText}
            </Button>
            <Button
              variant='ghost'
              size='sm'
              onClick={handlePreviewClick}
              className='w-full text-xs'
            >
              <Eye className='h-3 w-3 mr-1' />
              Preview
            </Button>
          </div>
        </div>
      </div>

      {/* Blurred content */}
      <div className='opacity-30 pointer-events-none'>{previewContent}</div>
    </Card>
  );
}

// Specific taste of Pro components for different features

export function TasteOfPatterns({ onUpgrade }: { onUpgrade?: () => void }) {
  return (
    <TasteOfPro
      feature='patterns'
      title='Weekly Sleep Patterns'
      description="See your baby's sleep trends, nap efficiency, and feeding patterns in beautiful charts."
      onUpgrade={onUpgrade}
      previewContent={
        <div className='p-6'>
          <CardHeader>
            <CardTitle className='flex items-center gap-2'>
              📊 Sleep Patterns
              <Badge variant='outline'>Last 7 Days</Badge>
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className='space-y-4'>
              <div className='h-32 bg-muted rounded-lg flex items-center justify-center'>
                <span className='text-muted-foreground'>Sleep duration chart</span>
              </div>
              <div className='grid grid-cols-2 gap-4'>
                <div className='text-center'>
                  <div className='text-2xl font-bold text-primary'>12.5h</div>
                  <div className='text-sm text-muted-foreground'>Avg daily sleep</div>
                </div>
                <div className='text-center'>
                  <div className='text-2xl font-bold text-primary'>4.2</div>
                  <div className='text-sm text-muted-foreground'>Avg naps/day</div>
                </div>
              </div>
            </div>
          </CardContent>
        </div>
      }
    />
  );
}

export function TasteOfDoctorReport({ onUpgrade }: { onUpgrade?: () => void }) {
  return (
    <TasteOfPro
      feature='doctor_report'
      title='Doctor Summary Report'
      description='Generate professional reports to share with your pediatrician, including charts and insights.'
      onUpgrade={onUpgrade}
      previewContent={
        <div className='p-6'>
          <CardHeader>
            <CardTitle className='flex items-center gap-2'>
              👨‍⚕️ Pediatrician Report
              <Badge variant='outline'>Emma Johnson</Badge>
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className='space-y-4'>
              <div className='grid grid-cols-3 gap-4'>
                <div className='text-center'>
                  <div className='text-xl font-bold'>8.5h</div>
                  <div className='text-xs text-muted-foreground'>Night sleep</div>
                </div>
                <div className='text-center'>
                  <div className='text-xl font-bold'>4.0h</div>
                  <div className='text-xs text-muted-foreground'>Day sleep</div>
                </div>
                <div className='text-center'>
                  <div className='text-xl font-bold'>6</div>
                  <div className='text-xs text-muted-foreground'>Feedings/day</div>
                </div>
              </div>
              <div className='h-24 bg-muted rounded-lg flex items-center justify-center'>
                <span className='text-muted-foreground'>Sleep pattern chart</span>
              </div>
            </div>
          </CardContent>
        </div>
      }
    />
  );
}

export function TasteOfAIInsights({ onUpgrade }: { onUpgrade?: () => void }) {
  return (
    <TasteOfPro
      feature='ai_insights'
      title='AI Parenting Assistant'
      description='Get personalized advice, cry analysis, and answers to your parenting questions.'
      onUpgrade={onUpgrade}
      previewContent={
        <div className='p-6'>
          <CardHeader>
            <CardTitle className='flex items-center gap-2'>
              🤖 AI Assistant
              <Badge variant='outline'>Available 24/7</Badge>
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className='space-y-4'>
              <div className='space-y-3'>
                <div className='flex gap-3'>
                  <div className='w-8 h-8 bg-primary rounded-full flex items-center justify-center text-xs font-bold text-primary-foreground'>
                    Y
                  </div>
                  <div className='flex-1'>
                    <div className='bg-muted rounded-lg p-3'>
                      <p className='text-sm'>
                        My baby is 8 weeks old and wakes every 2 hours. Is this normal?
                      </p>
                    </div>
                  </div>
                </div>
                <div className='flex gap-3'>
                  <div className='w-8 h-8 bg-primary rounded-full flex items-center justify-center text-xs'>
                    🤖
                  </div>
                  <div className='flex-1'>
                    <div className='bg-primary/10 rounded-lg p-3'>
                      <p className='text-sm'>
                        Yes, this is completely normal for an 8-week-old. Newborns typically need to
                        feed every 2-3 hours around the clock...
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </CardContent>
        </div>
      }
    />
  );
}

export function TasteOfCaregiverSync({ onUpgrade }: { onUpgrade?: () => void }) {
  return (
    <TasteOfPro
      feature='caregiver_sync'
      title='Family Caregiver Sync'
      description='Share access with your partner, nanny, or family. One subscription covers everyone.'
      onUpgrade={onUpgrade}
      previewContent={
        <div className='p-6'>
          <CardHeader>
            <CardTitle className='flex items-center gap-2'>
              👨‍👩‍👧 Family Sync
              <Badge variant='outline'>3 Caregivers</Badge>
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className='space-y-4'>
              <div className='space-y-2'>
                <div className='flex items-center justify-between p-3 bg-muted rounded-lg'>
                  <div className='flex items-center gap-3'>
                    <div className='w-8 h-8 bg-blue-500 rounded-full flex items-center justify-center text-xs font-bold text-white'>
                      M
                    </div>
                    <div>
                      <div className='font-medium'>Mom</div>
                      <div className='text-xs text-muted-foreground'>Last logged: 2h ago</div>
                    </div>
                  </div>
                  <Badge variant='outline' className='text-xs'>
                    Admin
                  </Badge>
                </div>
                <div className='flex items-center justify-between p-3 bg-muted rounded-lg'>
                  <div className='flex items-center gap-3'>
                    <div className='w-8 h-8 bg-green-500 rounded-full flex items-center justify-center text-xs font-bold text-white'>
                      D
                    </div>
                    <div>
                      <div className='font-medium'>Dad</div>
                      <div className='text-xs text-muted-foreground'>Last logged: 5h ago</div>
                    </div>
                  </div>
                  <Badge variant='outline' className='text-xs'>
                    Member
                  </Badge>
                </div>
              </div>
            </div>
          </CardContent>
        </div>
      }
    />
  );
}
