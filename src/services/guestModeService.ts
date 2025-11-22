import localforage from 'localforage';
import type { Baby } from '@/types/events';
import { EventRecord } from '@/types/events';

const guestStore = localforage.createInstance({
  name: 'nestling-guest',
  storeName: 'guest-data',
});

class GuestModeService {
  async isGuestMode(): Promise<boolean> {
    const mode = await guestStore.getItem<boolean>('is_guest');
    return mode === true;
  }

  async enableGuestMode(): Promise<void> {
    await guestStore.setItem('is_guest', true);
  }

  async getGuestEventCount(): Promise<number> {
    const count = await guestStore.getItem<number>('event_count');
    return count || 0;
  }

  async incrementGuestEventCount(): Promise<number> {
    const count = await this.getGuestEventCount();
    const newCount = count + 1;
    await guestStore.setItem('event_count', newCount);
    return newCount;
  }

  async shouldShowSignupBanner(): Promise<boolean> {
    const count = await this.getGuestEventCount();
    return count >= 3;
  }

  async clearGuestData(): Promise<void> {
    await guestStore.clear();
  }

  async getGuestBaby(): Promise<Baby | null> {
    return await guestStore.getItem<Baby>('guest_baby');
  }

  async setGuestBaby(baby: Baby): Promise<void> {
    await guestStore.setItem('guest_baby', baby);
  }
}

export const guestModeService = new GuestModeService();
