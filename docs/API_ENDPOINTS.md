# API Endpoints Documentation

Complete reference for all Supabase Edge Functions and their contracts.

## Base Configuration

**Supabase Project URL:** `https://your-project-id.supabase.co`  
**Functions Base URL:** `https://your-project-id.supabase.co/functions/v1`

All requests require:
```typescript
headers: {
  'Authorization': `Bearer ${supabaseAnonKey}`,
  'Content-Type': 'application/json'
}
```

---

## Authentication & User Management

### bootstrap-user
**File:** `supabase/functions/bootstrap-user/index.ts`
**Method:** `POST`
**Purpose:** Initialize new user with family and default baby
**Triggered:** Automatically after signup via database trigger

**Request Body:**
```typescript
{
  userId: string;      // UUID of newly created user
  email: string;       // User's email
  name?: string;       // Optional display name
}
```

**Response:**
```typescript
{
  success: true,
  familyId: string,
  babyId: string,
  message: "User bootstrapped successfully"
}
```

**Error Response:**
```typescript
{
  error: string,
  details?: any
}
```

---

## AI Features

### ai-assistant
**File:** `supabase/functions/ai-assistant/index.ts`
**Method:** `POST`
**Purpose:** AI Q&A for parenting questions
**Requires:** AI data sharing consent enabled

**Request Body:**
```typescript
{
  conversationId?: string;  // Optional, for continuing conversation
  babyId: string;
  message: string;          // User's question
  context?: {               // Optional context
    recentEvents?: Event[];
    babyAge?: number;
  }
}
```

**Response:**
```typescript
{
  conversationId: string,
  message: string,          // AI response
  timestamp: string,
  disclaimer: string        // Medical disclaimer
}
```

**AI Model Used:** `google/gemini-2.0-flash-exp` (Lovable AI)

**Consent Check:**
```sql
SELECT ai_data_sharing_enabled FROM profiles WHERE id = auth.uid()
```
If false, returns 403 error.

---

### generate-predictions
**File:** `supabase/functions/generate-predictions/index.ts`
**Method:** `POST`
**Purpose:** Generate smart predictions (nap windows, feeding patterns)
**Requires:** AI data sharing consent enabled

**Request Body:**
```typescript
{
  babyId: string;
  predictionType: 'nap_window' | 'feeding_pattern' | 'sleep_regression' | 'growth_spurt';
  lookbackDays?: number;    // Default: 7
}
```

**Response:**
```typescript
{
  predictionId: string,
  predictionType: string,
  confidence: number,       // 0-1
  prediction: {
    nextNapWindow?: {
      start: string,        // ISO timestamp
      end: string,
      confidence: number
    },
    feedingPattern?: {
      averageInterval: number,  // minutes
      nextFeedTime: string,
      confidence: number
    },
    insights: string[]
  },
  generatedAt: string
}
```

**AI Model Used:** `google/gemini-2.0-flash-exp` (Lovable AI)

---

### analyze-cry-pattern
**File:** `supabase/functions/analyze-cry-pattern/index.ts`
**Method:** `POST`
**Purpose:** Analyze baby cry audio
**Requires:** AI data sharing consent enabled

**Request Body:**
```typescript
{
  babyId: string;
  audioBase64?: string;     // Base64 encoded audio (optional)
  duration?: number;        // Cry duration in seconds
  context?: {
    timeSinceLastFeed?: number;
    timeSinceLastSleep?: number;
    timeSinceLastDiaper?: number;
  }
}
```

**Response:**
```typescript
{
  sessionId: string,
  category: 'hungry' | 'tired' | 'discomfort' | 'pain' | 'unknown',
  confidence: number,       // 0-1
  suggestions: string[],
  detectedAt: string
}
```

**Note:** Currently uses context-based heuristics. Audio analysis coming in future update.

---

### calculate-nap-window
**File:** `supabase/functions/calculate-nap-window/index.ts`
**Method:** `POST`
**Purpose:** Calculate next nap window based on wake windows
**Does NOT require AI consent** (rule-based calculation)

**Request Body:**
```typescript
{
  babyId: string;
  lastWakeTime?: string;    // ISO timestamp, defaults to now
}
```

