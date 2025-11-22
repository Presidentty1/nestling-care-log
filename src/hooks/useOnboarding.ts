import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { familyService } from '@/services/familyService';
import { babyService } from '@/services/babyService';
import { useAuth } from './useAuth';
import { useAppStore } from '@/store/appStore';
import { format, subDays } from 'date-fns';
import { toast } from 'sonner';
import { supabase } from '@/integrations/supabase/client';
import { guestModeService } from '@/services/guestModeService';
import { dataService } from '@/services/dataService';

export function useOnboarding() {
  const { user, loading: authLoading } = useAuth();
  const navigate = useNavigate();
  const { setActiveBabyId, setGuestMode } = useAppStore();
  const [checking, setChecking] = useState(true);

  useEffect(() => {
    if (authLoading) return;
    
    // Check if guest mode
    checkGuestMode();
    
    if (!user) {
      // Allow guest mode - go to home
      navigate('/home');
      return;
    }

    checkAndSetupUser();
  }, [user, authLoading]);

  const checkGuestMode = async () => {
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
  };

  const checkAndSetupUser = async () => {
    try {
      // Check if user has any families
      const families = await familyService.getUserFamilies();
      
      if (families.length === 0) {
        // First time user - call backend to bootstrap
        const demoBirthdate = format(subDays(new Date(), 60), 'yyyy-MM-dd');
        const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
        
        const { data: { session } } = await supabase.auth.getSession();
        if (!session) {
          toast.error('Authentication session not found');
          setChecking(false);
          return;
        }

        const response = await supabase.functions.invoke('bootstrap-user', {
          body: {
            babyName: 'Demo Baby',
            dateOfBirth: demoBirthdate,
            timezone
          },
          headers: {
            Authorization: `Bearer ${session.access_token}`
          }
        });

        if (response.error) {
          console.error('Bootstrap error:', response.error);
          toast.error('Could not complete setup. Please finish onboarding below.');
          setChecking(false);
          return;
        }

        const { babyId } = response.data;
        setActiveBabyId(babyId);
        localStorage.setItem('activeBabyId', babyId);
        toast.success('Welcome to Nestling! Your demo profile is ready.');
        navigate('/home');
      } else {
        // Has families - check for babies
        const babies = await babyService.getUserBabies();
        
        if (babies.length === 0) {
          // Has family but no babies - auto-provision a demo baby via backend
          const { data: { session } } = await supabase.auth.getSession();
          if (!session) {
            toast.error('Authentication session not found');
            setChecking(false);
            return;
          }

          const demoBirthdate = format(subDays(new Date(), 60), 'yyyy-MM-dd');
          const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;

          const response = await supabase.functions.invoke('bootstrap-user', {
            body: {
              babyName: 'Demo Baby',
              dateOfBirth: demoBirthdate,
              timezone
            },
            headers: {
              Authorization: `Bearer ${session.access_token}`
            }
          });

          if (response.error) {
            console.error('Bootstrap (no-baby) error:', response.error);
            // Fall back to manual onboarding UI
            setChecking(false);
            return;
          }

          const { babyId } = response.data;
          setActiveBabyId(babyId);
          localStorage.setItem('activeBabyId', babyId);
          toast.success('Your profile is ready!');
          navigate('/home');
        } else {
          // All set - go to home
          const storedBabyId = localStorage.getItem('activeBabyId');
          const activeBaby = babies.find(b => b.id === storedBabyId) || babies[0];
          setActiveBabyId(activeBaby.id);
          navigate('/home');
        }
      }
    } catch (error) {
      console.error('Onboarding check error:', error);
      toast.error('Failed to set up your profile. Please try again.');
      setChecking(false);
    }
  };

  return { checking };
}
