import { supabase } from '@/integrations/supabase/client';

export interface AIPreferences {
  aiDataSharingEnabled: boolean;
  lastUpdated: Date;
}

class AIPreferencesService {
  private static STORAGE_KEY = 'ai_preferences';
  
  /**
   * Get AI preferences from localStorage and Supabase (merged)
   */
  async getPreferences(userId: string): Promise<AIPreferences> {
    try {
      // Try localStorage first for quick access
      const cached = localStorage.getItem(AIPreferencesService.STORAGE_KEY);
      if (cached) {
        const parsed = JSON.parse(cached);
        return {
          aiDataSharingEnabled: parsed.aiDataSharingEnabled,
          lastUpdated: new Date(parsed.lastUpdated)
        };
      }
      
      // Fetch from Supabase
      const { data, error } = await supabase
        .from('profiles')
        .select('ai_data_sharing_enabled, ai_preferences_updated_at')
        .eq('id', userId)
        .single();
      
      if (error) throw error;
      
      const preferences: AIPreferences = {
        aiDataSharingEnabled: data.ai_data_sharing_enabled ?? true,
        lastUpdated: data.ai_preferences_updated_at ? new Date(data.ai_preferences_updated_at) : new Date()
      };
      
      // Cache in localStorage
      localStorage.setItem(AIPreferencesService.STORAGE_KEY, JSON.stringify(preferences));
      
      return preferences;
    } catch (error) {
      console.error('Error fetching AI preferences:', error);
      // Default to enabled for backward compatibility
      return {
        aiDataSharingEnabled: true,
        lastUpdated: new Date()
      };
    }
  }
  
  /**
   * Save AI preferences to both localStorage and Supabase
   */
  async setPreferences(userId: string, enabled: boolean): Promise<void> {
    const preferences: AIPreferences = {
      aiDataSharingEnabled: enabled,
      lastUpdated: new Date()
    };
    
    // Save to localStorage
    localStorage.setItem(AIPreferencesService.STORAGE_KEY, JSON.stringify(preferences));
    
    // Save to Supabase
    const { error } = await supabase
      .from('profiles')
      .update({
        ai_data_sharing_enabled: enabled,
        ai_preferences_updated_at: new Date().toISOString()
      })
      .eq('id', userId);
    
    if (error) {
      console.error('Error saving AI preferences:', error);
      throw error;
    }
  }
  
  /**
   * Check if user has consented to AI features
   */
  async canUseAI(userId: string): Promise<boolean> {
    const prefs = await this.getPreferences(userId);
    return prefs.aiDataSharingEnabled;
  }
  
  /**
   * Clear cached preferences (useful for testing or logout)
   */
  clearCache(): void {
    localStorage.removeItem(AIPreferencesService.STORAGE_KEY);
  }
}

export const aiPreferencesService = new AIPreferencesService();
