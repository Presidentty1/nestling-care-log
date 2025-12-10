import type { Baby } from '@/lib/types';
import { CDCVaccineSchedule } from '@/lib/vaccineSchedule';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { differenceInWeeks } from 'date-fns';
import { CheckCircle2, Clock } from 'lucide-react';

interface VaccineScheduleViewProps {
  baby: Baby;
  completedVaccines: string[];
}

export function VaccineScheduleView({ baby, completedVaccines }: VaccineScheduleViewProps) {
  const babyAgeWeeks = differenceInWeeks(new Date(), new Date(baby.date_of_birth));

  const upcomingVaccines = CDCVaccineSchedule.filter(
    v =>
      babyAgeWeeks >= v.windowStartWeeks &&
      babyAgeWeeks <= v.windowEndWeeks + 4 &&
      !completedVaccines.includes(v.name)
  ).sort((a, b) => a.recommendedAgeWeeks - b.recommendedAgeWeeks);

  const overdueVaccines = CDCVaccineSchedule.filter(
    v => babyAgeWeeks > v.windowEndWeeks && !completedVaccines.includes(v.name)
  );

  return (
    <div className='space-y-4'>
      {overdueVaccines.length > 0 && (
        <Card className='border-destructive'>
          <CardHeader>
            <CardTitle className='text-destructive flex items-center gap-2'>
              <Clock className='h-5 w-5' />
              Overdue Vaccines
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className='space-y-2'>
              {overdueVaccines.map(vaccine => (
                <div key={vaccine.name} className='p-2 bg-destructive/10 rounded-lg'>
                  <div className='font-medium'>{vaccine.name}</div>
                  <div className='text-sm text-muted-foreground'>{vaccine.description}</div>
                  <div className='text-xs text-destructive mt-1'>
                    Recommended at {Math.floor(vaccine.recommendedAgeWeeks / 4)} months
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {upcomingVaccines.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className='flex items-center gap-2'>
              <Clock className='h-5 w-5' />
              Upcoming Vaccines
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className='space-y-2'>
              {upcomingVaccines.map(vaccine => (
                <div key={vaccine.name} className='p-2 bg-muted/50 rounded-lg'>
                  <div className='flex items-start justify-between'>
                    <div>
                      <div className='font-medium'>{vaccine.name}</div>
                      <div className='text-sm text-muted-foreground'>{vaccine.description}</div>
                      <div className='text-xs text-muted-foreground mt-1'>
                        Recommended: {Math.floor(vaccine.recommendedAgeWeeks / 4)} months
                      </div>
                    </div>
                    {vaccine.required && <Badge variant='secondary'>Required</Badge>}
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {completedVaccines.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className='flex items-center gap-2'>
              <CheckCircle2 className='h-5 w-5 text-green-600' />
              Completed Vaccines
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className='space-y-1'>
              {completedVaccines.map(name => {
                const vaccine = CDCVaccineSchedule.find(v => v.name === name);
                return (
                  <div key={name} className='text-sm text-muted-foreground'>
                    ✓ {name} {vaccine && `(${vaccine.description})`}
                  </div>
                );
              })}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