**Response:**
```typescript
{
  nextNapWindow: {
    start: string,          // ISO timestamp
    end: string,
    wakeWindowMinutes: number,
    confidence: 'high' | 'medium' | 'low'
  },
  babyAgeMonths: number,
  lastSleepEvent?: Event
}
```

**Algorithm:**
- Fetches baby's date of birth
- Calculates age in months
- Uses age-appropriate wake windows:
  - 0-1 months: 45-60 min
  - 1-2 months: 60-90 min
  - 2-3 months: 75-90 min
  - 3-6 months: 90-120 min
  - 6-9 months: 2-3 hours
  - 9-12 months: 2.5-3.5 hours
  - 12+ months: 3-5 hours

---

## Analytics & Patterns

### analyze-sleep-patterns
**File:** `supabase/functions/analyze-sleep-patterns/index.ts`
**Method:** `POST`
**Purpose:** Analyze sleep quality and patterns

**Request Body:**
```typescript
{
  babyId: string;
  startDate: string;        // ISO date (YYYY-MM-DD)
  endDate: string;
}
```

**Response:**
```typescript
{
  totalSleepHours: number,
  averageNapDuration: number,     // minutes
  longestSleep: number,           // minutes
  nightWakings: number,
  sleepQuality: 'excellent' | 'good' | 'fair' | 'poor',
  patterns: {
    consistentBedtime: boolean,
    regularNaps: boolean,
    sleepRegressionDetected: boolean
  },
  recommendations: string[]
}
```

---

### detect-anomalies
**File:** `supabase/functions/detect-anomalies/index.ts`
**Method:** `POST`
**Purpose:** Detect unusual patterns in baby data

**Request Body:**
```typescript
{
  babyId: string;
  checkTypes: Array<'feeding' | 'sleep' | 'diaper' | 'growth'>;
}
```

**Response:**
```typescript
{
  anomalies: Array<{
    type: string,
    severity: 'low' | 'medium' | 'high',
    description: string,
    detectedAt: string,
    suggestedActions: string[]
  }>
}
```

**Anomaly Detection Rules:**
- Feeding: >6 hours between feeds (newborn)
- Sleep: <10 total hours in 24h
- Diaper: No wet diaper in 8+ hours
- Growth: Weight loss or no gain

---

## Reports & Summaries

### generate-handoff-report
**File:** `supabase/functions/generate-handoff-report/index.ts`
**Method:** `POST`
**Purpose:** Generate caregiver handoff summary

**Request Body:**
```typescript
{
  babyId: string;
  shiftStart: string;       // ISO timestamp
  shiftEnd: string;
  notes?: string;
}
```

**Response:**
```typescript
{
  reportId: string,
  summary: string,
  highlights: string[],
  concerns: string[],
  eventsSummary: {
    feeds: number,
    diapers: number,
    sleeps: number,
    totalSleepMinutes: number
  },
  generatedAt: string
}
```

---

### generate-weekly-summary
**File:** `supabase/functions/generate-weekly-summary/index.ts`
**Method:** `POST`
**Purpose:** Weekly recap email/notification

**Request Body:**
```typescript
{
  babyId: string;
  weekStartDate: string;    // ISO date (YYYY-MM-DD)
}
```

**Response:**
```typescript
{
  weekOf: string,
  totalFeeds: number,
  totalDiapers: number,
  totalSleepHours: number,
  averageSleepPerNight: number,
  milestones: Milestone[],
  topInsights: string[],
  mediaCount: number
}
```

---

### generate-monthly-recap
**File:** `supabase/functions/generate-monthly-recap/index.ts`
**Method:** `POST`
**Purpose:** Monthly highlight video/report

**Request Body:**
```typescript
{
  babyId: string;
  month: number;            // 1-12
  year: number;
}
```

**Response:**
```typescript
{
  recapId: string,
  month: number,
  year: number,
  highlights: {
    growthChange: {
      weightGain: number,
      lengthGain: number
    },
    milestones: Milestone[],
    topMoments: string[],
    photoCount: number
  },
  videoUrl?: string,        // If video generation enabled
  generatedAt: string
}
```

---

## Collaboration

