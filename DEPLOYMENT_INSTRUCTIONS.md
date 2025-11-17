# Deployment Instructions - Nestling MVP

## Prerequisites
- [ ] All tests passing
- [ ] All checklist items completed
- [ ] App Store assets ready

## Step 1: Deploy Web App

### Deploy to Lovable (Recommended)
1. Click "Publish" button in Lovable editor (top right)
2. Click "Update" to deploy latest changes
3. Copy the published URL
4. Test live app at deployed URL
5. Check for console errors in production

**Expected URL format:**
```
https://[your-project].lovableproject.com
```

### Alternative: Deploy to Vercel
```bash
# 1. Install Vercel CLI
npm i -g vercel

# 2. Login
vercel login

# 3. Deploy
vercel

# 4. Assign custom domain (if applicable)
vercel domains add your-domain.com
```

## Step 2: Configure Environment

**Verify production environment variables are set:**
- `VITE_SUPABASE_PROJECT_ID`
- `VITE_SUPABASE_PUBLISHABLE_KEY`
- `VITE_SUPABASE_URL`

These should be automatically configured in Lovable Cloud.

## Step 3: Build iOS App

```bash
# 1. Build web assets
npm run build

# 2. Sync to Capacitor
npx cap sync ios

# 3. Open Xcode
npx cap open ios
```

**In Xcode:**
1. Select target: Generic iOS Device
2. Product → Archive
3. Wait for archive to complete
4. Click "Distribute App"
5. Select "App Store Connect"
6. Follow prompts to upload

## Step 4: Submit to App Store

**In App Store Connect (https://appstoreconnect.apple.com):**

1. Navigate to your app
2. Click "+ Version or Platform"
3. Enter version: 1.0.0
4. Upload screenshots (from SCREENSHOT_SPECS.md)
5. Enter metadata (from APP_STORE_METADATA.md)
6. Select build from Xcode upload
7. Complete privacy labels
8. Submit for review

**Expected timeline:**
- Upload: Immediate
- Processing: 30-60 minutes
- Review: 1-3 days
- Approved: Live within hours

## Step 5: Post-Launch Monitoring

**First 24 hours:**
- [ ] Monitor error logs
- [ ] Check Lovable Cloud dashboard (usage, errors)
- [ ] Test app on real devices
- [ ] Respond to any crashes/bugs immediately

**First week:**
- [ ] Collect user feedback
- [ ] Monitor app reviews
- [ ] Track key metrics (DAU, retention)
- [ ] Plan hotfix if needed

## Rollback Plan

**If critical bug found:**

1. **Web app:**
   - In Lovable: Revert to previous version
   - Or redeploy fixed version immediately

2. **iOS app:**
   - Cannot roll back once live
   - Submit hotfix build (version 1.0.1)
   - Use "Expedited Review" if critical
   - Consider temporarily removing from App Store

## Support Setup

**Set up these channels:**
- [ ] Support email: support@nestling.app
- [ ] Help documentation: /help page
- [ ] Bug reporting: /feedback page
- [ ] Optional: Discord or community forum

## Success Metrics

**Track these KPIs:**
- Downloads (App Store analytics)
- Daily Active Users (DAU)
- Events logged per user
- Retention (Day 1, Day 7, Day 30)
- Crash-free rate (target: >99%)
- App Store rating (target: >4.5 stars)

## Troubleshooting

**Common issues:**

1. **Build fails in Xcode:**
   - Check iOS deployment target (iOS 14+)
   - Verify signing certificates
   - Run `npx cap sync ios` again

2. **App Store rejection:**
   - Common: Privacy policy not accessible
   - Common: Missing age rating justification
   - Fix and resubmit

3. **Crashes on device:**
   - Check Xcode console for logs
   - Verify Capacitor plugins configured correctly
   - Test on physical device before submitting

## Post-Launch Todo

- [ ] Set up crash reporting (Sentry recommended)
- [ ] Configure analytics (Plausible/Fathom)
- [ ] Create support documentation
- [ ] Plan first update (1.1.0)
- [ ] Gather user feedback
- [ ] Iterate based on usage data
