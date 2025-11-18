import localforage from 'localforage';

const referralStore = localforage.createInstance({
  name: 'nestling',
  storeName: 'referrals',
});

interface ReferralData {
  code: string;
  signupCount: number;
  createdAt: string;
}

class ReferralService {
  async getReferralCode(userId: string): Promise<string> {
    let referralData = await referralStore.getItem<ReferralData>(`referral_${userId}`);
    
    if (!referralData) {
      // Generate new code
      const code = this.generateCode();
      referralData = {
        code,
        signupCount: 0,
        createdAt: new Date().toISOString(),
      };
      await referralStore.setItem(`referral_${userId}`, referralData);
    }
    
    return referralData.code;
  }

  async getReferralStats(userId: string): Promise<{ code: string; signupCount: number }> {
    const referralData = await referralStore.getItem<ReferralData>(`referral_${userId}`);
    return {
      code: referralData?.code || '',
      signupCount: referralData?.signupCount || 0,
    };
  }

  async trackReferralSignup(referralCode: string): Promise<void> {
    // Find user by referral code
    const keys = await referralStore.keys();
    for (const key of keys) {
      const data = await referralStore.getItem<ReferralData>(key);
      if (data?.code === referralCode) {
        data.signupCount += 1;
        await referralStore.setItem(key, data);
        break;
      }
    }
  }

  async setReferralCodeUsed(code: string): Promise<void> {
    await referralStore.setItem('used_referral_code', code);
  }

  async getReferralCodeUsed(): Promise<string | null> {
    return await referralStore.getItem<string>('used_referral_code');
  }

  generateShareMessage(code: string, babyName?: string): string {
    const message = babyName 
      ? `I've been tracking ${babyName}'s sleep and feeds with Nestling - it's been so helpful! Join me: `
      : `I've been using Nestling to track my baby - check it out! `;
    
    const url = `${window.location.origin}/invite/${code}`;
    return `${message}${url}`;
  }

  private generateCode(): string {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    let code = '';
    for (let i = 0; i < 6; i++) {
      code += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return code;
  }

  getReferralLink(code: string): string {
    return `${window.location.origin}/invite/${code}`;
  }
}

export const referralService = new ReferralService();
