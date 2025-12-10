export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[];

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: '13.0.5';
  };
  public: {
    Tables: {
      activity_feed: {
        Row: {
          action_type: string;
          actor_id: string;
          created_at: string | null;
          entity_id: string;
          entity_type: string;
          family_id: string;
          id: string;
          metadata: Json | null;
          summary: string;
        };
        Insert: {
          action_type: string;
          actor_id: string;
          created_at?: string | null;
          entity_id: string;
          entity_type: string;
          family_id: string;
          id?: string;
          metadata?: Json | null;
          summary: string;
        };
        Update: {
          action_type?: string;
          actor_id?: string;
          created_at?: string | null;
          entity_id?: string;
          entity_type?: string;
          family_id?: string;
          id?: string;
          metadata?: Json | null;
          summary?: string;
        };
        Relationships: [];
      };
      ai_conversations: {
        Row: {
          baby_id: string | null;
          created_at: string | null;
          family_id: string;
          id: string;
          title: string | null;
          updated_at: string | null;
          user_id: string;
        };
        Insert: {
          baby_id?: string | null;
          created_at?: string | null;
          family_id: string;
          id?: string;
          title?: string | null;
          updated_at?: string | null;
          user_id: string;
        };
        Update: {
          baby_id?: string | null;
          created_at?: string | null;
          family_id?: string;
          id?: string;
          title?: string | null;
          updated_at?: string | null;
          user_id?: string;
        };
        Relationships: [];
      };
      ai_messages: {
        Row: {
          content: string;
          conversation_id: string;
          created_at: string | null;
          id: string;
          metadata: Json | null;
          role: string;
        };
        Insert: {
          content: string;
          conversation_id: string;
          created_at?: string | null;
          id?: string;
          metadata?: Json | null;
          role: string;
        };
        Update: {
          content?: string;
          conversation_id?: string;
          created_at?: string | null;
          id?: string;
          metadata?: Json | null;
          role?: string;
        };
        Relationships: [];
      };
      anomalies: {
        Row: {
          acknowledged_at: string | null;
          acknowledged_by: string | null;
          anomaly_type: string;
          baby_id: string;
          created_at: string | null;
          description: string;
          detected_at: string | null;
          id: string;
          metrics: Json | null;
          resolved_at: string | null;
          severity: string;
          suggested_actions: string[] | null;
        };
        Insert: {
          acknowledged_at?: string | null;
          acknowledged_by?: string | null;
          anomaly_type: string;
          baby_id: string;
          created_at?: string | null;
          description: string;
          detected_at?: string | null;
          id?: string;
          metrics?: Json | null;
          resolved_at?: string | null;
          severity: string;
          suggested_actions?: string[] | null;
        };
        Update: {
          acknowledged_at?: string | null;
          acknowledged_by?: string | null;
          anomaly_type?: string;
          baby_id?: string;
          created_at?: string | null;
          description?: string;
          detected_at?: string | null;
          id?: string;
          metrics?: Json | null;
          resolved_at?: string | null;
          severity?: string;
          suggested_actions?: string[] | null;
        };
        Relationships: [];
      };
      app_settings: {
        Row: {
          caregiver_mode: boolean | null;
          created_at: string | null;
          font_size: string | null;
          id: string;
          theme: string | null;
          updated_at: string | null;
          user_id: string;
        };
        Insert: {
          caregiver_mode?: boolean | null;
          created_at?: string | null;
          font_size?: string | null;
          id?: string;
          theme?: string | null;
          updated_at?: string | null;
          user_id: string;
        };
        Update: {
          caregiver_mode?: boolean | null;
          created_at?: string | null;
          font_size?: string | null;
          id?: string;
          theme?: string | null;
          updated_at?: string | null;
          user_id?: string;
        };
        Relationships: [];
      };
      babies: {
        Row: {
          created_at: string | null;
          date_of_birth: string;
          due_date: string | null;
          family_id: string;
          id: string;
          name: string;
          primary_feeding_style: string | null;
          sex: string | null;
          timezone: string | null;
          updated_at: string | null;
        };
        Insert: {
          created_at?: string | null;
          date_of_birth: string;
          due_date?: string | null;
          family_id: string;
          id?: string;
          name: string;
          primary_feeding_style?: string | null;
          sex?: string | null;
          timezone?: string | null;
          updated_at?: string | null;
        };
        Update: {
          created_at?: string | null;
          date_of_birth?: string;
          due_date?: string | null;
          family_id?: string;
          id?: string;
          name?: string;
          primary_feeding_style?: string | null;
          sex?: string | null;
          timezone?: string | null;
          updated_at?: string | null;
        };
        Relationships: [
          {
            foreignKeyName: 'babies_family_id_fkey';
            columns: ['family_id'];
            isOneToOne: false;
            referencedRelation: 'families';
            referencedColumns: ['id'];
          },
        ];
      };
      baby_book_pages: {
        Row: {
          book_id: string;
          content: string | null;
          created_at: string | null;
          date: string | null;
          id: string;
          layout_type: string | null;
          page_number: number;
          photos: Json | null;
          title: string | null;
        };
        Insert: {
          book_id: string;
          content?: string | null;
          created_at?: string | null;
          date?: string | null;
          id?: string;
          layout_type?: string | null;
          page_number: number;
          photos?: Json | null;
          title?: string | null;
        };
        Update: {
          book_id?: string;
          content?: string | null;
          created_at?: string | null;
          date?: string | null;
          id?: string;
          layout_type?: string | null;
          page_number?: number;
          photos?: Json | null;
          title?: string | null;
        };
        Relationships: [];
      };
      baby_books: {
        Row: {
          baby_id: string;
          cover_photo_url: string | null;
          created_at: string | null;
          created_by: string;
          description: string | null;
          id: string;
          is_public: boolean | null;
          password_hash: string | null;
          share_token: string | null;
          title: string;
        };
        Insert: {
          baby_id: string;
          cover_photo_url?: string | null;
          created_at?: string | null;
          created_by: string;
          description?: string | null;
          id?: string;
          is_public?: boolean | null;
          password_hash?: string | null;
          share_token?: string | null;
          title: string;
        };
        Update: {
          baby_id?: string;
          cover_photo_url?: string | null;
          created_at?: string | null;
          created_by?: string;
          description?: string | null;
          id?: string;
          is_public?: boolean | null;
          password_hash?: string | null;
          share_token?: string | null;
          title?: string;
        };
        Relationships: [];
      };
      behavior_patterns: {
        Row: {
          baby_id: string;
          confidence: number | null;
          created_at: string | null;
          description: string | null;
          detected_at: string | null;
          id: string;
          last_occurrence: string | null;
          metadata: Json | null;
          occurrences: number | null;
          pattern_type: string;
        };
        Insert: {
          baby_id: string;
          confidence?: number | null;
          created_at?: string | null;
          description?: string | null;
          detected_at?: string | null;
          id?: string;
          last_occurrence?: string | null;
          metadata?: Json | null;
          occurrences?: number | null;
          pattern_type: string;
        };
        Update: {
          baby_id?: string;
          confidence?: number | null;
          created_at?: string | null;
          description?: string | null;
          detected_at?: string | null;
          id?: string;
          last_occurrence?: string | null;
          metadata?: Json | null;
          occurrences?: number | null;
          pattern_type?: string;
        };
        Relationships: [];
      };
      caregiver_invites: {
        Row: {
          created_at: string | null;
          email: string;
          expires_at: string;
          family_id: string;
          id: string;
          invited_by: string | null;
          role: string;
          status: string;
          token: string;
          updated_at: string | null;
        };
        Insert: {
          created_at?: string | null;
          email: string;
          expires_at?: string;
          family_id: string;
          id?: string;
          invited_by?: string | null;
          role?: string;
          status?: string;
          token?: string;
          updated_at?: string | null;
        };
        Update: {
          created_at?: string | null;
          email?: string;
          expires_at?: string;
          family_id?: string;
          id?: string;
          invited_by?: string | null;
          role?: string;
          status?: string;
          token?: string;
          updated_at?: string | null;
        };
        Relationships: [
          {
            foreignKeyName: 'caregiver_invites_family_id_fkey';
            columns: ['family_id'];
            isOneToOne: false;
            referencedRelation: 'families';
            referencedColumns: ['id'];
          },
        ];
      };
      comparison_snapshots: {
        Row: {
          after_date: string;
          after_photo_url: string;
          baby_id: string;
          before_date: string;
          before_photo_url: string;
          created_at: string | null;
          created_by: string;
          description: string | null;
          id: string;
          title: string;
        };
        Insert: {
          after_date: string;
          after_photo_url: string;
          baby_id: string;
          before_date: string;
          before_photo_url: string;
          created_at?: string | null;
          created_by: string;
          description?: string | null;
          id?: string;
          title: string;
        };
        Update: {
          after_date?: string;
          after_photo_url?: string;
          baby_id?: string;
          before_date?: string;
          before_photo_url?: string;
          created_at?: string | null;
          created_by?: string;
          description?: string | null;
          id?: string;
          title?: string;
        };
        Relationships: [];
      };
      cry_insight_sessions: {
        Row: {
          baby_id: string;
          category: string | null;
          confidence: number | null;
          created_at: string | null;
          created_by: string | null;
          id: string;
        };
        Insert: {
          baby_id: string;
          category?: string | null;
          confidence?: number | null;
          created_at?: string | null;
          created_by?: string | null;
          id?: string;
        };
        Update: {
          baby_id?: string;
          category?: string | null;
          confidence?: number | null;
          created_at?: string | null;
          created_by?: string | null;
          id?: string;
        };
        Relationships: [
          {
            foreignKeyName: 'cry_insight_sessions_baby_id_fkey';
            columns: ['baby_id'];
            isOneToOne: false;
            referencedRelation: 'babies';
            referencedColumns: ['id'];
          },
        ];
      };
      cry_logs: {
        Row: {
          baby_id: string;
          confidence: number | null;
          context: Json | null;
          created_at: string | null;
          created_by: string | null;
          cry_type: string | null;
          end_time: string | null;
          family_id: string;
          id: string;
          note: string | null;
          resolved_by: string | null;
          start_time: string;
          updated_at: string | null;
        };
        Insert: {
          baby_id: string;
          confidence?: number | null;
          context?: Json | null;
          created_at?: string | null;
          created_by?: string | null;
          cry_type?: string | null;
          end_time?: string | null;
          family_id: string;
          id?: string;
          note?: string | null;
          resolved_by?: string | null;
          start_time: string;
          updated_at?: string | null;
        };
        Update: {
          baby_id?: string;
          confidence?: number | null;
          context?: Json | null;
          created_at?: string | null;
          created_by?: string | null;
          cry_type?: string | null;
          end_time?: string | null;
          family_id?: string;
          id?: string;
          note?: string | null;
          resolved_by?: string | null;
          start_time?: string;
          updated_at?: string | null;
        };
        Relationships: [];
      };
      events: {
        Row: {
          amount: number | null;
          baby_id: string;
          bottle_type: string | null;
          created_at: string | null;
          created_by: string | null;
          duration_min: number | null;
          duration_sec: number | null;
          end_time: string | null;
          family_id: string;
          id: string;
          note: string | null;
          side: string | null;
          start_time: string;
          subtype: string | null;
          type: string;
          unit: string | null;
          updated_at: string | null;
        };
        Insert: {
          amount?: number | null;
          baby_id: string;
          bottle_type?: string | null;
          created_at?: string | null;
          created_by?: string | null;
          duration_min?: number | null;
          duration_sec?: number | null;
          end_time?: string | null;
          family_id: string;
          id?: string;
          note?: string | null;
          side?: string | null;
          start_time: string;
          subtype?: string | null;
          type: string;
          unit?: string | null;
          updated_at?: string | null;
        };
        Update: {
          amount?: number | null;
          baby_id?: string;
          bottle_type?: string | null;
          created_at?: string | null;
          created_by?: string | null;
          duration_min?: number | null;
          duration_sec?: number | null;
          end_time?: string | null;
          family_id?: string;
          id?: string;
          note?: string | null;
          side?: string | null;
          start_time?: string;
          subtype?: string | null;
          type?: string;
          unit?: string | null;
          updated_at?: string | null;
        };
        Relationships: [
          {
            foreignKeyName: 'events_baby_id_fkey';
            columns: ['baby_id'];
            isOneToOne: false;
            referencedRelation: 'babies';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'events_family_id_fkey';
            columns: ['family_id'];
            isOneToOne: false;
            referencedRelation: 'families';
            referencedColumns: ['id'];
          },
        ];
      };
      families: {
        Row: {
          created_at: string | null;
          id: string;
          name: string;
          updated_at: string | null;
        };
        Insert: {
          created_at?: string | null;
          id?: string;
          name: string;
          updated_at?: string | null;
        };
        Update: {
          created_at?: string | null;
          id?: string;
          name?: string;
          updated_at?: string | null;
        };
        Relationships: [];
      };
      family_members: {
        Row: {
          created_at: string | null;
          family_id: string;
          id: string;
          role: string;
          user_id: string;
        };
        Insert: {
          created_at?: string | null;
          family_id: string;
          id?: string;
          role?: string;
          user_id: string;
        };
        Update: {
          created_at?: string | null;
          family_id?: string;
          id?: string;
          role?: string;
          user_id?: string;
        };
        Relationships: [
          {
            foreignKeyName: 'family_members_family_id_fkey';
            columns: ['family_id'];
            isOneToOne: false;
            referencedRelation: 'families';
            referencedColumns: ['id'];
          },
        ];
      };
      family_shares: {
        Row: {
          baby_id: string;
          can_download: boolean | null;
          created_at: string | null;
          created_by: string;
          entity_id: string;
          expires_at: string | null;
          id: string;
          max_views: number | null;
          password_hash: string | null;
          share_token: string | null;
          share_type: string;
          view_count: number | null;
        };
        Insert: {
          baby_id: string;
          can_download?: boolean | null;
          created_at?: string | null;
          created_by: string;
          entity_id: string;
          expires_at?: string | null;
          id?: string;
          max_views?: number | null;
          password_hash?: string | null;
          share_token?: string | null;
          share_type: string;
          view_count?: number | null;
        };
        Update: {
          baby_id?: string;
          can_download?: boolean | null;
          created_at?: string | null;
          created_by?: string;
          entity_id?: string;
          expires_at?: string | null;
          id?: string;
          max_views?: number | null;
          password_hash?: string | null;
          share_token?: string | null;
          share_type?: string;
          view_count?: number | null;
        };
        Relationships: [];
      };
      growth_records: {
        Row: {
          baby_id: string;
          created_at: string | null;
          head_circumference: number | null;
          id: string;
          length: number | null;
          note: string | null;
          percentile_head: number | null;
          percentile_length: number | null;
          percentile_weight: number | null;
          recorded_at: string;
          recorded_by: string | null;
          unit_system: string | null;
          weight: number | null;
        };
        Insert: {
          baby_id: string;
          created_at?: string | null;
          head_circumference?: number | null;
          id?: string;
          length?: number | null;
          note?: string | null;
          percentile_head?: number | null;
          percentile_length?: number | null;
          percentile_weight?: number | null;
          recorded_at: string;
          recorded_by?: string | null;
          unit_system?: string | null;
          weight?: number | null;
        };
        Update: {
          baby_id?: string;
          created_at?: string | null;
          head_circumference?: number | null;
          id?: string;
          length?: number | null;
          note?: string | null;
          percentile_head?: number | null;
          percentile_length?: number | null;
          percentile_weight?: number | null;
          recorded_at?: string;
          recorded_by?: string | null;
          unit_system?: string | null;
          weight?: number | null;
        };
        Relationships: [
          {
            foreignKeyName: 'growth_records_baby_id_fkey';
            columns: ['baby_id'];
            isOneToOne: false;
            referencedRelation: 'babies';
            referencedColumns: ['id'];
          },
        ];
      };
      handoff_reports: {
        Row: {
          baby_id: string;
          concerns: string[] | null;
          created_at: string | null;
          events_summary: Json | null;
          from_user_id: string;
          highlights: string[] | null;
          id: string;
          notes: string | null;
          shift_end: string;
          shift_start: string;
          summary: string | null;
          to_user_id: string | null;
        };
        Insert: {
          baby_id: string;
          concerns?: string[] | null;
          created_at?: string | null;
          events_summary?: Json | null;
          from_user_id: string;
          highlights?: string[] | null;
          id?: string;
          notes?: string | null;
          shift_end: string;
          shift_start: string;
          summary?: string | null;
          to_user_id?: string | null;
        };
        Update: {
          baby_id?: string;
          concerns?: string[] | null;
          created_at?: string | null;
          events_summary?: Json | null;
          from_user_id?: string;
          highlights?: string[] | null;
          id?: string;
          notes?: string | null;
          shift_end?: string;
          shift_start?: string;
          summary?: string | null;
          to_user_id?: string | null;
        };
        Relationships: [];
      };
      health_records: {
        Row: {
          baby_id: string;
          created_at: string | null;
          created_by: string | null;
          diagnosis: string | null;
          doctor_name: string | null;
          id: string;
          note: string | null;
          record_type: string;
          recorded_at: string;
          temperature: number | null;
          title: string;
          treatment: string | null;
          vaccine_dose: string | null;
          vaccine_name: string | null;
        };
        Insert: {
          baby_id: string;
          created_at?: string | null;
          created_by?: string | null;
          diagnosis?: string | null;
          doctor_name?: string | null;
          id?: string;
          note?: string | null;
          record_type: string;
          recorded_at: string;
          temperature?: number | null;
          title: string;
          treatment?: string | null;
          vaccine_dose?: string | null;
          vaccine_name?: string | null;
        };
        Update: {
          baby_id?: string;
          created_at?: string | null;
          created_by?: string | null;
          diagnosis?: string | null;
          doctor_name?: string | null;
          id?: string;
          note?: string | null;
          record_type?: string;
          recorded_at?: string;
          temperature?: number | null;
          title?: string;
          treatment?: string | null;
          vaccine_dose?: string | null;
          vaccine_name?: string | null;
        };
        Relationships: [
          {
            foreignKeyName: 'health_records_baby_id_fkey';
            columns: ['baby_id'];
            isOneToOne: false;
            referencedRelation: 'babies';
            referencedColumns: ['id'];
          },
        ];
      };
      journal_entries: {
        Row: {
          activities: string[] | null;
          baby_id: string;
          content: string;
          created_at: string | null;
          created_by: string;
          entry_date: string;
          firsts: string[] | null;
          funny_moments: string[] | null;
          id: string;
          is_published: boolean | null;
          media_ids: Json | null;
          mood: string | null;
          title: string | null;
          updated_at: string | null;
          weather: string | null;
        };
        Insert: {
          activities?: string[] | null;
          baby_id: string;
          content: string;
          created_at?: string | null;
          created_by: string;
          entry_date: string;
          firsts?: string[] | null;
          funny_moments?: string[] | null;
          id?: string;
          is_published?: boolean | null;
          media_ids?: Json | null;
          mood?: string | null;
          title?: string | null;
          updated_at?: string | null;
          weather?: string | null;
        };
        Update: {
          activities?: string[] | null;
          baby_id?: string;
          content?: string;
          created_at?: string | null;
          created_by?: string;
          entry_date?: string;
          firsts?: string[] | null;
          funny_moments?: string[] | null;
          id?: string;
          is_published?: boolean | null;
          media_ids?: Json | null;
          mood?: string | null;
          title?: string | null;
          updated_at?: string | null;
          weather?: string | null;
        };
        Relationships: [];
      };
      memory_tags: {
        Row: {
          baby_id: string;
          color: string | null;
          created_at: string | null;
          icon: string | null;
          id: string;
          tag_name: string;
        };
        Insert: {
          baby_id: string;
          color?: string | null;
          created_at?: string | null;
          icon?: string | null;
          id?: string;
          tag_name: string;
        };
        Update: {
          baby_id?: string;
          color?: string | null;
          created_at?: string | null;
          icon?: string | null;
          id?: string;
          tag_name?: string;
        };
        Relationships: [];
      };
      milestones: {
        Row: {
          achieved_at: string | null;
          baby_id: string;
          category: string;
          created_at: string | null;
          created_by: string | null;
          description: string | null;
          expected_age_months: number | null;
          id: string;
          note: string | null;
          photo_url: string | null;
          title: string;
        };
        Insert: {
          achieved_at?: string | null;
          baby_id: string;
          category: string;
          created_at?: string | null;
          created_by?: string | null;
          description?: string | null;
          expected_age_months?: number | null;
          id?: string;
          note?: string | null;
          photo_url?: string | null;
          title: string;
        };
        Update: {
          achieved_at?: string | null;
          baby_id?: string;
          category?: string;
          created_at?: string | null;
          created_by?: string | null;
          description?: string | null;
          expected_age_months?: number | null;
          id?: string;
          note?: string | null;
          photo_url?: string | null;
          title?: string;
        };
        Relationships: [
          {
            foreignKeyName: 'milestones_baby_id_fkey';
            columns: ['baby_id'];
            isOneToOne: false;
            referencedRelation: 'babies';
            referencedColumns: ['id'];
          },
        ];
      };
      monthly_recaps: {
        Row: {
          baby_id: string;
          created_at: string | null;
          generated_at: string | null;
          highlights: Json | null;
          id: string;
          is_published: boolean | null;
          month: number;
          video_url: string | null;
          year: number;
        };
        Insert: {
          baby_id: string;
          created_at?: string | null;
          generated_at?: string | null;
          highlights?: Json | null;
          id?: string;
          is_published?: boolean | null;
          month: number;
          video_url?: string | null;
          year: number;
        };
        Update: {
          baby_id?: string;
          created_at?: string | null;
          generated_at?: string | null;
          highlights?: Json | null;
          id?: string;
          is_published?: boolean | null;
          month?: number;
          video_url?: string | null;
          year?: number;
        };
        Relationships: [];
      };
      nap_feedback: {
        Row: {
          baby_id: string;
          created_at: string | null;
          id: string;
          predicted_end: string;
          predicted_start: string;
          rating: string | null;
        };
        Insert: {
          baby_id: string;
          created_at?: string | null;
          id?: string;
          predicted_end: string;
          predicted_start: string;
          rating?: string | null;
        };
        Update: {
          baby_id?: string;
          created_at?: string | null;
          id?: string;
          predicted_end?: string;
          predicted_start?: string;
          rating?: string | null;
        };
        Relationships: [
          {
            foreignKeyName: 'nap_feedback_baby_id_fkey';
            columns: ['baby_id'];
            isOneToOne: false;
            referencedRelation: 'babies';
            referencedColumns: ['id'];
          },
        ];
      };
      parent_medications: {
        Row: {
          created_at: string | null;
          dosage: string | null;
          end_date: string | null;
          frequency: string | null;
          id: string;
          is_active: boolean | null;
          medication_name: string;
          note: string | null;
          start_date: string;
          updated_at: string | null;
          user_id: string;
        };
        Insert: {
          created_at?: string | null;
          dosage?: string | null;
          end_date?: string | null;
          frequency?: string | null;
          id?: string;
          is_active?: boolean | null;
          medication_name: string;
          note?: string | null;
          start_date: string;
          updated_at?: string | null;
          user_id: string;
        };
        Update: {
          created_at?: string | null;
          dosage?: string | null;
          end_date?: string | null;
          frequency?: string | null;
          id?: string;
          is_active?: boolean | null;
          medication_name?: string;
          note?: string | null;
          start_date?: string;
          updated_at?: string | null;
          user_id?: string;
        };
        Relationships: [];
      };
      parent_wellness_logs: {
        Row: {
          created_at: string | null;
          id: string;
          log_date: string;
          mood: string | null;
          note: string | null;
          sleep_quality: string | null;
          updated_at: string | null;
          user_id: string;
          water_intake_ml: number | null;
        };
        Insert: {
          created_at?: string | null;
          id?: string;
          log_date: string;
          mood?: string | null;
          note?: string | null;
          sleep_quality?: string | null;
          updated_at?: string | null;
          user_id: string;
          water_intake_ml?: number | null;
        };
        Update: {
          created_at?: string | null;
          id?: string;
          log_date?: string;
          mood?: string | null;
          note?: string | null;
          sleep_quality?: string | null;
          updated_at?: string | null;
          user_id?: string;
          water_intake_ml?: number | null;
        };
        Relationships: [];
      };
      prediction_feedback: {
        Row: {
          comments: string | null;
          created_at: string | null;
          feedback_type: string;
          id: string;
          prediction_id: string;
          user_id: string;
        };
        Insert: {
          comments?: string | null;
          created_at?: string | null;
          feedback_type: string;
          id?: string;
          prediction_id: string;
          user_id: string;
        };
        Update: {
          comments?: string | null;
          created_at?: string | null;
          feedback_type?: string;
          id?: string;
          prediction_id?: string;
          user_id?: string;
        };
        Relationships: [];
      };
      predictions: {
        Row: {
          actual_outcome: Json | null;
          baby_id: string;
          confidence_score: number | null;
          created_at: string | null;
          id: string;
          model_version: string | null;
          predicted_at: string | null;
          prediction_data: Json;
          prediction_type: string;
          was_accurate: boolean | null;
        };
        Insert: {
          actual_outcome?: Json | null;
          baby_id: string;
          confidence_score?: number | null;
          created_at?: string | null;
          id?: string;
          model_version?: string | null;
          predicted_at?: string | null;
          prediction_data: Json;
          prediction_type: string;
          was_accurate?: boolean | null;
        };
        Update: {
          actual_outcome?: Json | null;
          baby_id?: string;
          confidence_score?: number | null;
          created_at?: string | null;
          id?: string;
          model_version?: string | null;
          predicted_at?: string | null;
          prediction_data?: Json;
          prediction_type?: string;
          was_accurate?: boolean | null;
        };
        Relationships: [];
      };
      private_notes: {
        Row: {
          baby_id: string;
          content: string;
          created_at: string | null;
          id: string;
          related_to_id: string | null;
          related_to_type: string | null;
          user_id: string;
        };
        Insert: {
          baby_id: string;
          content: string;
          created_at?: string | null;
          id?: string;
          related_to_id?: string | null;
          related_to_type?: string | null;
          user_id: string;
        };
        Update: {
          baby_id?: string;
          content?: string;
          created_at?: string | null;
          id?: string;
          related_to_id?: string | null;
          related_to_type?: string | null;
          user_id?: string;
        };
        Relationships: [];
      };
      profiles: {
        Row: {
          ai_data_sharing_enabled: boolean | null;
          ai_preferences_updated_at: string | null;
          created_at: string | null;
          email: string | null;
          id: string;
          name: string | null;
          updated_at: string | null;
        };
        Insert: {
          ai_data_sharing_enabled?: boolean | null;
          ai_preferences_updated_at?: string | null;
          created_at?: string | null;
          email?: string | null;
          id: string;
          name?: string | null;
          updated_at?: string | null;
        };
        Update: {
          ai_data_sharing_enabled?: boolean | null;
          ai_preferences_updated_at?: string | null;
          created_at?: string | null;
          email?: string | null;
          id?: string;
          name?: string | null;
          updated_at?: string | null;
        };
        Relationships: [];
      };
      recommendations: {
        Row: {
          acted_on: boolean | null;
          baby_id: string;
          category: string;
          confidence: number | null;
          created_at: string | null;
          dismissed_at: string | null;
          dismissed_by: string | null;
          expires_at: string | null;
          id: string;
          priority: number | null;
          reasoning: string | null;
          recommendation: string;
        };
        Insert: {
          acted_on?: boolean | null;
          baby_id: string;
          category: string;
          confidence?: number | null;
          created_at?: string | null;
          dismissed_at?: string | null;
          dismissed_by?: string | null;
          expires_at?: string | null;
          id?: string;
          priority?: number | null;
          reasoning?: string | null;
          recommendation: string;
        };
        Update: {
          acted_on?: boolean | null;
          baby_id?: string;
          category?: string;
          confidence?: number | null;
          created_at?: string | null;
          dismissed_at?: string | null;
          dismissed_by?: string | null;
          expires_at?: string | null;
          id?: string;
          priority?: number | null;
          reasoning?: string | null;
          recommendation?: string;
        };
        Relationships: [];
      };
      sleep_regressions: {
        Row: {
          baby_id: string;
          created_at: string | null;
          detected_at: string;
          id: string;
          regression_type: string | null;
          resolved_at: string | null;
          severity: string | null;
          symptoms: Json | null;
        };
        Insert: {
          baby_id: string;
          created_at?: string | null;
          detected_at: string;
          id?: string;
          regression_type?: string | null;
          resolved_at?: string | null;
          severity?: string | null;
          symptoms?: Json | null;
        };
        Update: {
          baby_id?: string;
          created_at?: string | null;
          detected_at?: string;
          id?: string;
          regression_type?: string | null;
          resolved_at?: string | null;
          severity?: string | null;
          symptoms?: Json | null;
        };
        Relationships: [];
      };
      sleep_training_logs: {
        Row: {
          bedtime_started: string | null;
          created_at: string | null;
          fell_asleep_at: string | null;
          id: string;
          intervention_notes: string | null;
          night_date: string;
          night_wakings: number | null;
          session_id: string;
          success_rating: number | null;
          total_crying_minutes: number | null;
        };
        Insert: {
          bedtime_started?: string | null;
          created_at?: string | null;
          fell_asleep_at?: string | null;
          id?: string;
          intervention_notes?: string | null;
          night_date: string;
          night_wakings?: number | null;
          session_id: string;
          success_rating?: number | null;
          total_crying_minutes?: number | null;
        };
        Update: {
          bedtime_started?: string | null;
          created_at?: string | null;
          fell_asleep_at?: string | null;
          id?: string;
          intervention_notes?: string | null;
          night_date?: string;
          night_wakings?: number | null;
          session_id?: string;
          success_rating?: number | null;
          total_crying_minutes?: number | null;
        };
        Relationships: [];
      };
      sleep_training_sessions: {
        Row: {
          baby_id: string;
          check_intervals: Json | null;
          created_at: string | null;
          id: string;
          method: string;
          notes: string | null;
          start_date: string;
          status: string | null;
          target_bedtime: string | null;
          target_wake_time: string | null;
          updated_at: string | null;
        };
        Insert: {
          baby_id: string;
          check_intervals?: Json | null;
          created_at?: string | null;
          id?: string;
          method: string;
          notes?: string | null;
          start_date: string;
          status?: string | null;
          target_bedtime?: string | null;
          target_wake_time?: string | null;
          updated_at?: string | null;
        };
        Update: {
          baby_id?: string;
          check_intervals?: Json | null;
          created_at?: string | null;
          id?: string;
          method?: string;
          notes?: string | null;
          start_date?: string;
          status?: string | null;
          target_bedtime?: string | null;
          target_wake_time?: string | null;
          updated_at?: string | null;
        };
        Relationships: [];
      };
      subscriptions: {
        Row: {
          cancel_at_period_end: boolean | null;
          created_at: string | null;
          current_period_end: string | null;
          current_period_start: string | null;
          id: string;
          status: string;
          stripe_customer_id: string;
          stripe_price_id: string | null;
          stripe_subscription_id: string | null;
          updated_at: string | null;
          user_id: string;
        };
        Insert: {
          cancel_at_period_end?: boolean | null;
          created_at?: string | null;
          current_period_end?: string | null;
          current_period_start?: string | null;
          id?: string;
          status?: string;
          stripe_customer_id: string;
          stripe_price_id?: string | null;
          stripe_subscription_id?: string | null;
          updated_at?: string | null;
          user_id: string;
        };
        Update: {
          cancel_at_period_end?: boolean | null;
          created_at?: string | null;
          current_period_end?: string | null;
          current_period_start?: string | null;
          id?: string;
          status?: string;
          stripe_customer_id?: string;
          stripe_price_id?: string | null;
          stripe_subscription_id?: string | null;
          updated_at?: string | null;
          user_id?: string;
        };
        Relationships: [];
      };
      tagged_memories: {
        Row: {
          created_at: string | null;
          id: string;
          memory_id: string;
          memory_type: string;
          tag_id: string;
        };
        Insert: {
          created_at?: string | null;
          id?: string;
          memory_id: string;
          memory_type: string;
          tag_id: string;
        };
        Update: {
          created_at?: string | null;
          id?: string;
          memory_id?: string;
          memory_type?: string;
          tag_id?: string;
        };
        Relationships: [];
      };
      user_feedback: {
        Row: {
          created_at: string | null;
          feedback_type: string;
          id: string;
          message: string;
          rating: number | null;
          status: string | null;
          subject: string | null;
          user_id: string;
        };
        Insert: {
          created_at?: string | null;
          feedback_type: string;
          id?: string;
          message: string;
          rating?: number | null;
          status?: string | null;
          subject?: string | null;
          user_id: string;
        };
        Update: {
          created_at?: string | null;
          feedback_type?: string;
          id?: string;
          message?: string;
          rating?: number | null;
          status?: string | null;
          subject?: string | null;
          user_id?: string;
        };
        Relationships: [];
      };
      user_roles: {
        Row: {
          created_at: string | null;
          family_id: string;
          id: string;
          role: Database['public']['Enums']['app_role'];
          user_id: string;
        };
        Insert: {
          created_at?: string | null;
          family_id: string;
          id?: string;
          role: Database['public']['Enums']['app_role'];
          user_id: string;
        };
        Update: {
          created_at?: string | null;
          family_id?: string;
          id?: string;
          role?: Database['public']['Enums']['app_role'];
          user_id?: string;
        };
        Relationships: [
          {
            foreignKeyName: 'user_roles_family_id_fkey';
            columns: ['family_id'];
            isOneToOne: false;
            referencedRelation: 'families';
            referencedColumns: ['id'];
          },
        ];
      };
      videos: {
        Row: {
          baby_id: string;
          created_at: string | null;
          description: string | null;
          duration_seconds: number | null;
          file_size_bytes: number | null;
          id: string;
          is_favorite: boolean | null;
          milestone_id: string | null;
          recorded_at: string;
          tags: string[] | null;
          thumbnail_url: string | null;
          title: string | null;
          uploaded_by: string;
          video_url: string;
        };
        Insert: {
          baby_id: string;
          created_at?: string | null;
          description?: string | null;
          duration_seconds?: number | null;
          file_size_bytes?: number | null;
          id?: string;
          is_favorite?: boolean | null;
          milestone_id?: string | null;
          recorded_at: string;
          tags?: string[] | null;
          thumbnail_url?: string | null;
          title?: string | null;
          uploaded_by: string;
          video_url: string;
        };
        Update: {
          baby_id?: string;
          created_at?: string | null;
          description?: string | null;
          duration_seconds?: number | null;
          file_size_bytes?: number | null;
          id?: string;
          is_favorite?: boolean | null;
          milestone_id?: string | null;
          recorded_at?: string;
          tags?: string[] | null;
          thumbnail_url?: string | null;
          title?: string | null;
          uploaded_by?: string;
          video_url?: string;
        };
        Relationships: [];
      };
      wake_windows: {
        Row: {
          actual_window_minutes: number | null;
          age_in_months: number;
          baby_id: string;
          id: string;
          recommended_window_minutes: number | null;
          recorded_at: string | null;
          resulted_in_good_nap: boolean | null;
        };
        Insert: {
          actual_window_minutes?: number | null;
          age_in_months: number;
          baby_id: string;
          id?: string;
          recommended_window_minutes?: number | null;
          recorded_at?: string | null;
          resulted_in_good_nap?: boolean | null;
        };
        Update: {
          actual_window_minutes?: number | null;
          age_in_months?: number;
          baby_id?: string;
          id?: string;
          recommended_window_minutes?: number | null;
          recorded_at?: string | null;
          resulted_in_good_nap?: boolean | null;
        };
        Relationships: [];
      };
    };
    Views: {
      daily_summaries: {
        Row: {
          avg_feed_amount: number | null;
          baby_id: string | null;
          date: string | null;
          diaper_count: number | null;
          family_id: string | null;
          feed_count: number | null;
          sleep_count: number | null;
          total_feed_amount: number | null;
          total_sleep_hours: number | null;
        };
        Relationships: [
          {
            foreignKeyName: 'events_baby_id_fkey';
            columns: ['baby_id'];
            isOneToOne: false;
            referencedRelation: 'babies';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'events_family_id_fkey';
            columns: ['family_id'];
            isOneToOne: false;
            referencedRelation: 'families';
            referencedColumns: ['id'];
          },
        ];
      };
    };
    Functions: {
      has_any_family_role: {
        Args: {
          _family_id: string;
          _roles: Database['public']['Enums']['app_role'][];
          _user_id: string;
        };
        Returns: boolean;
      };
      has_family_role: {
        Args: {
          _family_id: string;
          _role: Database['public']['Enums']['app_role'];
          _user_id: string;
        };
        Returns: boolean;
      };
    };
    Enums: {
      app_role: 'admin' | 'member' | 'viewer';
    };
    CompositeTypes: {
      [_ in never]: never;
    };
  };
};

