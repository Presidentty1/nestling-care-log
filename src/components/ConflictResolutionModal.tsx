import React from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { AlertTriangle, RefreshCw, SkipForward, Merge } from 'lucide-react';
import { useOfflineQueue } from '@/hooks/useOfflineQueue';

interface ConflictResolutionModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export function ConflictResolutionModal({ isOpen, onClose }: ConflictResolutionModalProps) {
  const { getConflicts, resolveConflict } = useOfflineQueue();
  const conflicts = getConflicts();

  const handleResolution = async (conflictIndex: number, strategy: 'overwrite' | 'merge' | 'skip') => {
    const conflict = conflicts[conflictIndex];
    if (!conflict) return;

    const success = resolveConflict({
      operationId: conflict.operation.id,
      strategy,
    });

    if (success) {
      // Remove this conflict from local state or refresh
      if (getConflicts().length === 0) {
        onClose();
      }
    }
  };

  const formatConflictData = (data: any) => {
    if (!data) return 'No data';

    if (typeof data === 'object') {
      const relevantFields = ['note', 'amount', 'start_time', 'end_time'];
      const relevantData = Object.fromEntries(
        Object.entries(data).filter(([key]) => relevantFields.includes(key))
      );

      if (Object.keys(relevantData).length === 0) return 'No relevant changes';

      return Object.entries(relevantData)
        .map(([key, value]) => `${key}: ${value}`)
        .join(', ');
    }

    return String(data);
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-2xl max-h-[80vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <AlertTriangle className="h-5 w-5 text-warning" />
            Data Conflicts Detected
          </DialogTitle>
        </DialogHeader>

        <div className="space-y-4">
          <p className="text-sm text-muted-foreground">
            Some data was modified on another device while you were offline.
            Please choose how to resolve each conflict.
          </p>

          {conflicts.length === 0 ? (
            <p className="text-center text-muted-foreground py-8">
              No conflicts remaining. All resolved!
            </p>
          ) : (
            <div className="space-y-4">
              {conflicts.map((conflict, index) => (
                <div key={conflict.operation.id} className="border rounded-lg p-4 space-y-3">
                  <div className="flex items-start justify-between">
                    <div>
                      <Badge variant="outline" className="mb-2">
                        {conflict.operation.type.toUpperCase()} - {conflict.operation.table}
                      </Badge>
                      <p className="text-sm font-medium">
                        Conflict Reason: {conflict.conflictReason.replace('_', ' ')}
                      </p>
                    </div>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
                    <div className="space-y-2">
                      <h4 className="font-medium text-destructive">Your Changes:</h4>
                      <div className="bg-destructive/5 p-2 rounded text-xs">
                        {formatConflictData(conflict.operation.data)}
                      </div>
                    </div>

                    <div className="space-y-2">
                      <h4 className="font-medium text-primary">Server Data:</h4>
                      <div className="bg-primary/5 p-2 rounded text-xs">
                        {formatConflictData(conflict.serverData)}
                      </div>
                    </div>
                  </div>

                  <div className="flex flex-wrap gap-2 pt-2 border-t">
                    <Button
                      size="sm"
                      variant="default"
                      onClick={() => handleResolution(index, 'overwrite')}
                      className="flex items-center gap-1"
                    >
                      <RefreshCw className="h-3 w-3" />
                      Use My Changes
                    </Button>

                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => handleResolution(index, 'merge')}
                      className="flex items-center gap-1"
                    >
                      <Merge className="h-3 w-3" />
                      Merge Changes
                    </Button>

                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => handleResolution(index, 'skip')}
                      className="flex items-center gap-1"
                    >
                      <SkipForward className="h-3 w-3" />
                      Skip This
                    </Button>
                  </div>
                </div>
              ))}
            </div>
          )}

          <div className="flex justify-end pt-4 border-t">
            <Button onClick={onClose}>
              {conflicts.length === 0 ? 'Close' : 'Resolve Later'}
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}