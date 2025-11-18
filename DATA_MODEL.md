# Data Model Documentation

This document describes all Supabase tables used in the application, their structure, and which features depend on them.

## Core Tables (P0 MVP)

### `profiles`
User profile information.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid (PK) | User ID, references `auth.users` |
| `email` | text | User's email address |
| `name` | text | Display name |
| `ai_data_sharing_enabled` | boolean | User consent for AI features (default: true) |
| `ai_preferences_updated_at` | timestamptz | When AI preferences were last updated |
| `created_at` | timestamptz | Account creation timestamp |
| `updated_at` | timestamptz | Last profile update |

**Used By:**
- Settings pages for profile management (`/settings/ai-data-sharing`)
- Family member displays
- Activity feed attribution
- AI consent checks in edge functions

---

### `families`
Family groups for multi-caregiver coordination.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid (PK) | Unique family identifier |
| `name` | text | Family name (e.g., "Smith Family") |
| `created_at` | timestamptz | Family creation timestamp |
| `updated_at` | timestamptz | Last update timestamp |

**Used By:**
- Multi-caregiver features
- Data isolation and RLS policies
- Family member management

---

### `family_members`
Links users to families with role-based access.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid (PK) | Unique membership record |
| `family_id` | uuid (FK) | References `families.id` |
| `user_id` | uuid (FK) | References `auth.users.id` |
| `role` | text | 'admin' or 'member' |
| `created_at` | timestamptz | When user joined family |

**Used By:**
- Authorization checks (RLS policies)
- Caregiver management screens
- Activity feed user lookups

---

### `babies`
Baby profiles within a family.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid (PK) | Unique baby identifier |
| `family_id` | uuid (FK) | References `families.id` |
| `name` | text | Baby's name |
| `date_of_birth` | date | Birth date for age calculations |
| `due_date` | date | Expected due date (optional) |
| `sex` | text | 'm', 'f', or 'other' |
| `timezone` | text | Baby's timezone (default 'UTC') |
| `primary_feeding_style` | text | 'breast', 'bottle', or 'both' |
| `created_at` | timestamptz | Profile creation timestamp |
| `updated_at` | timestamptz | Last update timestamp |

**Used By:**
- **Home/Dashboard**: Display selected baby, switch babies
- **All logging screens**: Associate events with baby
- **Nap Predictor**: Age-based wake window calculations
- **Growth Tracker**: Age-based percentile charts
- **AI Assistant**: Context for personalized advice
- **Settings**: Baby profile management

---

### `events`
All baby care events (feeds, diapers, sleep, tummy time).

| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid (PK) | Unique event identifier |
| `family_id` | uuid (FK) | References `families.id` |
| `baby_id` | uuid (FK) | References `babies.id` |
| `type` | text | 'feed', 'diaper', 'sleep', 'tummy_time', 'medication', 'other' |
| `subtype` | text | Specific variant (e.g., 'breast', 'wet') |
| `start_time` | timestamptz | Event start time |
| `end_time` | timestamptz | Event end time (optional) |
| `amount` | decimal | Quantity (ml for feeds, duration for sleep) |
| `unit` | text | Display unit ('ml', 'oz', 'min', 'hr') |
| `note` | text | Optional notes |
| `created_by` | uuid (FK) | User who logged the event |
| `created_at` | timestamptz | When event was logged |
| `updated_at` | timestamptz | Last modification timestamp |

**Note**: Duration is calculated from `start_time` and `end_time` in the application layer. The `amount` field stores feed quantities or sleep durations.

**Used By:**
- **Home/Dashboard**: Timeline, last feed/diaper display, summary chips
- **History**: Day-by-day event list with filtering
- **Feed/Diaper/Sleep Forms**: Create and edit events
- **Nap Predictor**: Analyze sleep patterns for predictions
- **Analytics**: Charts for feeding frequency, sleep duration
- **AI Assistant**: Context for answering questions
- **Export Features**: PDF/CSV reports

---

### `nap_feedback`
User feedback on nap prediction accuracy.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid (PK) | Unique feedback record |
| `baby_id` | uuid (FK) | References `babies.id` |
| `predicted_start` | timestamptz | Predicted nap start time |
| `predicted_end` | timestamptz | Predicted nap end time |
| `rating` | text | 'too_early', 'just_right', 'too_late' |
| `created_at` | timestamptz | Feedback submission time |

