import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { Baby } from '@/lib/types';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { BabySelector } from '@/components/BabySelector';
import { MobileNav } from '@/components/MobileNav';
import { ArrowLeft, Plus, BookOpen, Smile, Frown, Meh } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { format } from 'date-fns';

export default function Journal() {
  const navigate = useNavigate();
  const [selectedBaby, setSelectedBaby] = useState<Baby | null>(null);

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

  const { data: entries } = useQuery({
    queryKey: ['journal-entries', selectedBaby?.id],
    queryFn: async () => {
      if (!selectedBaby) return [];
      const { data } = await supabase
        .from('journal_entries')
        .select('*')
        .eq('baby_id', selectedBaby.id)
        .order('entry_date', { ascending: false })
        .limit(50);
      return data || [];
    },
    enabled: !!selectedBaby,
  });

  if (babies && babies.length > 0 && !selectedBaby) {
    setSelectedBaby(babies[0]);
  }

  const getMoodIcon = (mood: string) => {
    const icons: { [key: string]: any } = {
      great: <Smile className="h-5 w-5 text-green-500" />,
      good: <Smile className="h-5 w-5 text-blue-500" />,
      okay: <Meh className="h-5 w-5 text-yellow-500" />,
      challenging: <Frown className="h-5 w-5 text-orange-500" />,
      tough: <Frown className="h-5 w-5 text-red-500" />,
    };
    return icons[mood] || <Meh className="h-5 w-5" />;
  };

  return (
    <div className="min-h-screen bg-background pb-20">
      <div className="sticky top-0 z-10 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60 border-b">
        <div className="container mx-auto p-4">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-4">
              <Button onClick={() => navigate(-1)} variant="ghost" size="sm">
                <ArrowLeft className="h-4 w-4" />
              </Button>
              <div>
                <h1 className="text-2xl font-bold">Baby Journal</h1>
                <p className="text-sm text-muted-foreground">Capture daily moments</p>
              </div>
            </div>
            <Button onClick={() => navigate('/journal/new')}>
              <Plus className="mr-2 h-4 w-4" />
              New Entry
            </Button>
          </div>
          {babies && babies.length > 0 && (
            <BabySelector
              babies={babies}
              selectedBabyId={selectedBaby?.id || null}
              onSelect={(babyId) => {
                const baby = babies.find(b => b.id === babyId);
                if (baby) setSelectedBaby(baby);
              }}
            />
          )}
        </div>
      </div>

      <div className="container mx-auto p-4 space-y-4 max-w-2xl">
        {entries && entries.length > 0 ? (
          entries.map((entry: any) => (
            <Card 
              key={entry.id} 
              className="p-4 cursor-pointer hover:shadow-lg transition-shadow"
              onClick={() => navigate(`/journal/entry/${entry.id}`)}
            >
              <div className="flex items-start justify-between mb-3">
                <div>
                  <h3 className="font-semibold">{entry.title || 'Untitled Entry'}</h3>
                  <p className="text-sm text-muted-foreground">
                    {format(new Date(entry.entry_date), 'EEEE, MMMM d, yyyy')}
                  </p>
                </div>
                {entry.mood && (
                  <div className="flex items-center gap-2">
                    {getMoodIcon(entry.mood)}
                  </div>
                )}
              </div>

              <p className="text-sm line-clamp-3 text-muted-foreground">
                {entry.content}
              </p>

              {entry.firsts && entry.firsts.length > 0 && (
                <div className="mt-3 flex flex-wrap gap-2">
                  {entry.firsts.map((first: string, idx: number) => (
                    <span key={idx} className="text-xs bg-primary/10 text-primary px-2 py-1 rounded">
                      🎉 {first}
                    </span>
                  ))}
                </div>
              )}
            </Card>
          ))
        ) : (
          <Card className="p-8 text-center">
            <BookOpen className="h-12 w-12 mx-auto mb-4 text-muted-foreground" />
            <p className="text-muted-foreground">No journal entries yet</p>
            <p className="text-sm text-muted-foreground mt-2">
              Start documenting your baby's journey
            </p>
            <Button className="mt-4" onClick={() => navigate('/journal/new')}>
              Write First Entry
            </Button>
          </Card>
        )}
      </div>

      <MobileNav />
    </div>
  );
}