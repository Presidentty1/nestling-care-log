import { supabase } from '@/integrations/supabase/client';
import { toast } from 'sonner';

interface QueuedOperation {
  id: string;
  type: 'create' | 'update' | 'delete';
  table: string;
  data: any;
  timestamp: number;
  retryCount: number;
}

class OfflineQueue {
  private queue: QueuedOperation[] = [];
  private storageKey = 'nestling-offline-queue';
  private maxRetries = 3;

  constructor() {
    this.loadQueue();
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

  enqueue(operation: Omit<QueuedOperation, 'id' | 'timestamp' | 'retryCount'>) {
    const queuedOp: QueuedOperation = {
      ...operation,
      id: crypto.randomUUID(),
      timestamp: Date.now(),
      retryCount: 0,
    };
    
    this.queue.push(queuedOp);
    this.saveQueue();
  }

  async processQueue(): Promise<{ success: number; failed: number }> {
    let success = 0;
    let failed = 0;

    const operations = [...this.queue];
    
    for (const op of operations) {
      try {
        await this.processOperation(op);
        this.removeFromQueue(op.id);
        success++;
      } catch (error) {
        console.error('Failed to process operation:', error);
        op.retryCount++;
        
        if (op.retryCount >= this.maxRetries) {
          this.removeFromQueue(op.id);
          failed++;
        }
      }
    }

    this.saveQueue();
    return { success, failed };
  }

  private async processOperation(op: QueuedOperation) {
    const { table, type, data } = op;

    switch (type) {
      case 'create':
        await supabase.from(table).insert(data);
        break;
      case 'update':
        await supabase.from(table).update(data).eq('id', data.id);
        break;
      case 'delete':
        await supabase.from(table).delete().eq('id', data.id);
        break;
    }
  }

  private removeFromQueue(id: string) {
    this.queue = this.queue.filter(op => op.id !== id);
  }

  getStatus() {
    return {
      pending: this.queue.length,
      failed: this.queue.filter(op => op.retryCount >= this.maxRetries).length,
    };
  }

  clearCompleted() {
    this.queue = this.queue.filter(op => op.retryCount < this.maxRetries);
    this.saveQueue();
  }
}

export const offlineQueue = new OfflineQueue();