**Used By:**
- **Nap Predictor**: Collect user feedback on predictions
- **Analytics** (future): Improve prediction algorithms

---

### `predictions`
AI-generated predictions for baby events.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid (PK) | Unique prediction record |
| `baby_id` | uuid (FK) | References `babies.id` |
| `prediction_type` | text | 'next_feed', 'next_nap', etc. |
| `prediction_data` | jsonb | Prediction details (times, confidence) |
| `confidence_score` | numeric | Confidence percentage (0-100) |
| `predicted_at` | timestamptz | When prediction was generated |
| `actual_outcome` | jsonb | Actual event data (for accuracy tracking) |
| `was_accurate` | boolean | Whether prediction was correct |
| `model_version` | text | Version of prediction model used |
| `created_at` | timestamptz | Record creation timestamp |

**Used By:**
- **Nap Predictor**: Display next nap window
- **Predictions page**: Historical predictions and accuracy
- **AI system** (future): Model training and improvement

---

### `ai_conversations`
AI assistant chat conversation threads.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid (PK) | Unique conversation identifier |
| `user_id` | uuid (FK) | References `auth.users.id` |
| `family_id` | uuid (FK) | References `families.id` |
| `baby_id` | uuid (FK) | References `babies.id` (optional) |
| `title` | text | Conversation title (optional) |
| `created_at` | timestamptz | Conversation start time |
| `updated_at` | timestamptz | Last message timestamp |

**Used By:**
- **AI Assistant**: Organize chat history
- **AI Assistant**: Maintain conversation context

---

### `ai_messages`
Individual messages within AI conversations.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid (PK) | Unique message identifier |
| `conversation_id` | uuid (FK) | References `ai_conversations.id` |
| `role` | text | 'user' or 'assistant' |
| `content` | text | Message text |
| `metadata` | jsonb | Additional data (tokens, model used) |
| `created_at` | timestamptz | Message timestamp |

**Used By:**
- **AI Assistant**: Display chat history
- **AI Assistant**: Provide context for follow-up questions

---

## Extended Tables (Phase 2+)

### `growth_records`
Weight, length, and head circumference tracking.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid (PK) | Unique record identifier |
| `baby_id` | uuid (FK) | References `babies.id` |
| `recorded_at` | date | Measurement date |
| `weight` | numeric | Weight value |
| `length` | numeric | Length/height value |
| `head_circumference` | numeric | Head circumference value |
| `unit_system` | text | 'metric' or 'imperial' |
| `percentile_weight` | integer | Weight percentile (0-100) |
| `percentile_length` | integer | Length percentile (0-100) |
| `percentile_head` | integer | Head circumference percentile |
| `note` | text | Optional notes |
| `recorded_by` | uuid (FK) | User who recorded measurement |
| `created_at` | timestamptz | Record creation timestamp |

**Used By:**
- **Growth Tracker**: Display growth charts with WHO percentiles
- **Analytics**: Growth trends over time

---

### `health_records`
Vaccines, illnesses, doctor visits, and medications.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid (PK) | Unique record identifier |
| `baby_id` | uuid (FK) | References `babies.id` |
| `record_type` | text | 'vaccine', 'illness', 'checkup', 'medication' |
| `title` | text | Record title |
| `recorded_at` | timestamptz | Event date/time |
| `vaccine_name` | text | Vaccine name (if type=vaccine) |
| `vaccine_dose` | text | Dose number (e.g., "1st dose") |
| `diagnosis` | text | Illness diagnosis |
| `treatment` | text | Treatment or medication |
| `doctor_name` | text | Healthcare provider name |
| `temperature` | numeric | Body temperature (if recorded) |
| `note` | text | Additional notes |
| `created_by` | uuid (FK) | User who created record |
| `created_at` | timestamptz | Record creation timestamp |

**Used By:**
- **Health Records**: View vaccine schedule, illness history
- **Vaccine Schedule**: Track required and completed vaccines

---

