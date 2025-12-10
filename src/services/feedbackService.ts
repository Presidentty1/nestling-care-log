import { supabase } from '@/integrations/supabase/client';
import { authService } from './authService';

export interface UserFeedback {
  id: string;
  user_id: string;
  feedback_type: 'bug' | 'feature_request' | 'general' | 'rating';
  subject: string;
  message: string;
  rating?: number | null;
  created_at: string;
}

class FeedbackService {
  async submitFeedback(
    feedback: Omit<UserFeedback, 'id' | 'user_id' | 'created_at'>
  ): Promise<void> {
    const {
      data: { user },
    } = await authService.getUser();
    if (!user) throw new Error('Not authenticated');

    const { error } = await supabase.from('user_feedback').insert({
      user_id: user.id,
      feedback_type: feedback.feedback_type,
      subject: feedback.subject,
      message: feedback.message,
      rating: feedback.rating && feedback.rating > 0 ? feedback.rating : null,
    });

    if (error) throw error;
  }

  async getFeedback(userId?: string): Promise<UserFeedback[]> {
    const {
      data: { user },
    } = await authService.getUser();
    const targetUserId = userId || user?.id;
    if (!targetUserId) return [];

    const { data, error } = await supabase
      .from('user_feedback')
      .select('*')
      .eq('user_id', targetUserId)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return (data || []) as UserFeedback[];
  }
}

export const feedbackService = new FeedbackService();
