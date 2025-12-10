import { useEffect, useState } from 'react';
import type { User, Session } from '@supabase/supabase-js';
import { authService } from '@/services/authService';
import { supabase } from '@/integrations/supabase/client'; // Needed for profile creation still
import { useNavigate } from 'react-router-dom';
import { identify, track } from '@/analytics/analytics';

export function useAuth() {
  const [user, setUser] = useState<User | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    // Set up auth state listener
    const subscription = authService.onAuthStateChange((event, session) => {
      setSession(session);
      setUser(session?.user ?? null);
      setLoading(false);

      // Track auth events and identify user
      if (session?.user) {
        identify(session.user.id, {
          email: session.user.email,
          created_at: session.user.created_at,
        });

        if (event === 'SIGNED_IN') {
          track('user_signed_in', { method: 'email' });
        }
      }
    });

    // Check for existing session
    authService.getSession().then(({ session }) => {
      setSession(session);
      setUser(session?.user ?? null);
      setLoading(false);
    });

    return () => subscription.unsubscribe();
  }, []);

  const signUp = async (email: string, password: string, name?: string) => {
    const { data, error } = await authService.signUp(email, password, {
      emailRedirectTo: `${window.location.origin}/`,
      data: {
        name: name || '',
      },
    });

    if (!error && data.user) {
      // Create profile
      // Note: keeping direct supabase call here for now as profile service doesn't exist yet
      // Ideally this should move to profileService.createProfile(user.id, email, name)
      const { error: profileError } = await supabase.from('profiles').insert({
        id: data.user.id,
        email: data.user.email,
        name: name || null,
      });

      if (profileError) {
        console.error('Error creating profile:', profileError);
      } else {
        // Track signup
        track('user_signed_up', {
          method: 'email',
          has_baby: false, // Will be updated if baby created during onboarding
        });
      }
    }

    return { data, error };
  };

  const signIn = async (email: string, password: string) => {
    const { data, error } = await authService.signInWithPassword({
      email,
      password,
    });
    return { data, error };
  };

  const signOut = async () => {
    try {
      await authService.signOut();
      navigate('/home');
      return { error: null };
    } catch (error) {
      return { error };
    }
  };

  return {
    user,
    session,
    loading,
    signUp,
    signIn,
    signOut,
  };
}