### `milestones`
Developmental milestone tracking.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid (PK) | Unique milestone identifier |
| `baby_id` | uuid (FK) | References `babies.id` |
| `category` | text | 'motor', 'cognitive', 'social', 'language' |
| `title` | text | Milestone title (e.g., "First smile") |
| `description` | text | Detailed description |
| `expected_age_months` | integer | Typical age for milestone |
| `achieved_at` | date | Date baby achieved it |
| `photo_url` | text | Associated photo (optional) |
| `note` | text | Parent notes |
| `created_by` | uuid (FK) | User who logged milestone |
| `created_at` | timestamptz | Record creation timestamp |

**Used By:**
- **Milestones**: Track developmental progress
- **Photo Gallery**: Link milestone photos

---

### `journal_entries`
Daily journal entries with photos and memories.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid (PK) | Unique entry identifier |
| `baby_id` | uuid (FK) | References `babies.id` |
| `entry_date` | date | Journal entry date |
| `title` | text | Entry title (optional) |
| `content` | text | Journal text |
| `mood` | text | Baby's mood (e.g., 'happy', 'fussy') |
| `weather` | text | Weather conditions |
| `activities` | text[] | Array of activities |
| `firsts` | text[] | Array of "first" moments |
| `funny_moments` | text[] | Array of funny moments |
| `media_ids` | jsonb | Associated photo/video IDs |
| `is_published` | boolean | Whether entry is finalized |
| `created_by` | uuid (FK) | User who created entry |
| `created_at` | timestamptz | Entry creation timestamp |
| `updated_at` | timestamptz | Last update timestamp |

**Used By:**
- **Journal**: Daily memory logging
- **Photo Gallery**: Link journal photos
- **Monthly Recaps**: Source content for video recaps

---

### `cry_logs`
Cry tracking with AI categorization (prototype).

| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid (PK) | Unique log identifier |
| `family_id` | uuid (FK) | References `families.id` |
| `baby_id` | uuid (FK) | References `babies.id` |
| `start_time` | timestamptz | Cry start time |
| `end_time` | timestamptz | Cry end time (optional) |
| `cry_type` | text | AI-detected type ('hungry', 'tired', etc.) |
| `confidence` | numeric | AI confidence score |
| `resolved_by` | text | How cry was resolved |
| `note` | text | Parent notes |
| `context` | jsonb | Situational context |
| `created_by` | uuid (FK) | User who logged cry |
| `created_at` | timestamptz | Log creation timestamp |
| `updated_at` | timestamptz | Last update timestamp |

**Used By:**
- **Cry Insights**: Pattern analysis dashboard
- **AI Assistant**: Context for cry-related questions

---

### `cry_insight_sessions`
AI cry analysis sessions (prototype).

| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid (PK) | Unique session identifier |
| `baby_id` | uuid (FK) | References `babies.id` |
| `category` | text | Detected cry category |
| `confidence` | numeric | AI confidence percentage |
| `created_by` | uuid (FK) | User who initiated session |
| `created_at` | timestamptz | Session timestamp |

**Used By:**
- **Cry Recorder**: Display AI analysis results
- **Cry Insights**: Historical analysis

---

### `parent_wellness_logs`
Parent mood and water intake tracking.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid (PK) | Unique log identifier |
| `user_id` | uuid (FK) | References `auth.users.id` |
| `log_date` | date | Log date |
| `mood` | text | Parent mood ('great', 'good', 'okay', 'tired', 'struggling') |
| `sleep_quality` | text | Sleep quality rating |
| `water_intake_ml` | integer | Water consumed in ml |
| `note` | text | Optional notes |
| `created_at` | timestamptz | Log creation timestamp |
| `updated_at` | timestamptz | Last update timestamp |

**Used By:**
- **Parent Wellness**: Track parent health and mood
- **Water Intake Tracker**: Daily hydration goals

---

### `parent_medications`
Parent medication tracking (postpartum, chronic conditions).

| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid (PK) | Unique medication identifier |
| `user_id` | uuid (FK) | References `auth.users.id` |
| `medication_name` | text | Medication name |
| `dosage` | text | Dosage information |
| `frequency` | text | How often taken |
| `start_date` | date | Medication start date |
| `end_date` | date | Medication end date (optional) |
| `is_active` | boolean | Whether currently taking |
| `note` | text | Additional notes |
| `created_at` | timestamptz | Record creation timestamp |
| `updated_at` | timestamptz | Last update timestamp |

