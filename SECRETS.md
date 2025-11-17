# 🔐 Secrets Management

## Required Secrets

### 1. LOVABLE_API_KEY
**Used by:** All edge functions for AI capabilities (Gemini, GPT)  
**Where to get:** This is a Lovable platform secret, automatically provided  
**Migration note:** For production outside Lovable, you'll need to:
- Replace with direct OpenAI/Google AI API keys
- OR use a custom AI proxy/gateway
- Update all edge functions to use new keys

### 2. Supabase Environment Variables
Already in `.env` file - these work anywhere:
- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_PUBLISHABLE_KEY`
- `VITE_SUPABASE_PROJECT_ID`

### 3. Edge Function Secrets (for production)
When deploying edge functions outside Lovable:
```bash
# Set in Supabase dashboard or CLI
supabase secrets set OPENAI_API_KEY=sk-...
supabase secrets set GOOGLE_AI_API_KEY=...
```

## Development vs Production

**In Lovable (current):**
- `LOVABLE_API_KEY` works automatically
- No additional setup needed

**In Cursor + Local Dev:**
- Edge functions still call Lovable AI API (works)
- For production deployment, replace with your own keys

**In Production (self-hosted):**
- Must provide your own AI provider keys
- Update edge functions to use direct APIs

## Security Best Practices
- Never commit `.env` file to git
- Use Supabase secrets manager for edge function keys
- Rotate keys regularly
- Use different keys for development/production
