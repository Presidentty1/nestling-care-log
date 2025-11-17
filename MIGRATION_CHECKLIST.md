# 🔄 Migration from Lovable to Cursor - Final Checklist

## Pre-Migration (In Lovable)
- [ ] Export project to GitHub
- [ ] Document all custom configurations
- [ ] Note any Lovable-specific features being used
- [ ] Backup database: Use Cloud → Database → Export
- [ ] Test all features work correctly
- [ ] Run full test suite: `npm run test` and `npm run test:e2e`
- [ ] Document current state (screenshots, videos)
- [ ] List all edge functions and their purposes
- [ ] Verify all environment variables are documented

## Initial Migration Steps
- [ ] Clone repo to local machine: `git clone <repo-url>`
- [ ] Install dependencies: `npm install`
- [ ] Verify Node version: `node --version` (should be 18+)
- [ ] Create `.env` file with Supabase credentials (copy from Lovable)
- [ ] Start dev server: `npm run dev`
- [ ] Verify app runs at http://localhost:5173
- [ ] Run tests: `npm run test`
- [ ] Fix any failing tests

## Capacitor Setup
- [ ] Install Capacitor CLI: `npm install --save-dev @capacitor/cli`
- [ ] Install platform packages: `npm install @capacitor/ios @capacitor/android`
- [ ] Initialize Capacitor: `npx cap init`
  - App Name: `Nestling`
  - App ID: `app.lovable.3be850d6430e4062887da465d2abf643`
  - Web Dir: `dist`
- [ ] Verify `capacitor.config.ts` was created
- [ ] Build web assets: `npm run build`
- [ ] Add iOS platform: `npx cap add ios`
- [ ] Add Android platform (optional): `npx cap add android`
- [ ] Sync platforms: `npx cap sync`
- [ ] Update `package.json` with Capacitor scripts
- [ ] Update `.gitignore` for Capacitor artifacts

## iOS Configuration (macOS only)
- [ ] Open Xcode: `npx cap open ios`
- [ ] Configure signing certificate in Xcode
- [ ] Update Info.plist with permissions
  - Microphone usage description
  - Photo library usage description
  - Notifications
- [ ] Set iOS deployment target to 14.0 in Podfile
- [ ] Install CocoaPods dependencies: `cd ios/App && pod install`
- [ ] Build in Xcode (⌘+B)
- [ ] Run in simulator (⌘+R)
- [ ] Test all native features work

## Documentation Creation
- [ ] Create `.env.example` file
- [ ] Create `SECRETS.md` documenting all secrets
- [ ] Create `DEPLOYMENT.md` with deployment instructions
- [ ] Create `DEVELOPMENT.md` with setup guide
- [ ] Create `.cursorrules` for Cursor AI
- [ ] Create `.vscode/settings.json`
- [ ] Create `.vscode/extensions.json`
- [ ] Create `.prettierrc`
- [ ] Create `supabase/functions/README.md`
- [ ] Create `supabase/functions/_migration_template/index.ts`
- [ ] Create `TESTING_CHECKLIST.md`
- [ ] Update main `README.md` with iOS and Cursor sections

## Testing in New Environment
- [ ] Web app works: `npm run dev`
- [ ] Unit tests pass: `npm run test`
- [ ] E2E tests pass: `npm run test:e2e`
- [ ] iOS simulator works: `npm run cap:ios`
- [ ] All features work identically to Lovable version
- [ ] Database operations work
- [ ] Authentication works
- [ ] Edge functions work (may require LOVABLE_API_KEY)
- [ ] Offline mode works
- [ ] Dark mode works

## Edge Functions Configuration
- [ ] Install Supabase CLI: `brew install supabase/tap/supabase`
- [ ] Login to Supabase: `supabase login`
- [ ] Link project: `supabase link --project-ref tzvkwhznmkzfpenzxbfz`
- [ ] Test local function: `supabase functions serve ai-assistant`
- [ ] Deploy functions: `supabase functions deploy`
- [ ] Verify functions work in production
- [ ] Document AI provider migration strategy

