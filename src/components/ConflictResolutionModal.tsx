import React, { useState } from 'react';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { AlertTriangle, Clock, User } from 'lucide-react';
import { track } from '@/analytics/analytics';

export interface DataConflict {
  id: string;
  localData: any;
  remoteData: any;
  field: string;
  localTimestamp: Date;
  remoteTimestamp: Date;
  remoteUser?: string;
  type: 'event' | 'baby' | 'settings';
}

interface ConflictResolutionModalProps {
  conflict: DataConflict;
  isOpen: boolean;
  onResolve: (resolution: 'local' | 'remote' | 'merge') => void;
  onDismiss: () => void;
}

export function ConflictResolutionModal({
  conflict,
  isOpen,
  onResolve,
  onDismiss
}: ConflictResolutionModalProps) {
  const [selectedResolution, setSelectedResolution] = useState<'local' | 'remote' | 'merge' | null>(null);

  const handleResolve = (resolution: 'local' | 'remote' | 'merge') => {
    setSelectedResolution(resolution);
    onResolve(resolution);

    track('conflict_resolved', {
      conflict_id: conflict.id,
      resolution,
      conflict_type: conflict.type,
      field: conflict.field
    });
  };

  const formatValue = (value: any): string => {
    if (value instanceof Date) {
      return value.toLocaleString();
    }
    if (typeof value === 'boolean') {
      return value ? 'Yes' : 'No';
    }
    return String(value);
  };

  const getConflictDescription = () => {
    switch (conflict.type) {
      case 'event':
        return `The ${conflict.field} of an event was changed by both you and ${conflict.remoteUser || 'another caregiver'}.`;
      case 'baby':
        return `Baby information was updated by both you and ${conflict.remoteUser || 'another caregiver'}.`;
      case 'settings':
        return `Settings were changed by both you and ${conflict.remoteUser || 'another caregiver'}.`;
      default:
        return 'Data was modified by multiple people.';
    }
  };

  return (
    <Dialog open={isOpen} onOpenChange={onDismiss}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <AlertTriangle className="h-5 w-5 text-orange-500" />
            Data Conflict Detected
          </DialogTitle>
          <DialogDescription>
            {getConflictDescription()}
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4">
          {/* Local version */}
          <div className="border rounded-lg p-3 bg-blue-50">
            <div className="flex items-center justify-between mb-2">
              <div className="flex items-center gap-2">
                <User className="h-4 w-4 text-blue-600" />
                <span className="font-medium text-blue-900">Your Version</span>
              </div>
              <Badge variant="outline" className="text-xs">
                <Clock className="h-3 w-3 mr-1" />
                {conflict.localTimestamp.toLocaleTimeString()}
              </Badge>
            </div>
            <div className="text-sm text-blue-800">
              <strong>{conflict.field}:</strong> {formatValue(conflict.localData)}
            </div>
          </div>

          {/* Remote version */}
          <div className="border rounded-lg p-3 bg-green-50">
            <div className="flex items-center justify-between mb-2">
              <div className="flex items-center gap-2">
                <User className="h-4 w-4 text-green-600" />
                <span className="font-medium text-green-900">
                  {conflict.remoteUser || 'Other Caregiver'}
                </span>
              </div>
              <Badge variant="outline" className="text-xs">
                <Clock className="h-3 w-3 mr-1" />
                {conflict.remoteTimestamp.toLocaleTimeString()}
              </Badge>
            </div>
            <div className="text-sm text-green-800">
              <strong>{conflict.field}:</strong> {formatValue(conflict.remoteData)}
            </div>
          </div>

          {/* Resolution options */}
          <div className="space-y-2">
            <h4 className="font-medium text-sm">Choose how to resolve this conflict:</h4>

            <div className="space-y-2">
              <Button
                variant={selectedResolution === 'local' ? 'default' : 'outline'}
                className="w-full justify-start"
                onClick={() => handleResolve('local')}
              >
                <div className="text-left">
                  <div className="font-medium">Keep Your Changes</div>
                  <div className="text-xs opacity-70">Discard the other version</div>
                </div>
              </Button>

              <Button
                variant={selectedResolution === 'remote' ? 'default' : 'outline'}
                className="w-full justify-start"
                onClick={() => handleResolve('remote')}
              >
                <div className="text-left">
                  <div className="font-medium">Use Their Changes</div>
                  <div className="text-xs opacity-70">Discard your version</div>
                </div>
              </Button>

              {conflict.type === 'event' && (
                <Button
                  variant={selectedResolution === 'merge' ? 'default' : 'outline'}
                  className="w-full justify-start"
                  onClick={() => handleResolve('merge')}
                >
                  <div className="text-left">
                    <div className="font-medium">Merge Both</div>
                    <div className="text-xs opacity-70">Combine the changes</div>
                  </div>
                </Button>
              )}
            </div>
          </div>
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={onDismiss}>
            Cancel
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

// Hook for managing conflicts
export function useConflictResolution() {
  const [conflicts, setConflicts] = useState<DataConflict[]>([]);
  const [currentConflict, setCurrentConflict] = useState<DataConflict | null>(null);

  const addConflict = (conflict: DataConflict) => {
    setConflicts(prev => [...prev, conflict]);
    if (!currentConflict) {
      setCurrentConflict(conflict);
    }

    track('conflict_detected', {
      conflict_id: conflict.id,
      conflict_type: conflict.type,
      field: conflict.field
    });
  };

  const resolveConflict = (conflictId: string, resolution: 'local' | 'remote' | 'merge') => {
    // Remove the resolved conflict
    setConflicts(prev => prev.filter(c => c.id !== conflictId));

    // Show next conflict if any
    const nextConflict = conflicts.find(c => c.id !== conflictId);
    setCurrentConflict(nextConflict || null);
  };

  const dismissConflict = (conflictId: string) => {
    setConflicts(prev => prev.filter(c => c.id !== conflictId));
    const nextConflict = conflicts.find(c => c.id !== conflictId);
    setCurrentConflict(nextConflict || null);
  };

  return {
    conflicts,
    currentConflict,
    addConflict,
    resolveConflict,
    dismissConflict,
    hasConflicts: conflicts.length > 0
  };
}

