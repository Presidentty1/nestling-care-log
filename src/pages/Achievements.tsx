import { useEffect, useState } from 'react';
import { MobileNav } from '@/components/MobileNav';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import type { Achievement } from '@/services/achievementService';
import { achievementService } from '@/services/achievementService';
import { useAppStore } from '@/store/appStore';
import { Lock, Trophy } from 'lucide-react';
import { format } from 'date-fns';

export default function Achievements() {
  const { activeBabyId } = useAppStore();
  const [allAchievements, setAllAchievements] = useState<Achievement[]>([]);
  const [unlocked, setUnlocked] = useState<Set<string>>(new Set());

  useEffect(() => {
    loadAchievements();
  }, [activeBabyId]);

  const loadAchievements = async () => {
    if (!activeBabyId) return;

    const all = await achievementService.getAllAchievements();
    const unlockedList = await achievementService.getUnlockedAchievements(activeBabyId);

    setAllAchievements(all);
    setUnlocked(new Set(unlockedList.map(a => a.id)));
  };

  const unlockedCount = unlocked.size;
  const totalCount = allAchievements.length;
  const progress = totalCount > 0 ? (unlockedCount / totalCount) * 100 : 0;

  return (
    <div className='min-h-screen bg-surface pb-20'>
      <div className='max-w-2xl mx-auto p-4 space-y-4'>
        <div className='flex items-center justify-between'>
          <h1 className='text-2xl font-bold'>Achievements</h1>
          <Badge variant='outline' className='text-base'>
            <Trophy className='h-4 w-4 mr-1' />
            {unlockedCount}/{totalCount}
          </Badge>
        </div>

        {/* Progress bar */}
        <Card>
          <CardHeader>
            <CardTitle className='text-lg'>Your Progress</CardTitle>
            <CardDescription>Keep logging to unlock all achievements</CardDescription>
          </CardHeader>
          <CardContent>
            <div className='w-full h-3 bg-muted rounded-full overflow-hidden'>
              <div
                className='h-full bg-gradient-to-r from-primary to-primary/80 transition-all duration-500'
                style={{ width: `${progress}%` }}
              />
            </div>
            <p className='text-sm text-muted-foreground mt-2 text-center'>
              {Math.round(progress)}% complete
            </p>
          </CardContent>
        </Card>

        {/* Achievement grid */}
        <div className='grid gap-3'>
          {allAchievements.map(achievement => {
            const isUnlocked = unlocked.has(achievement.id);

            return (
              <Card key={achievement.id} className={!isUnlocked ? 'opacity-60' : ''}>
                <CardContent className='p-4 flex items-center gap-4'>
                  <div
                    className={`
                    w-14 h-14 rounded-full flex items-center justify-center text-2xl shrink-0
                    ${isUnlocked ? 'bg-gradient-to-br from-primary to-primary/60' : 'bg-muted'}
                  `}
                  >
                    {isUnlocked ? (
                      achievement.icon
                    ) : (
                      <Lock className='h-6 w-6 text-muted-foreground' />
                    )}
                  </div>

                  <div className='flex-1 min-w-0'>
                    <h3 className='font-semibold flex items-center gap-2'>
                      {achievement.title}
                      {isUnlocked && (
                        <Badge variant='outline' className='text-xs'>
                          Unlocked
                        </Badge>
                      )}
                    </h3>
                    <p className='text-sm text-muted-foreground mt-0.5'>
                      {achievement.description}
                    </p>
                  </div>
                </CardContent>
              </Card>
            );
          })}
        </div>
      </div>
      <MobileNav />
    </div>
  );
}
