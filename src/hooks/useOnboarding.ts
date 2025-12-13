import { useCallback, useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { familyService } from '@/services/familyService';
import { babyService } from '@/services/babyService';
import { useAuth } from '@/hooks/useAuth';
import { useAppStore } from '@/store/appStore';
import { format, subDays } from 'date-fns';
import { toast } from 'sonner';
import { guestModeService } from '@/services/guestModeService';
import { dataService } from '@/services/dataService';

export function useOnboarding() {
  const { user, loading: authLoading } = useAuth();
  const navigate = useNavigate();
  const { setActiveBabyId, setGuestMode } = useAppStore();
  const [checking, setChecking] = useState(true);

  const checkGuestMode = useCallback(async () => {
    const isGuest = await guestModeService.isGuestMode();
    if (isGuest) {
      setGuestMode(true);
      const guestBaby = await guestModeService.getGuestBaby();
      if (!guestBaby) {
        // Create guest baby
        const baby = await dataService.addBaby({
          name: 'Demo Baby',
          dobISO: format(subDays(new Date(), 60), 'yyyy-MM-dd'),
          timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone,
          units: 'imperial',
        });
        await guestModeService.setGuestBaby(baby);
        setActiveBabyId(baby.id);
      } else {
        setActiveBabyId(guestBaby.id);
      }
      setChecking(false);
    }
  }, [setActiveBabyId, setGuestMode]);

  const checkAndSetupUser = useCallback(async () => {
    try {
      // Check if user has any families
      const families = await familyService.getUserFamilies();

      if (families.length === 0) {
        // NEW: Navigate to manual onboarding instead of auto-bootstrapping
        navigate('/onboarding');
        setChecking(false);
        return;
      }

      // Has families - check for babies
      const babies = await babyService.getUserBabies();

      if (babies.length === 0) {
        // NEW: Navigate to onboarding here too
        navigate('/onboarding');
        setChecking(false);
        return;
      }

      // User has everything - proceed to home
      const storedBabyId = localStorage.getItem('activeBabyId');
      const activeBaby = babies.find(b => b.id === storedBabyId) || babies[0];
      setActiveBabyId(activeBaby.id);
      navigate('/home');
    } catch (error) {
      console.error('Setup error:', error);
      toast.error('Failed to set up your profile. Please try again.');
      setChecking(false);
    }
  }, [navigate, setActiveBabyId]);

  useEffect(() => {
    if (authLoading) return;

    void checkGuestMode();

    if (!user) {
      // Allow guest mode - go to home
      navigate('/home');
      return;
    }

    void checkAndSetupUser();
  }, [authLoading, checkAndSetupUser, checkGuestMode, navigate, user]);

  return { checking };
}
