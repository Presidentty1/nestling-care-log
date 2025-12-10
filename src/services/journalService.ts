import { supabase } from '@/integrations/supabase/client';
import { authService } from './authService';

export interface JournalEntry {
  id: string;
  baby_id: string;
  title?: string | null;
  content: string;
  mood?: string | null;
  entry_date: string;
  weather?: string | null;
  activities?: string[] | null;
  firsts?: string[] | null;
  funny_moments?: string[] | null;
  created_by?: string | null;
  created_at: string;
  updated_at: string;
}

class JournalService {
  async getJournalEntries(babyId: string, limit = 50): Promise<JournalEntry[]> {
    const { data, error } = await supabase
      .from('journal_entries')
      .select('*')
      .eq('baby_id', babyId)
      .order('entry_date', { ascending: false })
      .limit(limit);

    if (error) throw error;
    return data || [];
  }

  async getJournalEntry(id: string): Promise<JournalEntry | null> {
    const { data, error } = await supabase
      .from('journal_entries')
      .select('*')
      .eq('id', id)
      .single();

    if (error) {
      if (error.code === 'PGRST116') return null; // Not found
      throw error;
    }
    return data;
  }

  async createJournalEntry(
    entry: Omit<JournalEntry, 'id' | 'created_at' | 'updated_at'>
  ): Promise<JournalEntry> {
    const {
      data: { user },
    } = await authService.getUser();
    if (!user) throw new Error('Not authenticated');

    const entryData = {
      ...entry,
      created_by: user.id,
    };

    const { data, error } = await supabase
      .from('journal_entries')
      .insert(entryData)
      .select('*')
      .single();

    if (error) throw error;
    return data;
  }

  async updateJournalEntry(id: string, updates: Partial<JournalEntry>): Promise<JournalEntry> {
    const { data, error } = await supabase
      .from('journal_entries')
      .update(updates)
      .eq('id', id)
      .select('*')
      .single();

    if (error) throw error;
    return data;
  }

  async deleteJournalEntry(id: string): Promise<void> {
    const { error } = await supabase.from('journal_entries').delete().eq('id', id);

    if (error) throw error;
  }
}

export const journalService = new JournalService();
