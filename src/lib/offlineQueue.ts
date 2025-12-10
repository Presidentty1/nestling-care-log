import { supabase } from '@/integrations/supabase/client';
import { toast } from 'sonner';
import { logger } from './logger';

interface QueuedOperation {
  id: string;
  type: 'create' | 'update' | 'delete';
  table: string;
  data: any;
  timestamp: number;
  retryCount: number;
  originalData?: any; // For conflict resolution
  conflictStrategy?: 'overwrite' | 'merge' | 'manual' | 'skip';
}

interface ConflictResolution {
  operationId: string;
  strategy: 'overwrite' | 'merge' | 'manual' | 'skip';
  resolvedData?: any;
}

interface ConflictInfo {
  operation: QueuedOperation;
  serverData: any;
  conflictReason: 'version_mismatch' | 'concurrent_edit' | 'deleted_remotely';
  suggestedResolution: 'overwrite' | 'merge' | 'manual';
}

class OfflineQueue {
  private queue: QueuedOperation[] = [];
  private storageKey = 'nestling-offline-queue';
  private conflictStorageKey = 'nestling-offline-conflicts';
  private maxRetries = 3;
  private conflicts: ConflictInfo[] = [];

  constructor() {
    this.loadQueue();
    this.loadConflicts();
  }

  private loadQueue() {
    const stored = localStorage.getItem(this.storageKey);
    if (stored) {
      try {
        this.queue = JSON.parse(stored);
      } catch (e) {
        console.error('Failed to load offline queue:', e);
        this.queue = [];
      }
    }
  }

  private saveQueue() {
    localStorage.setItem(this.storageKey, JSON.stringify(this.queue));
  }

  private loadConflicts() {
    const stored = localStorage.getItem(this.conflictStorageKey);
    if (stored) {
      try {
        this.conflicts = JSON.parse(stored);
      } catch (e) {
        logger.error('Failed to load conflicts', e, 'OfflineQueue');
        this.conflicts = [];
      }
    }
  }

  private saveConflicts() {
    localStorage.setItem(this.conflictStorageKey, JSON.stringify(this.conflicts));
  }

  enqueue(operation: Omit<QueuedOperation, 'id' | 'timestamp' | 'retryCount'>) {
    const queuedOp: QueuedOperation = {
      ...operation,
      id: crypto.randomUUID(),
      timestamp: Date.now(),
      retryCount: 0,
    };

    // For update operations, capture original data for conflict resolution
    if (operation.type === 'update' && operation.table === 'events') {
      queuedOp.originalData = operation.data;
    }

    this.queue.push(queuedOp);
    this.saveQueue();
  }

  async processQueue(): Promise<{ success: number; failed: number }> {
    let success = 0;
    let failed = 0;

    // Process operations in batches to avoid blocking the main thread
    const batchSize = 5;
    const operations = [...this.queue];

    for (let i = 0; i < operations.length; i += batchSize) {
      const batch = operations.slice(i, i + batchSize);

      const results = await Promise.allSettled(
        batch.map(op => this.processOperation(op))
      );

      results.forEach((result, index) => {
        const op = batch[index];

        if (result.status === 'fulfilled') {
          this.removeFromQueue(op.id);
          success++;
        } else {
          logger.error('Failed to process operation', result.reason, 'OfflineQueue');
          op.retryCount++;

          if (op.retryCount >= this.maxRetries) {
            this.removeFromQueue(op.id);
            failed++;
          }
          // If operation can still be retried, keep it in queue but don't count as failed yet
        }
      });

      // Yield control to prevent blocking the main thread
      await new Promise(resolve => setTimeout(resolve, 0));
    }

    this.saveQueue();
    return { success, failed };
  }

  private async processOperation(op: QueuedOperation) {
    const { table, type, data, conflictStrategy = 'overwrite' } = op;

    try {
      switch (type) {
        case 'create':
          await this.handleCreateOperation(table, data, op);
          break;
        case 'update':
          await this.handleUpdateOperation(table, data, op, conflictStrategy);
          break;
        case 'delete':
          await this.handleDeleteOperation(table, data, op);
          break;
      }
    } catch (error: any) {
      // Check if it's a conflict error
      if (this.isConflictError(error)) {
        await this.handleConflict(op, error);
        throw error; // Re-throw to trigger retry logic
      }
      throw error;
    }
  }

  private async handleCreateOperation(table: string, data: any, op: QueuedOperation) {
    // For create operations, check if item already exists (might have been created elsewhere)
    if (table === 'events' && data.id) {
      const { data: existing } = await supabase
        .from(table)
        .select('id')
        .eq('id', data.id)
        .single();

      if (existing) {
        logger.warn('Create operation failed - item already exists, skipping', { id: data.id }, 'OfflineQueue');
        return; // Skip, item already exists
      }
    }

    await supabase.from(table).insert(data);
  }

