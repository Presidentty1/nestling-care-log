/**
 * Undo Manager for web app
 * Provides a lightweight undo queue with 7-second expiration window
 * Matches iOS UndoManager pattern
 */

export interface UndoableDeletion<T = any> {
  item: T;
  deletedAt: Date;
  restoreAction: () => Promise<void> | void;

  isExpired(): boolean;
}

class UndoManager {
  private static instance: UndoManager;
  private pendingDeletion: UndoableDeletion | null = null;
  private expirationTimer: ReturnType<typeof setTimeout> | null = null;
  private readonly UNDO_WINDOW_MS = 7000; // 7 seconds

  private constructor() {}

  static getInstance(): UndoManager {
    if (!UndoManager.instance) {
      UndoManager.instance = new UndoManager();
    }
    return UndoManager.instance;
  }

  /**
   * Register a deletion for potential undo
   * @param item - The item that was deleted
   * @param restoreAction - Function to restore the item
   */
  registerDeletion<T>(item: T, restoreAction: () => Promise<void> | void): UndoableDeletion<T> {
    // Clear any existing pending deletion
    this.clear();

    const deletion: UndoableDeletion<T> = {
      item,
      deletedAt: new Date(),
      restoreAction,
      isExpired: () => {
        const elapsed = Date.now() - deletion.deletedAt.getTime();
        return elapsed > this.UNDO_WINDOW_MS;
      },
    };

    this.pendingDeletion = deletion;

    // Auto-expire after 7 seconds
    this.expirationTimer = setTimeout(() => {
      if (this.pendingDeletion === deletion) {
        this.clear();
      }
    }, this.UNDO_WINDOW_MS);

    return deletion;
  }

  /**
   * Perform undo operation
   * @throws Error if undo window has expired
   */
  async undo(): Promise<void> {
    if (!this.pendingDeletion) {
      throw new Error('No pending deletion to undo');
    }

    if (this.pendingDeletion.isExpired()) {
      this.clear();
      throw new Error('Undo window has expired');
    }

    try {
      await this.pendingDeletion.restoreAction();
      this.clear();
    } catch (error) {
      this.clear();
      throw error;
    }
  }

  /**
   * Clear pending deletion (called when user dismisses or time expires)
   */
  clear(): void {
    if (this.expirationTimer) {
      clearTimeout(this.expirationTimer);
      this.expirationTimer = null;
    }
    this.pendingDeletion = null;
  }

  /**
   * Check if there's an undoable deletion
   */
  hasUndoableDeletion(): boolean {
    if (!this.pendingDeletion) {
      return false;
    }
    return !this.pendingDeletion.isExpired();
  }

  /**
   * Get the pending deletion (for UI display)
   */
  getPendingDeletion(): UndoableDeletion | null {
    if (!this.pendingDeletion || this.pendingDeletion.isExpired()) {
      return null;
    }
    return this.pendingDeletion;
  }

  /**
   * Get remaining time in milliseconds
   */
  getRemainingTime(): number {
    if (!this.pendingDeletion || this.pendingDeletion.isExpired()) {
      return 0;
    }
    const elapsed = Date.now() - this.pendingDeletion.deletedAt.getTime();
    return Math.max(0, this.UNDO_WINDOW_MS - elapsed);
  }
}

export const undoManager = UndoManager.getInstance();
