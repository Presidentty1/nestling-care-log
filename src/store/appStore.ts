import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface AppState {
  activeBabyId: string | null;
  caregiverMode: boolean;
  guestMode: boolean;
  setActiveBabyId: (id: string | null) => void;
  setCaregiverMode: (enabled: boolean) => void;
  setGuestMode: (enabled: boolean) => void;
}

export const useAppStore = create<AppState>()(
  persist(
    (set) => ({
      activeBabyId: null,
      caregiverMode: false,
      guestMode: false,
      setActiveBabyId: (id) => set({ activeBabyId: id }),
      setCaregiverMode: (enabled) => {
        set({ caregiverMode: enabled });
        // Apply to body element
        if (typeof document !== 'undefined') {
          if (enabled) {
            document.body.classList.add('caregiver-mode');
          } else {
            document.body.classList.remove('caregiver-mode');
          }
        }
      },
      setGuestMode: (enabled) => set({ guestMode: enabled }),
    }),
    {
      name: 'nestling-app-store',
    }
  )
);