type DatabaseWithoutInternals = Omit<Database, '__InternalSupabase'>;

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, 'public'>];

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema['Tables'] & DefaultSchema['Views'])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables'] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Views'])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals;
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables'] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Views'])[TableName] extends {
      Row: infer R;
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema['Tables'] & DefaultSchema['Views'])
    ? (DefaultSchema['Tables'] & DefaultSchema['Views'])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R;
      }
      ? R
      : never
    : never;

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema['Tables']
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables']
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals;
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables'][TableName] extends {
      Insert: infer I;
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema['Tables']
    ? DefaultSchema['Tables'][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I;
      }
      ? I
      : never
    : never;

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema['Tables']
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables']
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals;
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables'][TableName] extends {
      Update: infer U;
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema['Tables']
    ? DefaultSchema['Tables'][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U;
      }
      ? U
      : never
    : never;

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema['Enums']
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions['schema']]['Enums']
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals;
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions['schema']]['Enums'][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema['Enums']
    ? DefaultSchema['Enums'][DefaultSchemaEnumNameOrOptions]
    : never;

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema['CompositeTypes']
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions['schema']]['CompositeTypes']
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals;
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions['schema']]['CompositeTypes'][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema['CompositeTypes']
    ? DefaultSchema['CompositeTypes'][PublicCompositeTypeNameOrOptions]
    : never;

export const Constants = {
  public: {
    Enums: {
      app_role: ['admin', 'member', 'viewer'],
    },
  },
} as const;
