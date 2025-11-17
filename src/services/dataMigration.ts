/**
 * Data migration service for handling app updates and schema changes
 */

import localforage from 'localforage';
import { Baby, EventRecord } from '@/types/events';

const CURRENT_VERSION = 1;
const VERSION_KEY = 'app_data_version';

const versionStore = localforage.createInstance({
  name: 'nestling',
  storeName: 'meta',
});

class DataMigration {
  /**
   * Check and run migrations if needed
   */
  async runMigrations(): Promise<void> {
    const currentVersion = await this.getCurrentVersion();
    
    if (currentVersion < CURRENT_VERSION) {
      console.log(`[Migration] Running migrations from v${currentVersion} to v${CURRENT_VERSION}`);
      
      // Run migrations sequentially
      for (let version = currentVersion + 1; version <= CURRENT_VERSION; version++) {
        await this.runMigration(version);
      }
      
      await this.setVersion(CURRENT_VERSION);
      console.log('[Migration] Migrations complete');
    }
  }

  /**
   * Get current data version
   */
  private async getCurrentVersion(): Promise<number> {
    const version = await versionStore.getItem<number>(VERSION_KEY);
    return version ?? 0;
  }

  /**
   * Set data version
   */
  private async setVersion(version: number): Promise<void> {
    await versionStore.setItem(VERSION_KEY, version);
  }

  /**
   * Run specific migration
   */
  private async runMigration(version: number): Promise<void> {
    console.log(`[Migration] Running migration v${version}`);
    
    switch (version) {
      case 1:
        await this.migrateToV1();
        break;
      // Add future migrations here
      default:
        console.warn(`[Migration] No migration defined for v${version}`);
    }
  }

  /**
   * Migration to v1: Initialize data structure
   */
  private async migrateToV1(): Promise<void> {
    // This is the initial version, no migration needed
    console.log('[Migration] v1: Initial version');
  }

  /**
   * Backup all data
   */
  async backup(): Promise<string> {
    const eventsStore = localforage.createInstance({ name: 'nestling', storeName: 'events' });
    const babiesStore = localforage.createInstance({ name: 'nestling', storeName: 'babies' });
    const settingsStore = localforage.createInstance({ name: 'nestling', storeName: 'settings' });
    
    const backup = {
      version: await this.getCurrentVersion(),
      timestamp: new Date().toISOString(),
      data: {
        events: [] as EventRecord[],
        babies: [] as Baby[],
        settings: {},
      },
    };

    // Collect all data
    await eventsStore.iterate<EventRecord, void>((value) => {
      backup.data.events.push(value);
    });

    await babiesStore.iterate<Baby, void>((value) => {
      backup.data.babies.push(value);
    });

    await settingsStore.iterate((value, key) => {
      backup.data.settings[key] = value;
    });

    return JSON.stringify(backup, null, 2);
  }

  /**
   * Restore from backup
   */
  async restore(backupJson: string): Promise<void> {
    try {
      const backup = JSON.parse(backupJson);
      
      const eventsStore = localforage.createInstance({ name: 'nestling', storeName: 'events' });
      const babiesStore = localforage.createInstance({ name: 'nestling', storeName: 'babies' });
      const settingsStore = localforage.createInstance({ name: 'nestling', storeName: 'settings' });

      // Clear existing data
      await eventsStore.clear();
      await babiesStore.clear();
      await settingsStore.clear();

      // Restore data
      for (const event of backup.data.events) {
        await eventsStore.setItem(event.id, event);
      }

      for (const baby of backup.data.babies) {
        await babiesStore.setItem(baby.id, baby);
      }

      for (const [key, value] of Object.entries(backup.data.settings)) {
        await settingsStore.setItem(key, value);
      }

      console.log('[Migration] Backup restored successfully');
    } catch (error) {
      console.error('[Migration] Failed to restore backup:', error);
      throw new Error('Failed to restore backup. The file may be corrupted.');
    }
  }
}

export const dataMigration = new DataMigration();
