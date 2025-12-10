import { useState, useEffect } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { useToast } from '@/hooks/use-toast';
import { ArrowLeft, Save, Smile, Meh, Frown } from 'lucide-react';
import { validateJournalEntry } from '@/services/validation';
import { journalService } from '@/services/journalService';
import { useAppStore } from '@/store/appStore';

export default function JournalEntry() {
  const navigate = useNavigate();
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const { id } = useParams();
  const isNew = id === 'new';
  const { activeBabyId } = useAppStore();

  const [formData, setFormData] = useState({
    title: '',
    content: '',
    mood: 'good',
    entry_date: new Date().toISOString().split('T')[0],
    weather: '',
    activities: [] as string[],
    firsts: [] as string[],
    funny_moments: [] as string[],
  });

  const { data: entry } = useQuery({
    queryKey: ['journal-entry', id],
    queryFn: async () => {
      if (isNew) return null;
      return await journalService.getJournalEntry(id!);
    },
    enabled: !isNew && !!id,
  });

  useEffect(() => {
    if (entry) {
      setFormData({
        title: entry.title || '',
        content: entry.content || '',
        mood: entry.mood || 'good',
        entry_date: entry.entry_date,
        weather: entry.weather || '',
        activities: entry.activities || [],
        firsts: entry.firsts || [],
        funny_moments: entry.funny_moments || [],
      });
    }
  }, [entry]);

  const saveMutation = useMutation({
    mutationFn: async () => {
      // Get baby ID
      let babyId = activeBabyId;
      if (!babyId) {
        const selectedBabyId =
          localStorage.getItem('selectedBabyId') || localStorage.getItem('activeBabyId');
        if (!selectedBabyId) throw new Error('No baby selected');
        babyId = selectedBabyId;
      }

      // Prepare entry data
      const entryData = {
        ...formData,
        baby_id: babyId,
      };

      // Validate entry data
      const validationResult = validateJournalEntry(entryData);
      if (!validationResult.success) {
        throw new Error(validationResult.error.issues[0].message);
      }

      // Perform database operations
      if (isNew) {
        await journalService.createJournalEntry(validationResult.data);
      } else if (id) {
        await journalService.updateJournalEntry(id, validationResult.data);
      }

      return babyId;
    },
    mutationKey: ['save-journal-entry'],
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['journal-entries'] });
      toast({ title: isNew ? 'Entry created!' : 'Entry updated!' });
      navigate('/journal');
    },
    onError: (error: any) => {
      toast({
        title: 'Failed to save entry',
        description: error.message,
        variant: 'destructive',
      });
    },
  });

  return (
    <div className='min-h-screen bg-background pb-20'>
      <div className='sticky top-0 z-10 bg-background/95 backdrop-blur border-b'>
        <div className='container mx-auto p-4'>
          <div className='flex items-center justify-between'>
            <div className='flex items-center gap-4'>
              <Button onClick={() => navigate(-1)} variant='ghost' size='sm'>
                <ArrowLeft className='h-4 w-4' />
              </Button>
              <h1 className='text-2xl font-bold'>{isNew ? 'New Entry' : 'Edit Entry'}</h1>
            </div>
            <Button
              onClick={() => saveMutation.mutate()}
              disabled={saveMutation.isPending || !activeBabyId}
            >
              <Save className='mr-2 h-4 w-4' />
              Save
            </Button>
          </div>
        </div>
      </div>

      <div className='container mx-auto p-4 max-w-2xl space-y-4'>
        <Card className='p-6 space-y-4'>
          <div>
            <Label>Date</Label>
            <Input
              type='date'
              value={formData.entry_date}
              onChange={e => setFormData({ ...formData, entry_date: e.target.value })}
            />
          </div>

          <div>
            <Label>Title (Optional)</Label>
            <Input
              value={formData.title}
              onChange={e => setFormData({ ...formData, title: e.target.value })}
              placeholder='A special day...'
            />
          </div>

          <div>
            <Label>Mood</Label>
            <Select
              value={formData.mood}
              onValueChange={value => setFormData({ ...formData, mood: value })}
            >
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value='great'>😊 Great</SelectItem>
                <SelectItem value='good'>🙂 Good</SelectItem>
                <SelectItem value='okay'>😐 Okay</SelectItem>
                <SelectItem value='challenging'>😰 Challenging</SelectItem>
                <SelectItem value='tough'>😫 Tough</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <div>
            <Label>What happened today?</Label>
            <Textarea
              value={formData.content}
              onChange={e => setFormData({ ...formData, content: e.target.value })}
              placeholder='Write about your day...'
              rows={8}
            />
          </div>

          <div>
            <Label>Weather (Optional)</Label>
            <Select
              value={formData.weather}
              onValueChange={value => setFormData({ ...formData, weather: value })}
            >
              <SelectTrigger>
                <SelectValue placeholder='Select weather' />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value='sunny'>☀️ Sunny</SelectItem>
                <SelectItem value='cloudy'>☁️ Cloudy</SelectItem>
                <SelectItem value='rainy'>🌧️ Rainy</SelectItem>
                <SelectItem value='snowy'>❄️ Snowy</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </Card>
      </div>
    </div>
  );
}
