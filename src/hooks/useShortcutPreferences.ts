import { useState, useEffect } from 'react';

interface ShortcutPreferences {
  voiceEnabled: boolean;
  quickActionsEnabled: boolean;
  floatingButtonEnabled: boolean;
}

export function useShortcutPreferences() {
  const [preferences, setPreferences] = useState<ShortcutPreferences>(() => {
    const voiceStored = localStorage.getItem('voice_enabled');
    const quickActionsStored = localStorage.getItem('quick_actions_enabled');
    const floatingButtonStored = localStorage.getItem('floating_button_enabled');

    return {
      voiceEnabled: voiceStored !== null ? JSON.parse(voiceStored) : true,
      quickActionsEnabled: quickActionsStored !== null ? JSON.parse(quickActionsStored) : true,
      floatingButtonEnabled:
        floatingButtonStored !== null ? JSON.parse(floatingButtonStored) : true,
    };
  });

  // Listen for changes in localStorage (from other tabs/windows)
  useEffect(() => {
    const handleStorageChange = (e: StorageEvent) => {
      if (e.key === 'voice_enabled') {
        setPreferences(prev => ({ ...prev, voiceEnabled: JSON.parse(e.newValue || 'true') }));
      }
      if (e.key === 'quick_actions_enabled') {
        setPreferences(prev => ({
          ...prev,
          quickActionsEnabled: JSON.parse(e.newValue || 'true'),
        }));
      }
      if (e.key === 'floating_button_enabled') {
        setPreferences(prev => ({
          ...prev,
          floatingButtonEnabled: JSON.parse(e.newValue || 'true'),
        }));
      }
    };

    window.addEventListener('storage', handleStorageChange);
    return () => window.removeEventListener('storage', handleStorageChange);
  }, []);

  return preferences;
}
