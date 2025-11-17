import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { Check, Plus } from 'lucide-react';
import { Baby } from '@/types/events';
import { getAgeDisplay } from '@/services/time';

interface BabySwitcherModalProps {
  babies: Baby[];
  activeBabyId: string | null;
  isOpen: boolean;
  onClose: () => void;
  onSelect: (babyId: string) => void;
  onAddNew: () => void;
}

export function BabySwitcherModal({
  babies,
  activeBabyId,
  isOpen,
  onClose,
  onSelect,
  onAddNew,
}: BabySwitcherModalProps) {
  const getInitials = (name: string) => {
    return name
      .split(' ')
      .map(n => n[0])
      .join('')
      .toUpperCase()
      .slice(0, 2);
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Switch Baby</DialogTitle>
        </DialogHeader>
        <div className="space-y-2">
          {babies.map((baby) => (
            <button
              key={baby.id}
              onClick={() => {
                onSelect(baby.id);
                onClose();
              }}
              className="w-full flex items-center gap-3 p-3 rounded-lg hover:bg-accent transition-colors"
            >
              <Avatar>
                <AvatarFallback>{getInitials(baby.name)}</AvatarFallback>
              </Avatar>
              <div className="flex-1 text-left">
                <div className="font-medium">{baby.name}</div>
                <div className="text-sm text-muted-foreground">
                  {getAgeDisplay(baby.dobISO)}
                </div>
              </div>
              {baby.id === activeBabyId && (
                <Check className="h-5 w-5 text-primary" />
              )}
            </button>
          ))}
          
          <Button
            variant="outline"
            className="w-full"
            onClick={() => {
              onAddNew();
              onClose();
            }}
          >
            <Plus className="mr-2 h-4 w-4" />
            Add New Baby
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}
