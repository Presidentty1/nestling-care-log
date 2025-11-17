# Edge Functions Overview

All edge functions currently use `LOVABLE_API_KEY` to access AI models via Lovable AI.

## Functions List

### 1. ai-assistant
- **Purpose:** General Q&A chatbot for baby care
- **AI Model:** Gemini 2.5 Flash (via Lovable AI)
- **Migration:** Replace with OpenAI GPT-4 or Google AI direct
- **Endpoint:** `/functions/v1/ai-assistant`

### 2. analyze-cry-pattern
- **Purpose:** Interpret baby cry audio
- **AI Model:** Gemini 2.5 Pro (via Lovable AI)
- **Migration:** Replace with speech-to-text + sentiment analysis
- **Endpoint:** `/functions/v1/analyze-cry-pattern`

### 3. analyze-sleep-patterns
- **Purpose:** Detect sleep pattern anomalies
- **AI Model:** Gemini 2.5 Flash (via Lovable AI)
- **Migration:** Could be rule-based or keep AI
- **Endpoint:** `/functions/v1/analyze-sleep-patterns`

### 4. calculate-nap-window
- **Purpose:** Predict next nap time
- **AI Model:** None (pure logic)
- **Migration:** ✅ No changes needed
- **Endpoint:** `/functions/v1/calculate-nap-window`

### 5. bootstrap-user
- **Purpose:** Initialize new user profile
- **AI Model:** None
- **Migration:** ✅ No changes needed
- **Endpoint:** `/functions/v1/bootstrap-user`

### 6. detect-anomalies
- **Purpose:** Flag unusual patterns
- **AI Model:** Gemini 2.5 Flash
- **Migration:** Replace with custom logic or AI
- **Endpoint:** `/functions/v1/detect-anomalies`

### 7. generate-handoff-report
- **Purpose:** Create caregiver handoff summaries
- **AI Model:** Gemini 2.5 Flash
- **Migration:** Replace with OpenAI
- **Endpoint:** `/functions/v1/generate-handoff-report`

### 8. generate-monthly-recap
- **Purpose:** Monthly summary email
- **AI Model:** Gemini 2.5 Flash
- **Migration:** Replace with OpenAI
- **Endpoint:** `/functions/v1/generate-monthly-recap`

### 9. generate-predictions
- **Purpose:** Predict patterns
- **AI Model:** Gemini 2.5 Flash
- **Migration:** Replace with ML model or OpenAI
- **Endpoint:** `/functions/v1/generate-predictions`

### 10. generate-weekly-summary
- **Purpose:** Weekly insights
- **AI Model:** Gemini 2.5 Flash
- **Migration:** Replace with OpenAI
- **Endpoint:** `/functions/v1/generate-weekly-summary`

### 11. invite-caregiver
- **Purpose:** Send invite emails
- **AI Model:** None
- **Migration:** ✅ No changes needed
- **Endpoint:** `/functions/v1/invite-caregiver`

### 12. process-voice-command
- **Purpose:** Parse voice logs
- **AI Model:** Gemini 2.5 Flash
- **Migration:** Replace with OpenAI Whisper + GPT
- **Endpoint:** `/functions/v1/process-voice-command`

## Migration Strategy

### Option A: Keep Lovable AI (Recommended for MVP)
- Edge functions continue to work as-is
- No code changes needed
- Dependency on Lovable platform
- Cost: Included in Lovable Cloud

### Option B: Switch to OpenAI
```bash
# Set secret
supabase secrets set OPENAI_API_KEY=sk-...

# Update each function to use:
import OpenAI from "openai"
const openai = new OpenAI({ apiKey: Deno.env.get("OPENAI_API_KEY") })
```

See `_migration_template/index.ts` for example code.

### Option C: Switch to Google AI Direct
```bash
supabase secrets set GOOGLE_AI_API_KEY=...
# Use @google/generative-ai package
```

### Option D: Hybrid Approach
- Use rule-based logic where possible (`calculate-nap-window`, `bootstrap-user`)
- Reserve AI for complex tasks only
- Reduces API costs and latency

## Local Development

```bash
# Serve function locally
supabase functions serve ai-assistant --env-file .env

# Test function
curl -X POST http://localhost:54321/functions/v1/ai-assistant \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -d '{"prompt": "Test"}'

# View logs
supabase functions logs ai-assistant
```

## Deployment

```bash
# Deploy all functions
supabase functions deploy

# Deploy specific function
supabase functions deploy ai-assistant

# Check deployment status
supabase functions list
```

## Cost Estimates

### Current (Lovable AI)
- Included in Lovable Cloud subscription

### After Migration (OpenAI)
- ~$0.01 per GPT-4 request
- ~$0.001 per GPT-3.5 request
- Estimate: $20-50/month for 1000 users

### After Migration (Google AI)
- ~$0.0005 per Gemini request
- Cheaper than OpenAI
- Estimate: $10-20/month for 1000 users
