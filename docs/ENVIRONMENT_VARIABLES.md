# Environment Variables & Secrets Management

## Overview

This document describes all environment variables used in the Nuzzle application and how to manage them securely.

## 🔐 Security Best Practices

1. **Never commit `.env` files to git** - They are in `.gitignore`
2. **Use different values for dev/staging/production**
3. **Rotate secrets regularly**
4. **Use Supabase secrets manager for edge functions**
5. **Use GitHub Secrets for CI/CD**

## Web Application Variables

### Required for Development

Create a `.env` file in the project root:

```bash
# Supabase Configuration
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=your-anon-key-here
VITE_SUPABASE_PROJECT_ID=your-project-id

# Sentry (Optional - for error tracking)
VITE_SENTRY_DSN=https://your-sentry-dsn@sentry.io/project-id

# App Version
VITE_APP_VERSION=1.0.0

# Firebase (Optional - if using Firebase features)
VITE_FIREBASE_API_KEY=your-firebase-api-key
VITE_FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=your-firebase-project-id
VITE_FIREBASE_STORAGE_BUCKET=your-project.appspot.com
VITE_FIREBASE_MESSAGING_SENDER_ID=your-sender-id
VITE_FIREBASE_APP_ID=your-app-id
VITE_FIREBASE_MEASUREMENT_ID=your-measurement-id
```

### Production Environment Variables

For production deployments (Vercel, Netlify, etc.):

1. **Vercel**: Project Settings → Environment Variables
2. **Netlify**: Site Settings → Environment Variables
3. **Other platforms**: Use their respective secret management

**Required for Production:**
- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_PUBLISHABLE_KEY`
- `VITE_SUPABASE_PROJECT_ID`
- `VITE_APP_VERSION`

**Optional:**
- `VITE_SENTRY_DSN` (recommended for production)
- Firebase variables (if using Firebase)

## Supabase Edge Functions

Edge functions use environment variables set in Supabase:

### Setting Secrets

```bash
# Using Supabase CLI
supabase secrets set LOVABLE_API_KEY=your-api-key
supabase secrets set OPENAI_API_KEY=sk-...
supabase secrets set GOOGLE_AI_API_KEY=...

# Or via Supabase Dashboard
# Project Settings → Edge Functions → Secrets
```

### Edge Function Environment Variables

| Variable | Purpose | Required | Notes |
|----------|---------|-----------|-------|
| `SUPABASE_URL` | Supabase project URL | Yes | Auto-provided by Supabase |
| `SUPABASE_ANON_KEY` | Supabase anonymous key | Yes | Auto-provided by Supabase |
| `SUPABASE_SERVICE_ROLE_KEY` | Service role key | Yes | Auto-provided by Supabase |
| `LOVABLE_API_KEY` | Lovable AI API key | Yes* | For AI features via Lovable |
| `OPENAI_API_KEY` | OpenAI API key | No | Alternative to Lovable API |
| `GOOGLE_AI_API_KEY` | Google AI API key | No | Alternative to Lovable API |

\* Required if using Lovable AI features. For production, replace with direct API keys.

## iOS Application

### Configuration Files

iOS app uses:
- `Info.plist` for app configuration
- Xcode build settings for environment-specific values
- No `.env` file (use Xcode build configurations)

### iOS Environment Variables

Set in Xcode → Target → Build Settings:

- **Bundle Identifier**: `com.nestling.Nestling` (preserved for App Store continuity)
- **Version**: `1.0` (CFBundleShortVersionString)
- **Build**: `1` (CFBundleVersion)
- **Display Name**: `Nuzzle`

### Supabase Configuration (iOS)

Supabase credentials are configured in:
- `ios/Nuzzle/Nestling/Services/SupabaseClient.swift`

**⚠️ Important**: Never hardcode API keys in Swift files. Use:
- Xcode build configurations
- Info.plist (for non-sensitive config)
- Keychain (for sensitive data)

## CI/CD Environment Variables

### GitHub Actions Secrets

Set in: Repository Settings → Secrets and variables → Actions

**Required Secrets:**
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `SUPABASE_ACCESS_TOKEN` (for Supabase CLI)

**Optional:**
- `SENTRY_AUTH_TOKEN` (for Sentry releases)
- `APP_STORE_CONNECT_API_KEY` (for iOS deployment)
- `APP_STORE_CONNECT_ISSUER_ID` (for iOS deployment)

### CI/CD Workflow Variables

Set in: Repository Settings → Secrets and variables → Actions → Variables

- `NODE_VERSION`: `20` (for Node.js setup)
- `XCODE_VERSION`: `15.0` (for iOS builds)

## Environment-Specific Configurations

### Development

```bash
# .env.local (gitignored)
VITE_SUPABASE_URL=http://localhost:54321  # Local Supabase
VITE_SUPABASE_PUBLISHABLE_KEY=local-anon-key
```

### Staging

```bash
# Use staging Supabase project
VITE_SUPABASE_URL=https://staging-project.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=staging-anon-key
```

### Production

```bash
# Use production Supabase project
VITE_SUPABASE_URL=https://production-project.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=production-anon-key
```

## Verification

### Check Environment Variables

**Web:**
```bash
# Check if variables are loaded
npm run dev
# Open browser console, check for errors
```

**Supabase Edge Functions:**
```bash
# List secrets
supabase secrets list

# Test edge function
supabase functions invoke function-name
```

**iOS:**
```bash
# Check build settings
cd ios/Nuzzle
xcodebuild -showBuildSettings | grep SUPABASE
```

## Migration from Lovable

If migrating from Lovable platform:

1. **Replace `LOVABLE_API_KEY`** with direct API keys:
   - `OPENAI_API_KEY` for OpenAI features
   - `GOOGLE_AI_API_KEY` for Google AI features

2. **Update edge functions** to use new keys:
   ```typescript
   // Old
   const LOVABLE_API_KEY = Deno.env.get("LOVABLE_API_KEY");
   
   // New
   const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");
   ```

3. **Update client code** if any hardcoded URLs exist

## Troubleshooting

### "Environment variable not found"

1. Check `.env` file exists in project root
2. Verify variable name matches exactly (case-sensitive)
3. Restart dev server after adding variables
4. Check for typos in variable names

### "Supabase connection failed"

1. Verify `VITE_SUPABASE_URL` is correct
2. Check `VITE_SUPABASE_PUBLISHABLE_KEY` is valid
3. Ensure Supabase project is active
4. Check network connectivity

### Edge function secrets not working

1. Verify secrets are set: `supabase secrets list`
2. Check secret names match code exactly
3. Redeploy edge function after setting secrets
4. Check Supabase dashboard → Edge Functions → Secrets

## Security Checklist

- [ ] `.env` files are in `.gitignore`
- [ ] No API keys in source code
- [ ] Different keys for dev/staging/production
- [ ] Supabase secrets configured for edge functions
- [ ] GitHub Secrets configured for CI/CD
- [ ] Production keys are rotated regularly
- [ ] Service role key is never exposed to client

## Additional Resources

- [Supabase Environment Variables](https://supabase.com/docs/guides/functions/secrets)
- [Vite Environment Variables](https://vitejs.dev/guide/env-and-mode.html)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)









