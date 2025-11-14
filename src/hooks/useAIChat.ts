import { useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { Baby } from '@/lib/types';
import { buildBabyContext } from '@/lib/aiContext';
import { useToast } from '@/hooks/use-toast';

interface Message {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  created_at: string;
}

export function useAIChat(baby: Baby | null) {
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const [conversationId, setConversationId] = useState<string | null>(null);

  const { data: messages = [] } = useQuery({
    queryKey: ['ai-messages', conversationId],
    queryFn: async () => {
      if (!conversationId) return [];
      const { data } = await supabase
        .from('ai_messages')
        .select('*')
        .eq('conversation_id', conversationId)
        .order('created_at', { ascending: true });
      return data || [];
    },
    enabled: !!conversationId,
  });

  const createConversationMutation = useMutation({
    mutationFn: async () => {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');

      const { data: familyMember } = await supabase
        .from('family_members')
        .select('family_id')
        .eq('user_id', user.id)
        .single();

      if (!familyMember) throw new Error('Family not found');

      const { data, error } = await supabase
        .from('ai_conversations')
        .insert({
          user_id: user.id,
          family_id: familyMember.family_id,
          baby_id: baby?.id || null,
          title: 'New Conversation',
        })
        .select()
        .single();

      if (error) throw error;
      return data;
    },
    onSuccess: (data) => {
      setConversationId(data.id);
    },
  });

  const sendMessageMutation = useMutation({
    mutationFn: async (content: string) => {
      let convId = conversationId;

      if (!convId) {
        const newConv = await createConversationMutation.mutateAsync();
        convId = newConv.id;
      }

      // Save user message
      const { error: userMsgError } = await supabase.from('ai_messages').insert({
        conversation_id: convId,
        role: 'user',
        content,
      });

      if (userMsgError) throw userMsgError;

      // Get baby context
      const babyContext = baby ? await buildBabyContext(baby) : null;

      // Get conversation history
      const { data: history } = await supabase
        .from('ai_messages')
        .select('role, content')
        .eq('conversation_id', convId)
        .order('created_at', { ascending: true });

      // Call AI assistant
      const { data, error } = await supabase.functions.invoke('ai-assistant', {
        body: {
          conversationId: convId,
          messages: history || [],
          babyContext,
        },
      });

      if (error) throw error;

      // Save assistant message
      const { error: assistantMsgError } = await supabase.from('ai_messages').insert({
        conversation_id: convId,
        role: 'assistant',
        content: data.message,
      });

      if (assistantMsgError) throw assistantMsgError;

      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['ai-messages', conversationId] });
    },
    onError: (error: any) => {
      console.error('Send message error:', error);
      toast({
        title: 'Failed to send message',
        description: error.message || 'Please try again.',
        variant: 'destructive',
      });
    },
  });

  const sendMessage = async (content: string) => {
    await sendMessageMutation.mutateAsync(content);
  };

  return {
    messages,
    isLoading: sendMessageMutation.isPending,
    sendMessage,
  };
}