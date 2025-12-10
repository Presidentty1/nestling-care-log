# 💻 Development Setup for Cursor

## Prerequisites

- **Node.js:** v18+ (use `nvm` recommended)
- **Package Manager:** npm or bun
- **iOS Development:** macOS + Xcode 15+
- **Android Development:** Android Studio + Java 17+
- **Supabase CLI:** `brew install supabase/tap/supabase`

## First-Time Setup

### 1. Clone & Install

```bash
git clone <your-repo-url>
cd nestling-care-log
npm install
```

### 2. Environment Variables

Copy `.env.example` to `.env` and fill in values.  
**Note:** The `.env` file in the repo already has production values from Lovable Cloud.

### 3. Start Development Server

```bash
npm run dev
# Opens at http://localhost:5173
```

### 4. Run Tests

```bash
# Unit tests
npm run test

# E2E tests (requires dev server running)
npm run test:e2e

# E2E tests with UI
npm run test:e2e:ui
```

## iOS Development Workflow

### First-Time iOS Setup

```bash
# Build web assets
npm run build

# Add iOS platform (if not already added)
npx cap add ios

# Sync web assets to iOS
npx cap sync ios

# Open in Xcode
npx cap open ios
```

### Daily iOS Development

```bash
# Method 1: Hot-reload from device/simulator (RECOMMENDED)
# 1. Find your local IP: ifconfig | grep "inet " | grep -v 127.0.0.1
# 2. Edit capacitor.config.ts, uncomment server.url and set your IP
# 3. Run: npm run dev
# 4. In Xcode, run on simulator/device
# 5. App will load from your dev server with hot-reload!

# Method 2: Full rebuild (slower)
npm run cap:run:ios
```

### Viewing iOS/Xcode Logs

```bash
# Stream logs from running simulator (auto-detects)
npm run ios:logs

# Stream logs and save to file
npm run ios:logs:save

# Stream logs with custom options
./scripts/xcode-logs.sh --bundle-id com.nuzzle.Nuzzle --filter "Error"
./scripts/xcode-logs.sh --level error --output error-logs.txt

# View help
./scripts/xcode-logs.sh --help
```

The log streaming script automatically detects running simulators or connected devices and streams their logs in real-time. Useful for debugging iOS app behavior without needing to keep Xcode console open.

**Hot-reload setup in `capacitor.config.ts`:**

```typescript
server: {
  url: 'http://192.168.1.10:5173', // Your local IP
  cleartext: true
}
```

## Database Development

### View Database Schema

```bash
supabase db dump --schema public > schema.sql
```

### Create New Migration

```bash
supabase migration new your_migration_name
# Edit the generated SQL file in supabase/migrations/
supabase db push
```

### Reset Local Database (WARNING: Deletes all data)

```bash
supabase db reset
```

### Query Database

```bash
# Via Supabase Studio
supabase start
# Open http://localhost:54323

# Via CLI
supabase db query "SELECT * FROM events LIMIT 10"
```

## Edge Functions Development

### Serve Function Locally

```bash
supabase functions serve ai-assistant --env-file .env
```

### Test Function

```bash
curl -X POST http://localhost:54321/functions/v1/ai-assistant \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Test message"}'
```

### View Logs

```bash
supabase functions logs ai-assistant
```

### Deploy Function

```bash
supabase functions deploy ai-assistant
```

## Troubleshooting

### Issue: "Module not found"

```bash
rm -rf node_modules package-lock.json
npm install
```

### Issue: iOS build fails

```bash
cd ios/App
pod install
cd ../..
npx cap sync ios
```

### Issue: Edge functions not working locally

Edge functions use `LOVABLE_API_KEY` which only works in Lovable environment.  
For local testing, consider mocking AI responses or using your own API keys.

### Issue: Type errors in Cursor

```bash
# Regenerate types from Supabase
npx supabase gen types typescript --project-id your-project-id > src/integrations/supabase/types.ts
```

### Issue: Hot-reload not working in iOS

1. Ensure your computer and iOS device are on same WiFi
2. Check firewall isn't blocking port 5173
3. Verify IP address in `capacitor.config.ts` is correct
4. Try disabling VPN if active

### Issue: Permission denied errors

```bash
# Fix iOS permissions
sudo xcode-select --reset
sudo xcodebuild -license accept
```

## Code Quality

### Linting

```bash
npm run lint
```

### Type Checking

```bash
npx tsc --noEmit
```

### Format Code

```bash
npx prettier --write "src/**/*.{ts,tsx}"
```

## Performance Profiling

### React DevTools

1. Install React DevTools browser extension
2. Open DevTools → Profiler tab
3. Record interaction and analyze

### Lighthouse

```bash
npm run build
npm run preview
# Open Chrome DevTools → Lighthouse → Run audit
```

## Debugging Tips

### React Query DevTools

Already installed - open `/` and look for floating React Query icon in bottom-right.

### Zustand DevTools

```typescript
// In any component
import { useAppStore } from '@/store/appStore';
console.log(useAppStore.getState());
```

### IndexedDB Inspector

Chrome DevTools → Application tab → Storage → IndexedDB → nestling

### Network Requests

Chrome DevTools → Network tab → Filter by "supabase.co"

## Helpful Commands

```bash
# Full reset (nuclear option)
rm -rf node_modules package-lock.json dist .vite
npm install
npm run build

# Check bundle size
npm run build
du -sh dist/

# Find large dependencies
npx vite-bundle-visualizer

# Update dependencies
npm outdated
npm update
```
