# AI Features Documentation

## Overview

All AI features use Google Gemini via Lovable AI gateway. No direct API keys required from users.

## Consent & Privacy

### User Control

- Users must enable "AI Data Sharing" in Settings → AI & Data Sharing
- Edge functions check consent before processing any AI requests
- Users can disable AI features at any time without losing their event data

### Data Sharing

When AI features are enabled, the following data is sent to Google Gemini:

- Baby age and profile information (name, date of birth)
- Recent event history (last 7 days of feeds, sleep, diapers)
- Optional audio recordings for cry analysis (only when user initiates recording)
- User questions to the AI Assistant

### Data Retention

- Data is processed in real-time by Google Gemini
- We do not store user data on AI provider servers
- Audio recordings for cry analysis are not persisted after analysis
- All data transmission is encrypted via HTTPS

### Privacy Compliance

- GDPR compliant: Users have full control over AI data sharing
- CCPA compliant: Users can export or delete all data
- App Store compliant: Clear consent mechanism with detailed explanations

## Platform-Specific Implementation

### iOS Implementation

**AI Assistant:**

- Uses Supabase Swift SDK for authentication
- Session tokens extracted from Supabase sessions
- Edge function calls authenticated with user tokens
- Falls back to local-only mode if authentication fails

**Cry Analysis:**

- On-device analysis using `MLCryClassifier` (rule-based)
- No edge function calls required
- Audio processed locally and immediately deleted
- Works offline

**Authentication Flow:**

- Supabase client initialized on app launch
- Session management with automatic token refresh
- AI features require authenticated users with consent enabled

## Features

### 1. Smart Predictions

**Purpose**: Predict next feeding time and nap windows based on patterns

**Input Data**:

- Baby age (in weeks/months)
- Last 7 days of feeding events
- Last 7 days of sleep events
- Current time of day

**AI Model**: Gemini 2.5 Flash (fast, cost-effective for pattern recognition)

**Output**:

- Predicted next feeding time with confidence score (0-1)
- Predicted nap window with suggested start/end times
- Confidence indicator (High/Medium/Low)

**Accuracy**:

- Improves with more data points
- Most accurate after 2+ weeks of consistent logging
- Confidence score indicates reliability

**Implementation**:

- Edge function: `generate-predictions`
- Query: `predictions` table for history
- UI: `src/pages/Predictions.tsx`

### 2. Cry Insights (Prototype)

**Purpose**: Analyze crying context to suggest likely causes

**Input Data**:

- Time since last feeding
- Time since last sleep
- Current time of day
- Duration of crying (from timer or user input)
- Optional: Brief audio snippet metadata (not the actual audio, just duration/intensity markers)

**AI Model**: Gemini 2.5 Flash

**Output**:

- Likely causes ranked by probability:
  - Hungry (needs feeding)
  - Tired (needs sleep)
  - Discomfort (diaper change, temperature)
  - Pain (medical attention may be needed)
  - Overstimulation (needs calm environment)
- Brief suggestion for each cause
- Confidence score for top prediction

**Disclaimer**: Always shown - this is not medical diagnosis

**Implementation**:

- Edge function: `analyze-cry-pattern`
- UI: `src/pages/CryInsights.tsx`
- Component: `src/components/CryTimer.tsx`, `src/components/CryRecorder.tsx`

### 3. AI Assistant

**Purpose**: Answer parenting questions in a conversational manner

**Input Data**:

- User question
- Baby age (for age-appropriate advice)
- Context: Recent events summary (optional, only if relevant to question)

**AI Model**: Gemini 2.5 Pro (better for complex reasoning and nuanced advice)

**Output**:

- Conversational response
- Follows these guidelines:
  - Always include medical disclaimers for health-related questions
  - Recommend consulting pediatrician for concerning symptoms
  - Use parent-friendly language, avoid medical jargon
  - Provide actionable, specific advice when possible
  - Include reassurance and empathy

**Example Questions**:

