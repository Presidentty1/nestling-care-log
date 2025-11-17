/**
 * Enhanced offline queue for handling data sync when connection is restored
 * This will be fully utilized when Supabase sync is added in Cursor phase
 */

import localforage from 'localforage';

interface QueueItem {
  id: string;
  operation: 'create' | 'update' | 'delete';
  entity: 'event' | 'baby' | 'napFeedback' | 'settings';
  data: any;
  timestamp: string;
  retryCount: number;
}

const queueStore = localforage.createInstance({
  name: 'nestling',
  storeName: 'syncQueue',
});

class OfflineQueue {
  private processing = false;
  private maxRetries = 3;

  /**
   * Add item to sync queue
   */
  async enqueue(item: Omit<QueueItem, 'id' | 'timestamp' | 'retryCount'>): Promise<void> {
    const queueItem: QueueItem = {
      ...item,
      id: crypto.randomUUID(),
      timestamp: new Date().toISOString(),
      retryCount: 0,
    };

    await queueStore.setItem(queueItem.id, queueItem);
    console.log('[OfflineQueue] Enqueued:', queueItem);
  }

  /**
   * Get all queued items
   */
  async getQueue(): Promise<QueueItem[]> {
    const items: QueueItem[] = [];
    await queueStore.iterate<QueueItem, void>((item) => {
      items.push(item);
    });
    return items.sort((a, b) => a.timestamp.localeCompare(b.timestamp));
  }

  /**
   * Process queue (will be used when Supabase sync is added)
   */
  async process(): Promise<void> {
    if (this.processing) return;

    this.processing = true;
    console.log('[OfflineQueue] Processing queue...');

    try {
      const queue = await this.getQueue();

      for (const item of queue) {
        try {
          // TODO: Implement actual sync logic with Supabase
          // For now, we just log and remove from queue
          console.log('[OfflineQueue] Would sync:', item);
          await queueStore.removeItem(item.id);
        } catch (error) {
          console.error('[OfflineQueue] Failed to sync item:', error);
          
          // Increment retry count
          item.retryCount++;
          
          if (item.retryCount >= this.maxRetries) {
            console.error('[OfflineQueue] Max retries reached, removing item:', item.id);
            await queueStore.removeItem(item.id);
          } else {
            await queueStore.setItem(item.id, item);
          }
        }
      }
    } finally {
      this.processing = false;
    }
  }

  /**
   * Clear all queue items
   */
  async clear(): Promise<void> {
    await queueStore.clear();
    console.log('[OfflineQueue] Queue cleared');
  }

  /**
   * Get queue size
   */
  async size(): Promise<number> {
    return await queueStore.length();
  }
}

export const offlineQueue = new OfflineQueue();
