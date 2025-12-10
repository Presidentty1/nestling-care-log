import { Button } from '@/components/ui/button';

interface MoodTrackerProps {
  currentMood?: string;
  onMoodSelect: (mood: string) => void;
}

const moods = [
  { value: 'great', emoji: '😄', label: 'Great' },
  { value: 'good', emoji: '🙂', label: 'Good' },
  { value: 'okay', emoji: '😐', label: 'Okay' },
  { value: 'tired', emoji: '😴', label: 'Tired' },
  { value: 'stressed', emoji: '😰', label: 'Stressed' },
];

export function MoodTracker({ currentMood, onMoodSelect }: MoodTrackerProps) {
  return (
    <div className='space-y-3'>
      <div className='flex items-center gap-2'>
        <span className='text-sm font-medium'>Your Mood</span>
      </div>
      <div className='grid grid-cols-5 gap-2'>
        {moods.map(mood => (
          <Button
            key={mood.value}
            variant={currentMood === mood.value ? 'default' : 'outline'}
            onClick={() => onMoodSelect(mood.value)}
            className='flex flex-col h-auto py-3'
          >
            <span className='text-2xl mb-1'>{mood.emoji}</span>
            <span className='text-xs'>{mood.label}</span>
          </Button>
        ))}
      </div>
    </div>
  );
}