- "How often should a 3-month-old eat?"
- "Is it normal for my baby to wake up every 2 hours?"
- "What should I do if my baby has a fever?"
- "How can I help my baby sleep longer stretches?"

**System Prompt** (configured in edge function):

```
You are a helpful parenting assistant for new parents. Provide supportive,
evidence-based advice while always recommending they consult their pediatrician
for medical concerns. Be warm, reassuring, and concise. Never diagnose conditions.
```

**Implementation**:

- Edge function: `ai-assistant`
- Hook: `src/hooks/useAIChat.ts`
- UI: `src/pages/AIAssistant.tsx`

## Edge Function Guard Implementation

All AI edge functions check user consent before processing:

```typescript
// Example from generate-predictions/index.ts
const { data: profile, error: profileError } = await supabase
  .from('profiles')
  .select('ai_data_sharing_enabled')
  .eq('id', userId)
  .single();

if (!profile?.ai_data_sharing_enabled) {
  return new Response(
    JSON.stringify({
      error:
        'AI features are disabled. Enable in Settings → AI & Data Sharing.',
    }),
    { status: 403, headers: { 'Content-Type': 'application/json' } }
  );
}
```

## UI Disabled States

When AI data sharing is disabled:

### Smart Predictions Page

- "Generate Prediction" buttons are disabled
- Inline message: "AI predictions are disabled. Enable in Settings → AI & Data Sharing to use this feature."
- Link to settings page

### Cry Insights Page

- "Analyze Cry" button is disabled
- Inline message: "Cry analysis is disabled. Enable AI features in Settings to analyze patterns."
- Timer still works for tracking cry duration

### AI Assistant Page

- Chat input is disabled
- Banner above input: "AI Assistant is disabled. Enable AI features in Settings → AI & Data Sharing."
- Previous conversation history remains visible (if any)

## Testing

### Manual Testing

1. Disable AI in Settings → AI & Data Sharing
2. Navigate to each AI feature page
3. Verify disabled state UI is shown
4. Try to trigger AI action (should fail gracefully)
5. Re-enable AI in Settings
6. Verify features work normally

### Edge Function Testing

Test edge functions locally:

```bash
supabase functions serve generate-predictions --no-verify-jwt
```

Test with curl:

```bash
curl -X POST http://localhost:54321/functions/v1/generate-predictions \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -d '{"babyId": "test-baby-id", "predictionType": "feeding"}'
```

## Future Enhancements

### Phase 2+ Ideas (Not MVP)

- Sleep training AI coach with progressive plans
- Personalized growth milestone predictions
- Automatic anomaly detection (unusual patterns)
- Voice-to-log with AI parsing (currently uses basic pattern matching)
- Photo-based diaper rash assessment (requires image analysis)
- Nutrition recommendations based on feeding patterns

### Model Considerations

- Gemini 2.5 Flash is optimal for speed + cost for current features
- Gemini 2.5 Pro for AI Assistant provides better conversational quality
- Future: Fine-tune models on anonymized baby data for better predictions

## Cost Management

Using Lovable AI gateway:

- No direct API keys needed
- Lovable handles rate limiting and usage monitoring
- Cost-effective for MVP scale
- Scales automatically with user growth

## Troubleshooting

### Common Issues

**"AI features are disabled" error**

- User needs to enable AI Data Sharing in Settings
- Check `profiles.ai_data_sharing_enabled` in database

**Edge function timeout**

- Gemini API may be slow during peak times
- Implement client-side timeout (30s) and retry logic
- Show "Taking longer than usual..." message after 10s

**Poor prediction accuracy**

- Needs more data points (minimum 3-5 days of consistent logging)
- Irregular schedules reduce accuracy
- Show confidence score to manage expectations

**AI Assistant gives generic responses**

- Ensure baby age is included in context
- Consider adding more recent events to context
- System prompt may need refinement

## Support Resources

- Lovable AI Models: [Internal docs]
- Google Gemini API: https://ai.google.dev/docs
- Privacy compliance: See `PRIVACY.md`
- User support: Guide users to Settings → Feedback
