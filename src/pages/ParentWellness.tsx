import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/hooks/useAuth';
import { supabase } from '@/integrations/supabase/client';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { MobileNav } from '@/components/MobileNav';
import { Heart, Droplets, Moon, Pill, ArrowLeft } from 'lucide-react';
import { MoodTracker } from '@/components/MoodTracker';
import { WaterIntakeTracker } from '@/components/WaterIntakeTracker';
import { ParentMedicationTracker } from '@/components/ParentMedicationTracker';
import { toast } from 'sonner';
import { format } from 'date-fns';

export default function ParentWellness() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [selectedDate, setSelectedDate] = useState<Date>(new Date());
  const [todayLog, setTodayLog] = useState<any>(null);
  const [medications, setMedications] = useState<any[]>([]);

  useEffect(() => {
    if (!user) {
      navigate('/auth');
      return;
    }
    loadTodayLog();
    loadMedications();
  }, [user, navigate, selectedDate]);

  const loadTodayLog = async () => {
    if (!user) return;

    try {
      const dateStr = format(selectedDate, 'yyyy-MM-dd');
      const { data, error } = await supabase
        .from('parent_wellness_logs')
        .select('*')
        .eq('user_id', user.id)
        .eq('log_date', dateStr)
        .maybeSingle();

      if (error && error.code !== 'PGRST116') throw error;
      setTodayLog(data);
    } catch (error) {
      console.error('Error loading wellness log:', error);
    }
  };

  const loadMedications = async () => {
    if (!user) return;

    try {
      const { data, error } = await supabase
        .from('parent_medications')
        .select('*')
        .eq('user_id', user.id)
        .eq('is_active', true)
        .order('created_at', { ascending: false });

      if (error) throw error;
      setMedications(data || []);
    } catch (error) {
      console.error('Error loading medications:', error);
    }
  };

  const handleMoodUpdate = async (mood: string) => {
    if (!user) return;

    try {
      const dateStr = format(selectedDate, 'yyyy-MM-dd');
      const { error } = await supabase
        .from('parent_wellness_logs')
        .upsert({
          user_id: user.id,
          log_date: dateStr,
          mood,
        }, {
          onConflict: 'user_id,log_date',
        });

      if (error) throw error;
      toast.success('Mood recorded!');
      loadTodayLog();
    } catch (error) {
      console.error('Error saving mood:', error);
      toast.error('Failed to save mood');
    }
  };

  const handleWaterUpdate = async (amount: number) => {
    if (!user) return;

    try {
      const dateStr = format(selectedDate, 'yyyy-MM-dd');
      const currentWater = todayLog?.water_intake_ml || 0;
      const { error } = await supabase
        .from('parent_wellness_logs')
        .upsert({
          user_id: user.id,
          log_date: dateStr,
          water_intake_ml: currentWater + amount,
        }, {
          onConflict: 'user_id,log_date',
        });

      if (error) throw error;
      loadTodayLog();
    } catch (error) {
      console.error('Error saving water intake:', error);
      toast.error('Failed to save water intake');
    }
  };

  const handleSleepQualityUpdate = async (quality: string) => {
    if (!user) return;

    try {
      const dateStr = format(selectedDate, 'yyyy-MM-dd');
      const { error } = await supabase
        .from('parent_wellness_logs')
        .upsert({
          user_id: user.id,
          log_date: dateStr,
          sleep_quality: quality,
        }, {
          onConflict: 'user_id,log_date',
        });

      if (error) throw error;
      toast.success('Sleep quality recorded!');
      loadTodayLog();
    } catch (error) {
      console.error('Error saving sleep quality:', error);
      toast.error('Failed to save sleep quality');
    }
  };

  return (
    <div className="min-h-screen bg-surface pb-20">
      <div className="max-w-2xl mx-auto p-4 space-y-4">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Button
              variant="ghost"
              size="sm"
              onClick={() => navigate('/settings')}
            >
              <ArrowLeft className="h-4 w-4" />
            </Button>
            <div>
              <h1 className="text-headline">Parent Wellness</h1>
              <p className="text-sm text-muted-foreground">Take care of yourself too 💚</p>
            </div>
          </div>
          <Badge variant="secondary">Beta</Badge>
        </div>

        {/* Info Card */}
        <Card className="bg-primary/5 border-primary/20">
          <CardContent className="p-4">
            <p className="text-sm text-foreground">
              💡 Self-care isn't selfish. Tracking your wellness helps you be your best for your baby.
            </p>
          </CardContent>
        </Card>

        {/* Quick Check-In */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Heart className="h-5 w-5 text-primary" />
              Quick Check-In
            </CardTitle>
            <CardDescription>How are you feeling today?</CardDescription>
          </CardHeader>
          <CardContent className="space-y-6">
            <MoodTracker
              currentMood={todayLog?.mood}
              onMoodSelect={handleMoodUpdate}
            />

            <div className="border-t pt-4">
              <WaterIntakeTracker
                currentIntake={todayLog?.water_intake_ml || 0}
                onAddWater={handleWaterUpdate}
              />
            </div>

            <div className="border-t pt-4">
              <div className="space-y-3">
                <div className="flex items-center gap-2">
                  <Moon className="h-4 w-4 text-muted-foreground" />
                  <span className="text-sm font-medium">Sleep Quality</span>
                </div>
                <div className="flex gap-2">
                  {['great', 'good', 'fair', 'poor'].map((quality) => (
                    <Button
                      key={quality}
                      variant={todayLog?.sleep_quality === quality ? 'default' : 'outline'}
                      size="sm"
                      onClick={() => handleSleepQualityUpdate(quality)}
                      className="flex-1 capitalize"
                    >
                      {quality}
                    </Button>
                  ))}
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Medications & Supplements */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Pill className="h-5 w-5 text-primary" />
              Medications & Supplements
            </CardTitle>
            <CardDescription>Track what you're taking</CardDescription>
          </CardHeader>
          <CardContent>
            <ParentMedicationTracker
              medications={medications}
              onRefresh={loadMedications}
            />
          </CardContent>
        </Card>
      </div>
      <MobileNav />
    </div>
  );
}
