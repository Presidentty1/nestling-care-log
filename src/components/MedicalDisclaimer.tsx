import { Alert, AlertDescription } from '@/components/ui/alert';
import { AlertTriangle, Info } from 'lucide-react';
import { cn } from '@/lib/utils';

type DisclaimerVariant = 'ai' | 'sleep' | 'predictions';

interface MedicalDisclaimerProps {
  variant?: DisclaimerVariant;
  className?: string;
}

const disclaimerContent = {
  ai: {
    icon: AlertTriangle,
    text: (
      <>
        <strong>Medical Disclaimer:</strong> This AI assistant provides general information only and
        is not a substitute for professional medical advice. Always consult your pediatrician for
        health concerns.
      </>
    ),
  },
  sleep: {
    icon: Info,
    text: (
      <>
        This guidance is based on typical patterns and is not medical advice. Always follow your
        pediatrician's recommendations.
      </>
    ),
  },
  predictions: {
    icon: Info,
    text: (
      <>
        Predictions are based on typical patterns and your baby's data. This is not medical
        advice—always consult your pediatrician.
      </>
    ),
  },
};

export function MedicalDisclaimer({ variant = 'ai', className }: MedicalDisclaimerProps) {
  const { icon: Icon, text } = disclaimerContent[variant];

  return (
    <Alert className={cn('mb-4', className)} variant={variant === 'ai' ? 'default' : 'default'}>
      <Icon className='h-4 w-4' />
      <AlertDescription className='text-xs leading-relaxed'>{text}</AlertDescription>
    </Alert>
  );
}
