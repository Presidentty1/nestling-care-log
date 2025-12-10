# ✅ Pre-Migration Testing Checklist

## Web App (Cursor + Local)

- [ ] `npm install` completes without errors
- [ ] `npm run dev` starts successfully at http://localhost:5173
- [ ] All pages load without console errors
- [ ] Authentication works (signup/login)
- [ ] Can create/log events (feed, sleep, diaper)
- [ ] Timeline displays correctly on home page
- [ ] History page shows past events
- [ ] AI assistant responds (requires Lovable API key)
- [ ] Nap predictor shows estimates
- [ ] Dark mode toggles correctly
- [ ] Offline mode works (disconnect wifi, verify data loads)
- [ ] Data persists after page reload
- [ ] Unit tests pass: `npm run test`
- [ ] E2E tests pass: `npm run test:e2e`
- [ ] No TypeScript errors: `npx tsc --noEmit`

## iOS Simulator

- [ ] `npm run build` completes successfully
- [ ] `npx cap add ios` creates ios/ folder
- [ ] `npx cap sync ios` completes without errors
- [ ] `npx cap open ios` opens Xcode
- [ ] App builds successfully in Xcode (⌘+B)
- [ ] App launches in simulator (⌘+R)
- [ ] Haptic feedback works (tap buttons, feel vibration)
- [ ] Local notifications trigger (schedule reminder)
- [ ] All web features work identically
- [ ] Network requests succeed (check Network tab)
- [ ] Camera permission prompt appears (for cry analysis)
- [ ] App survives background/foreground transitions
- [ ] Dark mode matches system preference
- [ ] Safe area insets work (notch/island respected)
- [ ] Performance feels smooth (60fps scrolling)

## iOS Device (Physical)

- [ ] Install via Xcode to physical device
- [ ] All simulator tests pass on device
- [ ] Performance feels smooth (no lag)
- [ ] Offline mode works completely
- [ ] Notifications appear on lock screen
- [ ] App survives phone restart
- [ ] Data syncs across devices (if multi-device)
- [ ] Battery usage is reasonable
- [ ] Haptic feedback intensity is appropriate
- [ ] App icon displays correctly on home screen

## Edge Functions

- [ ] `supabase functions serve ai-assistant` runs locally
- [ ] AI assistant function responds to test request
- [ ] Cry analysis function processes audio
- [ ] Nap predictor function returns valid data
- [ ] Functions deploy successfully: `supabase functions deploy`
- [ ] Functions work in production environment
- [ ] Function logs are accessible: `supabase functions logs`
- [ ] Error handling works (try invalid inputs)

## Database & Supabase

- [ ] Supabase connection works from local dev
- [ ] Can query tables via client
- [ ] RLS policies enforce correctly (test unauthorized access)
- [ ] Migrations apply successfully
- [ ] Realtime subscriptions work
- [ ] Auth flows work (signup, login, logout, password reset)
- [ ] Storage works (if applicable)

## Performance Benchmarks

- [ ] Lighthouse score > 90 (run on production build)
- [ ] First Contentful Paint < 1.5s
- [ ] Time to Interactive < 3s
- [ ] Bundle size < 500KB (gzipped)
- [ ] No memory leaks (open DevTools Memory profiler)

## Security Checks

- [ ] No sensitive data in console logs
- [ ] Environment variables not exposed client-side
- [ ] RLS policies tested and working
- [ ] HTTPS enforced in production
- [ ] API keys not committed to git

## User Experience

- [ ] Forms validate properly
- [ ] Error messages are user-friendly
- [ ] Loading states display correctly
- [ ] Success toasts appear
- [ ] Navigation works intuitively
- [ ] Back button works as expected
- [ ] Modal dialogs can be dismissed

## Accessibility

- [ ] Keyboard navigation works
- [ ] Screen reader announces content correctly
- [ ] Color contrast meets WCAG AA standards
- [ ] Focus indicators visible
- [ ] Touch targets are at least 44x44pt

## Browser Compatibility (Web)

- [ ] Chrome (latest)
- [ ] Safari (latest)
- [ ] Firefox (latest)
- [ ] Mobile Safari (iOS)
- [ ] Mobile Chrome (Android)

## Documentation

- [ ] README.md is up to date
- [ ] DEVELOPMENT.md is accurate
- [ ] All commands work as documented
- [ ] Environment variables documented in .env.example

## Pre-Deployment Final Checks

- [ ] All tests passing
- [ ] No console errors in production build
- [ ] Environment variables set in hosting platform
- [ ] Database migrations applied
- [ ] Edge functions deployed
- [ ] Domain configured (if applicable)
- [ ] SSL certificate active
- [ ] Monitoring/analytics configured

## Post-Deployment Smoke Tests

- [ ] Production URL loads correctly
- [ ] Can create account
- [ ] Can log events
- [ ] Can view history
- [ ] AI features work
- [ ] Notifications work
- [ ] No JavaScript errors in console