## Cursor IDE Setup
- [ ] Open project in Cursor
- [ ] Install recommended extensions (see `.vscode/extensions.json`)
- [ ] Verify Cursor AI rules are loaded
- [ ] Test code completion works
- [ ] Test Cursor AI chat works
- [ ] Configure Prettier and ESLint
- [ ] Verify TypeScript IntelliSense works

## Post-Migration Validation
- [ ] All features work identically to Lovable version
- [ ] Performance is acceptable (Lighthouse > 90)
- [ ] No console errors in production build
- [ ] Tests pass in new environment
- [ ] iOS build succeeds
- [ ] Edge functions still work
- [ ] Database operations work
- [ ] Authentication works
- [ ] Can deploy to production
- [ ] Documentation is complete and accurate

## Production Deployment (Optional)
- [ ] Choose hosting platform (Vercel/Netlify/Custom)
- [ ] Set environment variables in hosting platform
- [ ] Deploy frontend: `vercel` or `netlify deploy`
- [ ] Verify production URL works
- [ ] Test on real iOS devices
- [ ] Submit to App Store (if applicable)
- [ ] Setup monitoring/analytics (Sentry, PostHog, etc.)
- [ ] Configure custom domain (if applicable)
- [ ] Setup CI/CD pipeline (GitHub Actions)

## Known Limitations After Migration

### ⚠️ Lovable AI Features
- Edge functions use `LOVABLE_API_KEY` which only works in Lovable environment
- Works in development (existing key)
- For production outside Lovable, plan to replace with OpenAI/Google AI
- See `supabase/functions/README.md` for migration strategy

### ⚠️ Auto-Deploy
- Lovable's auto-deploy won't work
- Setup CI/CD with GitHub Actions
- See `DEPLOYMENT.md` for manual deployment steps

### ⚠️ Database Migrations
- Require Supabase CLI: `brew install supabase/tap/supabase`
- Can't use Lovable's GUI migration tool
- Use `supabase migration new` and `supabase db push`

### ⚠️ Edge Function Logs
- View via Supabase CLI: `supabase functions logs ai-assistant`
- OR via Supabase dashboard (if migrating to own project)

## Success Criteria

### ✅ Migration Complete When:
1. **All new files created** - Documentation, configs, scripts ✓
2. **Capacitor configured** - iOS builds successfully ✓
3. **Tests pass** - Unit + E2E work in new environment ✓
4. **App runs in Cursor** - `npm run dev` works flawlessly ✓
5. **iOS app launches** - Simulator shows working app ✓
6. **Documentation complete** - Team can develop without Lovable ✓
7. **Edge functions documented** - Clear migration path for AI features ✓
8. **Secrets documented** - Know what needs replacing in production ✓

### 🎯 Ready for Cursor Development When:
- Developer can clone → install → run without issues
- All Cursor AI rules configured properly
- iOS development workflow documented
- Team knows how to deploy without Lovable
- Clear path forward for AI feature independence

## Rollback Plan

If migration fails:
1. Revert to Lovable version (still accessible)
2. Document issues encountered
3. Fix in local environment
4. Try migration again
5. Lovable version remains as backup until migration is stable

## Timeline Estimate
- **Setup Phase:** 2-3 hours (Steps 1-20)
- **Testing Phase:** 1-2 hours (Steps 21-30)
- **iOS Configuration:** 1-2 hours (macOS only)
- **Production Deployment:** 2-4 hours (optional)
- **Total:** 6-11 hours for complete migration

## Next Steps After Migration
1. Test thoroughly using `TESTING_CHECKLIST.md`
2. Setup CI/CD pipeline
3. Plan AI provider migration (replace Lovable AI)
4. Add monitoring/analytics
5. Performance optimization
6. App Store submission (if applicable)
