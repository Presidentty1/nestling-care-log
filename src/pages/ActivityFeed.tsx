import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { familyService } from '@/services/familyService';
import { authService } from '@/services/authService';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { MobileNav } from '@/components/MobileNav';
import { ArrowLeft, Users } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { formatDistanceToNow } from 'date-fns';

export default function ActivityFeed() {
  const navigate = useNavigate();

  const { data: families } = useQuery({
    queryKey: ['user-families'],
    queryFn: async () => {
      const { user } = await authService.getUser();
      if (!user) return [];
      return await familyService.getUserFamilies();
    },
  });

  const familyId = families?.[0]?.id;

  const { data: activities } = useQuery({
    queryKey: ['activity-feed', familyId],
    queryFn: async () => {
      if (!familyId) return [];
      return await familyService.getActivityFeed(familyId);
    },
    enabled: !!familyId,
  });

  const getActivityIcon = (actionType: string) => {
    const icons: { [key: string]: string } = {
      logged_event: '📝',
      added_milestone: '🎉',
      updated_health: '💊',
      added_photo: '📷',
      created_journal: '📖',
    };
    return icons[actionType] || '•';
  };

  return (
    <div className="min-h-screen bg-background pb-20">
      <div className="sticky top-0 z-10 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60 border-b">
        <div className="container mx-auto p-4">
          <div className="flex items-center gap-4">
            <Button onClick={() => navigate(-1)} variant="ghost" size="sm">
              <ArrowLeft className="h-4 w-4" />
            </Button>
            <div>
              <h1 className="text-2xl font-bold">Family Activity</h1>
              <p className="text-sm text-muted-foreground">See what everyone's been up to</p>
            </div>
          </div>
        </div>
      </div>

      <div className="container mx-auto p-4 space-y-3 max-w-2xl">
        {activities && activities.length > 0 ? (
          activities.map((activity: any) => (
            <Card key={activity.id} className="p-4">
              <div className="flex gap-3">
                <div className="flex-shrink-0">
                  <Avatar className="h-10 w-10">
                    <AvatarFallback>
                      {activity.profiles?.name?.[0] || activity.profiles?.email?.[0] || '?'}
                    </AvatarFallback>
                  </Avatar>
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-start justify-between gap-2">
                    <p className="text-sm">
                      <span className="font-medium">
                        {activity.profiles?.name || activity.profiles?.email?.split('@')[0] || 'Someone'}
                      </span>
                      {' '}
                      <span className="text-muted-foreground">{activity.summary}</span>
                    </p>
                    <span className="text-2xl flex-shrink-0">
                      {getActivityIcon(activity.action_type)}
                    </span>
                  </div>
                  <p className="text-xs text-muted-foreground mt-1">
                    {formatDistanceToNow(new Date(activity.created_at), { addSuffix: true })}
                  </p>
                </div>
              </div>
            </Card>
          ))
        ) : (
          <Card className="p-8 text-center">
            <Users className="h-12 w-12 mx-auto mb-4 text-muted-foreground" />
            <p className="text-muted-foreground">No recent activity</p>
            <p className="text-sm text-muted-foreground mt-2">
              Activities from your family will appear here
            </p>
          </Card>
        )}
      </div>

      <MobileNav />
    </div>
  );
}