### invite-caregiver
**File:** `supabase/functions/invite-caregiver/index.ts`
**Method:** `POST`
**Purpose:** Send caregiver invitation email

**Request Body:**
```typescript
{
  familyId: string;
  email: string;
  role: 'admin' | 'member' | 'viewer';
  message?: string;         // Optional personal message
}
```

**Response:**
```typescript
{
  inviteId: string,
  token: string,
  email: string,
  expiresAt: string,
  inviteUrl: string         // Deep link to accept invite
}
```

**Email Template:**
Uses Supabase Auth email templates with custom styling.

---

## Voice & Commands

### process-voice-command
**File:** `supabase/functions/process-voice-command/index.ts`
**Method:** `POST`
**Purpose:** Parse voice input into structured log

**Request Body:**
```typescript
{
  babyId: string;
  transcript: string;       // Voice-to-text result
}
```

**Response:**
```typescript
{
  success: boolean,
  parsedCommand: {
    eventType: 'feed' | 'diaper' | 'sleep' | 'tummy_time',
    details: {
      amount?: number,
      unit?: string,
      side?: string,
      type?: string,
      duration?: number
    },
    timestamp?: string
  },
  confidence: number,
  eventId?: string          // If auto-logged
}
```

**Example Commands:**
- "Log bottle feed 4 ounces"
- "Diaper change wet"
- "Start sleep timer"
- "Fed from left breast 15 minutes"

---

## Error Handling

All endpoints return errors in this format:

```typescript
{
  error: string,            // Error message
  code?: string,            // Error code (e.g., 'CONSENT_REQUIRED')
  details?: any,            // Additional error details
  timestamp: string
}
```

### Common Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `CONSENT_REQUIRED` | 403 | AI data sharing not enabled |
| `UNAUTHORIZED` | 401 | Invalid/missing auth token |
| `INVALID_INPUT` | 400 | Request validation failed |
| `NOT_FOUND` | 404 | Resource not found |
| `RATE_LIMITED` | 429 | Too many requests |
| `SERVER_ERROR` | 500 | Internal server error |

---

## Rate Limiting

AI endpoints are rate limited per user:
- **ai-assistant:** 30 requests/hour
- **generate-predictions:** 10 requests/hour
- **analyze-cry-pattern:** 20 requests/hour

Non-AI endpoints have higher limits.

---

## Testing Endpoints

Use these cURL examples for testing:

### Test AI Assistant
```bash
curl -X POST \
  https://your-project-id.supabase.co/functions/v1/ai-assistant \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "babyId": "uuid-here",
    "message": "Why is my baby crying?"
  }'
```

### Test Nap Prediction
```bash
curl -X POST \
  https://your-project-id.supabase.co/functions/v1/calculate-nap-window \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "babyId": "uuid-here"
  }'
```

---

## iOS Integration

### Swift Example

```swift
import Supabase
import Foundation

class APIService {
    let supabase = SupabaseClient.shared.client
    
    func generatePrediction(babyId: UUID) async throws -> Prediction {
        let response = try await supabase.functions
            .invoke(
                "generate-predictions",
                body: [
                    "babyId": babyId.uuidString,
                    "predictionType": "nap_window"
                ]
            )
        
        return try JSONDecoder().decode(Prediction.self, from: response.data)
    }
    
    func askAI(question: String, babyId: UUID) async throws -> AIResponse {
        let response = try await supabase.functions
            .invoke(
                "ai-assistant",
                body: [
                    "babyId": babyId.uuidString,
                    "message": question
                ]
            )
        
        return try JSONDecoder().decode(AIResponse.self, from: response.data)
    }
}
```

---

## Database Direct Access

For standard CRUD operations, use Supabase client directly:

```typescript
// Fetch events
const { data, error } = await supabase
  .from('events')
  .select('*')
  .eq('baby_id', babyId)
  .order('start_time', { ascending: false })
  .limit(50)

// Insert event
const { data, error } = await supabase
  .from('events')
  .insert({
    baby_id: babyId,
    family_id: familyId,
    type: 'feed',
    start_time: new Date().toISOString(),
    amount: 4,
    unit: 'oz'
  })
```

See `DATA_MODEL.md` for complete schema reference.
