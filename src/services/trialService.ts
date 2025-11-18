import localforage from 'localforage';
import { differenceInMonths, differenceInDays, addDays } from 'date-fns';

const trialStore = localforage.createInstance({
  name: 'nestling',
  storeName: 'trial',
});

interface TrialData {
  startDate: string;
  endDate: string;
  isActive: boolean;
}

class TrialService {
  async canStartTrial(babyBirthdate: string): Promise<boolean> {
    const ageInMonths = differenceInMonths(new Date(), new Date(babyBirthdate));
    const trial = await this.getTrialData();
    return ageInMonths >= 2 && !trial;
  }

  async startTrial(): Promise<TrialData> {
    const startDate = new Date();
    const endDate = addDays(startDate, 14);
    
    const trialData: TrialData = {
      startDate: startDate.toISOString(),
      endDate: endDate.toISOString(),
      isActive: true,
    };

    await trialStore.setItem('trial', trialData);
    return trialData;
  }

  async getTrialData(): Promise<TrialData | null> {
    return await trialStore.getItem<TrialData>('trial');
  }

  async getTrialDaysRemaining(): Promise<number | null> {
    const trial = await this.getTrialData();
    if (!trial || !trial.isActive) return null;

    const daysRemaining = differenceInDays(new Date(trial.endDate), new Date());
    return Math.max(0, daysRemaining);
  }

  async isTrialActive(): Promise<boolean> {
    const trial = await this.getTrialData();
    if (!trial || !trial.isActive) return false;

    const daysRemaining = differenceInDays(new Date(trial.endDate), new Date());
    return daysRemaining > 0;
  }

  async shouldShowTrialStartModal(babyBirthdate: string): Promise<boolean> {
    const canStart = await this.canStartTrial(babyBirthdate);
    const hasSeenModal = await trialStore.getItem<boolean>('trial_modal_shown');
    return canStart && !hasSeenModal;
  }

  async markTrialModalShown(): Promise<void> {
    await trialStore.setItem('trial_modal_shown', true);
  }

  async endTrial(): Promise<void> {
    const trial = await this.getTrialData();
    if (trial) {
      trial.isActive = false;
      await trialStore.setItem('trial', trial);
    }
  }
}

export const trialService = new TrialService();
