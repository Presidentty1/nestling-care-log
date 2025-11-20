# 🚀 Deployment Guide

## Architecture Overview
- **Frontend:** React SPA (Vite build)
- **Backend:** Supabase (Lovable Cloud)
- **Edge Functions:** Deno runtime on Supabase
- **Database:** PostgreSQL (Supabase)
- **Storage:** Supabase Storage (for future features)

## Current Deployment (Lovable Platform)
1. Push to GitHub (auto-deploys)
2. Click "Publish" in Lovable editor
3. Access at: `https://lovable.app/your-subdomain`

## Deploying Outside Lovable

### Option 1: Vercel (Recommended for Web)
```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel

# Set environment variables in Vercel dashboard
VITE_SUPABASE_URL=...
VITE_SUPABASE_PUBLISHABLE_KEY=...
VITE_SUPABASE_PROJECT_ID=...
```

**Vercel Configuration:**
- Build command: `npm run build`
- Output directory: `dist`
- Node version: 18+

### Option 2: Netlify
```bash
# Install Netlify CLI
npm i -g netlify-cli

# Deploy
netlify deploy --prod

# Build settings:
# Build command: npm run build
# Publish directory: dist
```

### Option 3: iOS App Store
```bash
# 1. Build production bundle
npm run build

# 2. Sync to iOS
npx cap sync ios

# 3. Open Xcode
npx cap open ios

# 4. In Xcode:
# - Set signing certificate
# - Update version/build number
# - Archive for distribution
# - Upload to App Store Connect
```

**iOS Requirements:**
- Apple Developer account ($99/year)
- Valid signing certificate
- App icons (1024x1024 PNG)
- Privacy policy URL
- App Store screenshots

### Edge Functions Deployment
Edge functions are automatically deployed by Lovable.  
For manual deployment:
```bash
# Install Supabase CLI
brew install supabase/tap/supabase

# Login
supabase login

# Link project
supabase link --project-ref your-project-id

# Deploy all functions
supabase functions deploy

# Deploy specific function
supabase functions deploy ai-assistant
```

## Environment Variables

### Required for All Deployments
```env
VITE_SUPABASE_URL=https://your-project-id.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=your-supabase-anon-key
VITE_SUPABASE_PROJECT_ID=your-project-id
```

### Edge Function Secrets (Production)
```bash
# Set via Supabase CLI
supabase secrets set LOVABLE_API_KEY=your_key
# OR replace with:
supabase secrets set OPENAI_API_KEY=sk-...
```

## CI/CD Setup (GitHub Actions)

Create `.github/workflows/deploy.yml`:
```yaml
name: Deploy
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: 18
      - run: npm install
      - run: npm run build
      - run: npm run test
      # Add deployment step (Vercel/Netlify)
```

## Monitoring & Analytics
- **Error Tracking:** Sentry.io
- **Performance:** Vercel Analytics or Google Analytics
- **Uptime:** UptimeRobot or Better Uptime

## Cost Estimates (Monthly)

### Free Tier (Hobby)
- Frontend: Vercel/Netlify free tier
- Backend: Supabase free (50k MAU)
- Total: $0

### Production (Paid)
- Frontend: $20 (Vercel Pro)
- Backend: $25 (Supabase Pro)
- AI APIs: $10-50 (usage-based)
- Apple Developer: $99/year
- **Total: ~$60-100/month**
