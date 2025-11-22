import type { Baby } from '@/lib/types';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { differenceInMonths, differenceInWeeks } from 'date-fns';

interface BabySelectorProps {
  babies: Baby[];
  selectedBabyId: string | null;
  onSelect: (babyId: string) => void;
}

export function BabySelector({ babies, selectedBabyId, onSelect }: BabySelectorProps) {
  if (babies.length <= 1) return null;

  const getAgeLabel = (dateOfBirth: string) => {
    const now = new Date();
    const dob = new Date(dateOfBirth);
    const months = differenceInMonths(now, dob);
    const weeks = differenceInWeeks(now, dob);

    if (months >= 12) {
      const years = Math.floor(months / 12);
      return `${years} ${years === 1 ? 'year' : 'years'}`;
    } else if (months > 0) {
      return `${months} ${months === 1 ? 'month' : 'months'}`;
    } else {
      return `${weeks} ${weeks === 1 ? 'week' : 'weeks'}`;
    }
  };

  return (
    <Select value={selectedBabyId || ''} onValueChange={onSelect}>
      <SelectTrigger className="w-[200px]">
        <SelectValue placeholder="Select baby" />
      </SelectTrigger>
      <SelectContent>
        {babies.map((baby) => (
          <SelectItem key={baby.id} value={baby.id}>
            👶 {baby.name} · {getAgeLabel(baby.date_of_birth)}
          </SelectItem>
        ))}
      </SelectContent>
    </Select>
  );
}
