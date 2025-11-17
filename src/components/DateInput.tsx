import { useState, useEffect } from 'react';
import { Calendar } from '@/components/ui/calendar';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { CalendarIcon } from 'lucide-react';
import { format } from 'date-fns';
import { cn } from '@/lib/utils';

interface DateInputProps {
  value: string; // ISO date string (YYYY-MM-DD)
  onChange: (date: string) => void;
  maxDate?: Date;
  placeholder?: string;
}

export function DateInput({ 
  value, 
  onChange, 
  maxDate = new Date(),
  placeholder = 'MM/DD/YYYY'
}: DateInputProps) {
  const [isOpen, setIsOpen] = useState(false);
  const [inputValue, setInputValue] = useState('');

  useEffect(() => {
    if (value) {
      try {
        setInputValue(format(new Date(value), 'MM/dd/yyyy'));
      } catch {
        setInputValue('');
      }
    } else {
      setInputValue('');
    }
  }, [value]);

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const val = e.target.value;
    setInputValue(val);

    // Parse MM/DD/YYYY
    const match = val.match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/);
    if (match) {
      const [_, month, day, year] = match;
      const date = new Date(parseInt(year), parseInt(month) - 1, parseInt(day));
      if (!isNaN(date.getTime()) && date <= maxDate) {
        onChange(date.toISOString().split('T')[0]);
      }
    }
  };

  const handleCalendarSelect = (date: Date | undefined) => {
    if (date) {
      onChange(date.toISOString().split('T')[0]);
      setInputValue(format(date, 'MM/dd/yyyy'));
      setIsOpen(false);
    }
  };

  const handleTodayClick = () => {
    const today = new Date();
    onChange(today.toISOString().split('T')[0]);
    setInputValue(format(today, 'MM/dd/yyyy'));
  };

  return (
    <div className="flex gap-2">
      <Input
        type="text"
        value={inputValue}
        onChange={handleInputChange}
        placeholder={placeholder}
        className="flex-1"
      />
      <Popover open={isOpen} onOpenChange={setIsOpen}>
        <PopoverTrigger asChild>
          <Button variant="outline" size="icon">
            <CalendarIcon className="h-4 w-4" />
          </Button>
        </PopoverTrigger>
        <PopoverContent className="w-auto p-0" align="start">
          <Calendar
            mode="single"
            selected={value ? new Date(value) : undefined}
            onSelect={handleCalendarSelect}
            disabled={(date) => date > maxDate}
            initialFocus
            className={cn("p-3 pointer-events-auto")}
          />
        </PopoverContent>
      </Popover>
      <Button variant="outline" size="sm" onClick={handleTodayClick}>
        Today
      </Button>
    </div>
  );
}
