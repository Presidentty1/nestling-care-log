import { Baby } from '@/lib/types';
import {
  Drawer,
  DrawerContent,
  DrawerHeader,
  DrawerTitle,
} from '@/components/ui/drawer';
import { Button } from '@/components/ui/button';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { Plus } from 'lucide-react';
import { differenceInMonths, differenceInWeeks } from 'date-fns';
import { useNavigate } from 'react-router-dom';
import { track } from '@/analytics/analytics';

interface BabySwitcherProps {
  babies: Baby[];
  selectedBabyId: string | null;
  onSelect: (babyId: string) => void;
  isOpen: boolean;
  onClose: () => void;
}

export function BabySwitcher({ babies, selectedBabyId, onSelect, isOpen, onClose }: BabySwitcherProps) {
  const navigate = useNavigate();

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

  const getInitials = (name: string) => {
    return name
      .split(' ')
      .map(n => n[0])
      .join('')
      .toUpperCase()
      .slice(0, 2);
  };

  const handleSelect = (babyId: string) => {
    // Track analytics
    if (selectedBabyId && selectedBabyId !== babyId) {
      track('baby_switched', {
        from_baby_id: selectedBabyId,
        to_baby_id: babyId
      });
    }
    
    onSelect(babyId);
    onClose();
  };

  const handleAddBaby = () => {
    navigate('/manage-babies');
    onClose();
  };

  if (babies.length <= 1) return null;

  return (
    <Drawer open={isOpen} onOpenChange={onClose}>
      <DrawerContent className="rounded-t-[24px]">
        <DrawerHeader>
          <DrawerTitle>Switch Baby</DrawerTitle>
        </DrawerHeader>
        <div className="px-4 pb-8 space-y-2">
          {babies.map((baby) => (
            <button
              key={baby.id}
              onClick={() => handleSelect(baby.id)}
              className={`
                w-full flex items-center gap-3 p-4 rounded-lg transition-colors
                ${selectedBabyId === baby.id 
                  ? 'bg-primary/10 border-2 border-primary' 
                  : 'bg-muted hover:bg-muted/80 border-2 border-transparent'
                }
              `}
            >
              <Avatar className="h-12 w-12">
                <AvatarFallback className="bg-primary text-primary-foreground text-lg">
                  {getInitials(baby.name)}
                </AvatarFallback>
              </Avatar>
              <div className="flex-1 text-left">
                <p className="font-medium">{baby.name}</p>
                <p className="text-sm text-muted-foreground">{getAgeLabel(baby.date_of_birth)}</p>
              </div>
            </button>
          ))}
          <Button
            variant="outline"
            className="w-full mt-4"
            onClick={handleAddBaby}
          >
            <Plus className="h-4 w-4 mr-2" />
            Add Baby
          </Button>
        </div>
      </DrawerContent>
    </Drawer>
  );
}