  private async handleUpdateOperation(table: string, data: any, op: QueuedOperation, strategy: string) {
    const { data: existing, error: fetchError } = await supabase
      .from(table)
      .select('*')
      .eq('id', data.id)
      .single();

    if (fetchError?.code === 'PGRST116') { // Not found
      throw new Error('Item not found for update operation');
    }

    if (existing && this.hasConflict(existing, data, op)) {
      const conflictInfo: ConflictInfo = {
        operation: op,
        serverData: existing,
        conflictReason: 'concurrent_edit',
        suggestedResolution: 'manual'
      };

      this.conflicts.push(conflictInfo);
      this.saveConflicts();

      // Notify user about conflict
      toast.error('Data conflict detected. Please resolve manually.', {
        duration: 5000,
        action: {
          label: 'Resolve',
          onClick: () => this.showConflictResolution(conflictInfo)
        }
      });

      throw new Error('Conflict detected - requires manual resolution');
    }

    // Apply conflict resolution strategy
    let finalData = data;
    if (strategy === 'merge' && existing) {
      finalData = this.mergeData(existing, data);
    }

    await supabase.from(table).update(finalData).eq('id', data.id);
  }

  private async handleDeleteOperation(table: string, data: any, op: QueuedOperation) {
    const { error } = await supabase.from(table).delete().eq('id', data.id);

    if (error?.code === 'PGRST116') { // Not found
      logger.warn('Delete operation failed - item not found, skipping', { id: data.id }, 'OfflineQueue');
      return; // Item already deleted, consider it successful
    }

    if (error) throw error;
  }

  private isConflictError(error: any): boolean {
    return error?.message?.includes('conflict') ||
           error?.code === '23505' || // Unique constraint violation
           error?.code === 'PGRST116'; // Not found (for updates)
  }

  private hasConflict(serverData: any, localData: any, op: QueuedOperation): boolean {
    // Check if server data was modified after our operation was queued
    if (serverData.updated_at && op.timestamp) {
      const serverUpdated = new Date(serverData.updated_at).getTime();
      return serverUpdated > op.timestamp;
    }

    // Check for field-level conflicts
    const conflictingFields = ['note', 'amount', 'start_time', 'end_time'];
    return conflictingFields.some(field => {
      const serverValue = serverData[field];
      const localValue = localData[field];
      const originalValue = op.originalData?.[field];

      // If field was changed locally and differs from server (and we have original data)
      return originalValue !== undefined &&
             localValue !== originalValue &&
             serverValue !== localValue;
    });
  }

  private mergeData(serverData: any, localData: any): any {
    // Simple merge strategy: prefer local changes but keep server data for unchanged fields
    const merged = { ...serverData };

    Object.keys(localData).forEach(key => {
      if (localData[key] !== null && localData[key] !== undefined) {
        merged[key] = localData[key];
      }
    });

    return merged;
  }

  private async handleConflict(op: QueuedOperation, error: any) {
    logger.warn('Conflict detected for operation', {
      operationId: op.id,
      type: op.type,
      table: op.table,
      error: error.message
    }, 'OfflineQueue');
  }

  private showConflictResolution(conflict: ConflictInfo) {
    // This would show a modal or navigate to a conflict resolution screen
    // For now, we'll just log it
    logger.info('Conflict resolution requested', { operationId: conflict.operation.id }, 'OfflineQueue');
  }

  private removeFromQueue(id: string) {
    this.queue = this.queue.filter(op => op.id !== id);
  }

  getStatus() {
    return {
      pending: this.queue.length,
      failed: this.queue.filter(op => op.retryCount >= this.maxRetries).length,
      conflicts: this.conflicts.length,
    };
  }

  getConflicts(): ConflictInfo[] {
    return [...this.conflicts];
  }

  resolveConflict(conflictResolution: ConflictResolution) {
    const conflictIndex = this.conflicts.findIndex(c => c.operation.id === conflictResolution.operationId);
    if (conflictIndex === -1) return false;

    const conflict = this.conflicts[conflictIndex];

    switch (conflictResolution.strategy) {
      case 'overwrite':
        // Re-queue the operation with overwrite strategy
        this.enqueue({
          ...conflict.operation,
          conflictStrategy: 'overwrite'
        });
        break;

      case 'merge': {
        // Merge the data and re-queue
        const mergedData = conflictResolution.resolvedData || this.mergeData(conflict.serverData, conflict.operation.data);
        this.enqueue({
          ...conflict.operation,
          data: mergedData,
          conflictStrategy: 'merge'
        });
        break;
      }

      case 'skip':
        // Just remove the conflict without re-queuing
        logger.info('Conflict resolution: skipping operation', { operationId: conflict.operation.id }, 'OfflineQueue');
        break;

      case 'manual':
        // Keep the conflict for manual resolution
        return false;
    }

    // Remove the conflict
    this.conflicts.splice(conflictIndex, 1);
    this.saveConflicts();
    return true;
  }

  clearResolvedConflicts() {
    // Remove conflicts that have been resolved
    this.saveConflicts();
  }

  clearCompleted() {
    this.queue = this.queue.filter(op => op.retryCount < this.maxRetries);
    this.saveQueue();
  }
}

export const offlineQueue = new OfflineQueue();
