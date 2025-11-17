import { ReactNode } from 'react';
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetFooter,
} from '@/components/ui/sheet';
import { Button } from '@/components/ui/button';
import { X } from 'lucide-react';

interface SheetFrameProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  title: string;
  children: ReactNode;
  onSave?: () => void;
  onCancel?: () => void;
  saveLabel?: string;
  cancelLabel?: string;
  saveDisabled?: boolean;
  isLoading?: boolean;
  footerContent?: ReactNode;
}

export function SheetFrame({
  open,
  onOpenChange,
  title,
  children,
  onSave,
  onCancel,
  saveLabel = 'Save',
  cancelLabel = 'Cancel',
  saveDisabled = false,
  isLoading = false,
  footerContent,
}: SheetFrameProps) {
  const handleCancel = () => {
    onCancel?.();
    onOpenChange(false);
  };

  const handleSave = () => {
    onSave?.();
  };

  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent 
        side="bottom" 
        className="rounded-t-[24px] max-h-[90vh] overflow-y-auto"
      >
        {/* Drag handle */}
        <div className="flex justify-center pt-3 pb-2">
          <div className="w-10 h-1 rounded-full bg-muted/40" />
        </div>
        
        <SheetHeader className="relative pb-4">
          <SheetTitle className="text-center pr-8">{title}</SheetTitle>
          <Button
            variant="ghost"
            size="icon"
            className="absolute right-0 top-0 h-8 w-8"
            onClick={handleCancel}
            aria-label="Close"
          >
            <X className="h-4 w-4" />
          </Button>
        </SheetHeader>

        <div className="py-4">
          {children}
        </div>

        {(onSave || footerContent) && (
          <SheetFooter className="flex-row gap-2 pt-4 border-t">
            {footerContent ? (
              footerContent
            ) : (
              <>
                <Button
                  variant="outline"
                  onClick={handleCancel}
                  disabled={isLoading}
                  className="flex-1"
                >
                  {cancelLabel}
                </Button>
                <Button
                  onClick={handleSave}
                  disabled={saveDisabled || isLoading}
                  className="flex-1"
                >
                  {isLoading ? 'Saving...' : saveLabel}
                </Button>
              </>
            )}
          </SheetFooter>
        )}
      </SheetContent>
    </Sheet>
  );
}
