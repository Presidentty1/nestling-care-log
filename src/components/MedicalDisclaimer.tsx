import { Alert, AlertDescription } from '@/components/ui/alert';
import { AlertTriangle } from 'lucide-react';

export function MedicalDisclaimer() {
  return (
    <Alert className="mb-4">
      <AlertTriangle className="h-4 w-4" />
      <AlertDescription className="text-xs">
        <strong>Medical Disclaimer:</strong> This AI assistant provides general information only 
        and is not a substitute for professional medical advice. Always consult your pediatrician 
        for health concerns.
      </AlertDescription>
    </Alert>
  );
}