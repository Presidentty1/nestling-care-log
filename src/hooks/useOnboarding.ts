import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { familyService } from '@/services/familyService';
import { babyService } from '@/services/babyService';
import { useAuth } from './useAuth';
import { useAppStore } from '@/store/appStore';
import { format, subDays } from 'date-fns';
import { toast } from 'sonner';

export function useOnboarding() {
  const { user, loading: authLoading } = useAuth();
  const navigate = useNavigate();
  const { setActiveBabyId } = useAppStore();
  const [checking, setChecking] = useState(true);

  useEffect(() => {
    if (authLoading) return;
    
    if (!user) {
      navigate('/auth');
      return;
    }

    checkAndSetupUser();
  }, [user, authLoading]);

  const checkAndSetupUser = async () => {
    try {
      // Check if user has any families
      const families = await familyService.getUserFamilies();
      
      if (families.length === 0) {
        // First time user - auto-create family + demo baby
        const demoBirthdate = format(subDays(new Date(), 60), 'yyyy-MM-dd'); // 2 months old
        const { baby } = await familyService.createFamilyWithBaby(
          'My Family',
          'Demo Baby',
          demoBirthdate
        );
        
        setActiveBabyId(baby.id);
        localStorage.setItem('activeBabyId', baby.id);
        toast.success('Welcome to Nestling! Your demo profile is ready.');
        navigate('/home');
      } else {
        // Has families - check for babies
        const babies = await babyService.getUserBabies();
        
        if (babies.length === 0) {
          // Has family but no babies - go to onboarding
          setChecking(false);
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