**Used By:**
- **Parent Wellness**: Medication reminders and tracking

---

### `caregiver_invites`
Pending family member invitations.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid (PK) | Unique invite identifier |
| `family_id` | uuid (FK) | References `families.id` |
| `email` | text | Invitee email address |
| `role` | text | Role to assign ('admin', 'member', or 'viewer') |
| `token` | uuid | Unique invite token |
| `status` | text | 'pending', 'accepted', 'expired' |
| `invited_by` | uuid (FK) | User who sent invite |
| `expires_at` | timestamptz | Invite expiration time |
| `created_at` | timestamptz | Invite creation timestamp |
| `updated_at` | timestamptz | Last status update |

**Used By:**
- **Caregiver Management** (`/settings/caregivers`): Send and manage family invites
- **Accept Invite** (`/accept-invite/:token`): Process invite acceptance

---

### `activity_feed`
Activity log for family coordination.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid (PK) | Unique activity identifier |
| `family_id` | uuid (FK) | References `families.id` |
| `actor_id` | uuid (FK) | User who performed action |
| `action_type` | text | Type of action (e.g., 'logged_feed') |
| `entity_type` | text | Type of entity affected |
| `entity_id` | uuid | ID of affected entity |
| `summary` | text | Human-readable summary |
| `metadata` | jsonb | Additional action data |
| `created_at` | timestamptz | Activity timestamp |

**Used By:**
- **Activity Feed** (future): Show family activity timeline

---

### `subscriptions`
User subscription and billing information.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid (PK) | Unique subscription identifier |
| `user_id` | uuid (FK) | References `auth.users.id` (unique) |
| `stripe_customer_id` | text | Stripe customer ID (unique) |
| `stripe_subscription_id` | text | Stripe subscription ID (unique, nullable) |
| `stripe_price_id` | text | Stripe price ID |
| `status` | text | Subscription status (default: 'trialing') |
| `current_period_start` | timestamptz | Current billing period start |
| `current_period_end` | timestamptz | Current billing period end |
| `cancel_at_period_end` | boolean | Whether subscription cancels at period end |
| `created_at` | timestamptz | Subscription creation timestamp |
| `updated_at` | timestamptz | Last update timestamp |

**Used By:**
- Trial and subscription management
- Feature gating (premium features)

### `app_settings`
User application preferences.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid (PK) | Unique setting identifier |
| `user_id` | uuid (FK) | References `auth.users.id` |
| `key` | text | Setting key |
| `value` | jsonb | Setting value |
| `created_at` | timestamptz | Setting creation timestamp |
| `updated_at` | timestamptz | Last update timestamp |

**Used By:**
- User preferences storage
- Feature flags

### `user_feedback`
User feedback and feature requests.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid (PK) | Unique feedback identifier |
| `user_id` | uuid (FK) | References `auth.users.id` |
| `feedback_type` | text | Type of feedback |
| `content` | text | Feedback content |
| `rating` | integer | Rating (1-5) |
| `created_at` | timestamptz | Feedback submission timestamp |

**Used By:**
- Feedback form (`/feedback`)
- Feature improvement tracking

## Relationships Summary

```
families
  ├── family_members (many) → auth.users
  ├── caregiver_invites (many)
  └── babies (many)
       ├── events (many)
       ├── nap_feedback (many)
       ├── predictions (many)
       ├── ai_conversations (many)
       ├── growth_records (many)
       ├── health_records (many)
       ├── milestones (many)
       ├── journal_entries (many)
       ├── cry_logs (many)
       ├── cry_insight_sessions (many)
       ├── sleep_training_sessions (many)
       ├── wake_windows (many)
       └── behavior_patterns (many)

auth.users
  ├── profiles (one)
  ├── subscriptions (one)
  ├── app_settings (many)
  ├── user_feedback (many)
  ├── parent_wellness_logs (many)
  └── parent_medications (many)
```

## RLS Security Model

All tables use Row Level Security (RLS) to enforce data isolation:

1. **User can only access data for families they belong to**
2. **Family admins have elevated privileges** (delete, manage invites)
3. **All writes require authentication**
4. **Reads are scoped to family membership**

See individual table policies in the Supabase dashboard or migration files.
