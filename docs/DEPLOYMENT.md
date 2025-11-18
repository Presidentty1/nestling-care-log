# Deployment Guide

## Current Deployment (Web)

### Frontend Hosting
- **Platform**: Lovable hosting (automatic)
- **Build**: Automatic on code push
- **Domain**: https://nestling-care-log.lovable.app
- **SSL**: Automatic (Let's Encrypt)
- **CDN**: Built-in global distribution

### Backend (Supabase via Lovable Cloud)
- **Database**: PostgreSQL (managed by Supabase)
- **Edge Functions**: Auto-deploy on code push
- **Authentication**: Supabase Auth
- **Storage**: Supabase Storage (for future photo features)

### Build Process
1. Code pushed to Lovable
2. Vite builds production bundle
   - Tree-shaking unused code
   - Minification
   - Asset optimization
3. Edge functions deployed to Supabase
4. Static files deployed to CDN
5. Preview URL generated instantly

### Environment Variables
Managed automatically by Lovable:
- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`
- `VITE_SUPABASE_PROJECT_ID`

No manual configuration needed.

## Performance Optimization

### Current Metrics (Target)
- **Lighthouse Score**: 90+ overall
- **First Contentful Paint (FCP)**: < 1.5s
- **Largest Contentful Paint (LCP)**: < 2.5s
- **Time to Interactive (TTI)**: < 3.5s
- **Cumulative Layout Shift (CLS)**: < 0.1

### Optimizations Applied
1. **Code Splitting**: React.lazy() for heavy pages
2. **Image Optimization**: WebP format, lazy loading
3. **Caching**: LocalStorage + IndexedDB for offline
4. **Prefetching**: Critical resources prefetched
5. **Bundle Size**: < 500KB gzipped (currently ~380KB)

### Monitoring
- Lovable built-in analytics
- Real User Monitoring (RUM) in production
- Error tracking via browser console logs

## iOS Deployment (Future)

### Prerequisites
- **Xcode**: Version 15+ (macOS required)
- **Apple Developer Account**: $99/year
- **Capacitor**: Already configured in project
- **CocoaPods**: For iOS dependencies

### Build Steps

#### 1. Install Dependencies
```bash
npm install
npm run build
npx cap sync ios
```

#### 2. Open in Xcode
```bash
npx cap open ios
```

#### 3. Configure Xcode Project

**App Settings** (General tab):
- Bundle Identifier: `com.nestling.caretracker`
- Version: 1.0.0
- Build: 1
- Deployment Target: iOS 15.0+

**Signing & Capabilities**:
- Team: Select your Apple Developer team
- Enable:
  - Push Notifications
  - Background Modes (Remote notifications)
  - App Groups (for shared data)

**Info.plist Keys**:
```xml
<key>NSCameraUsageDescription</key>
<string>We use the camera to capture photos for milestones and memories.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to save baby photos.</string>

<key>NSMicrophoneUsageDescription</key>
<string>We use speech recognition to help you log events hands-free.</string>

<key>NSSpeechRecognitionUsageDescription</key>
<string>Voice commands make logging easier when your hands are full.</string>

<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

#### 4. Build for Device
1. Select target device (your iPhone or "Any iOS Device")
2. Product → Archive
3. Wait for build to complete (5-10 minutes first time)

#### 5. TestFlight Beta Testing

**Upload to App Store Connect**:
1. Window → Organizer
2. Select your archive
3. Click "Distribute App"
4. Choose "App Store Connect"
5. Upload (this takes 10-20 minutes)

**Set Up TestFlight**:
1. Go to App Store Connect
2. Select your app
3. Go to TestFlight tab
4. Add internal testers (your team)
5. Add external testers (beta users)
6. Wait for Apple review (1-2 days for first build)

**Invite Testers**:
- Internal: Immediate access after upload
- External: Access after Apple review
- Testers install via TestFlight app
- You can have up to 10,000 beta testers

#### 6. Production Release

**Prepare App Store Listing**:
- App Name: "Nestling - Baby Care Tracker"
- Subtitle: "AI-Powered Parenting Assistant"
- Keywords: baby tracker, newborn, feeding, sleep, diaper, parenting
- Description: See `APP_STORE_METADATA.md`
- Screenshots: See `SCREENSHOT_SPECS.md`
- App Icon: See `APP_ICON_GUIDELINES.md`
- Privacy Policy URL: Required
- Age Rating: 4+ (No objectionable content)
- Category: Primary: Lifestyle, Secondary: Health & Fitness

**Submit for Review**:
1. Create version 1.0.0 in App Store Connect
2. Upload all metadata and screenshots
3. Select build from TestFlight
4. Submit for review
5. Wait 1-3 days for Apple review

**Review Guidelines to Follow**:
- Accurate metadata (no misleading claims)
- Medical disclaimer prominent (we have this)
- Privacy policy clearly linked
- Functional demo account not required (auth is simple)
- No crashes or major bugs
- Follows Human Interface Guidelines

### Continuous Deployment (CI/CD)

**For iOS TestFlight Automation** (optional):
Use Fastlane to automate builds and uploads

```ruby
# Fastfile
lane :beta do
  increment_build_number
  build_app(scheme: "App")
  upload_to_testflight(skip_waiting_for_build_processing: true)
end
```

Run with:
```bash
fastlane beta
```

## Android Deployment (Future)

### Prerequisites
- **Android Studio**: Latest version
- **Google Play Console Account**: $25 one-time fee
- **Capacitor**: Already configured

### Build Steps

#### 1. Prepare Android Project
```bash
npm run build
npx cap sync android
npx cap open android
```

#### 2. Configure Android Studio

**build.gradle** (app level):
```gradle
android {
    defaultConfig {
        applicationId "com.nestling.caretracker"
        minSdkVersion 22
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }
}
```

**AndroidManifest.xml permissions**:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

#### 3. Generate Signed APK
1. Build → Generate Signed Bundle / APK
2. Choose "Android App Bundle" (AAB)
3. Create keystore (save it securely!)
4. Sign with keystore
5. Build release variant

#### 4. Upload to Play Console
1. Create app in Google Play Console
2. Complete store listing:
   - Title, description, icon
   - Screenshots (phone, tablet, TV optional)
   - Content rating questionnaire
   - Privacy policy
3. Upload AAB file to Internal Testing track
4. Invite testers via email
5. Promote to Open Testing (optional)
6. Submit for Production review

**Play Store Review**: Usually faster than Apple (1-3 days)

## Database Migrations

### Development
- Migrations auto-generated when using Lovable
- Stored in `supabase/migrations/`
- Applied automatically to preview environment

### Production
- Migrations reviewed before applying
- Test in staging environment first (if available)
- Apply via Supabase dashboard or CLI
- Backup database before major migrations

### Rollback Strategy
```sql
-- If migration fails, rollback:
BEGIN;
-- Apply reverse migration
ROLLBACK; -- or COMMIT; if successful
```

## Monitoring & Maintenance

### Health Checks
- **Frontend**: Automatic (Lovable monitoring)
- **Edge Functions**: Check Supabase logs
- **Database**: Monitor query performance in Supabase dashboard

### Error Tracking
- Browser console errors (captured client-side)
- Supabase logs for edge function errors
- Consider adding Sentry for production (future)

### Performance Monitoring
- Lighthouse CI (run before each deployment)
- Real User Monitoring metrics
- Database query analysis (Supabase dashboard)

### Backup Strategy
- **Database**: Automatic daily backups (Supabase)
- **Retention**: 7 days on free tier, 30 days on paid
- **Point-in-time recovery**: Available on paid plans
- **User data export**: Users can export their own data

### Update Cadence
- **Minor updates**: Weekly (bug fixes, small features)
- **Major updates**: Monthly (new features, UX improvements)
- **Security patches**: Immediate as needed
- **iOS/Android updates**: Submit after thorough testing

## Scaling Considerations

### Current Capacity
- **Lovable hosting**: Scales automatically
- **Supabase free tier**:
  - 500 MB database
  - 1 GB file storage
  - 2 GB bandwidth
  - Good for ~1000 active users

### When to Upgrade
- > 400 MB database usage
- > 500 concurrent users
- Need advanced features (point-in-time recovery)
- Need dedicated support

### Supabase Paid Tiers
- **Pro**: $25/month
  - 8 GB database
  - 100 GB file storage
  - 250 GB bandwidth
  - Point-in-time recovery
  - ~10,000 active users

- **Team**: $599/month
  - 50+ GB database
  - Priority support
  - ~100,000+ active users

## Security Best Practices

### Pre-Deployment Checklist
- [ ] All API keys stored as environment variables (not in code)
- [ ] RLS policies tested on all tables
- [ ] Authentication flows tested
- [ ] HTTPS enabled (automatic on Lovable)
- [ ] Content Security Policy headers configured
- [ ] Rate limiting on edge functions
- [ ] SQL injection prevention (use parameterized queries)
- [ ] XSS prevention (React's default escaping)

### Post-Deployment Monitoring
- Monitor for unusual API usage patterns
- Check for failed authentication attempts
- Review edge function logs for errors
- Set up alerts for critical errors

## Rollback Procedures

### Frontend Rollback
1. In Lovable dashboard, find previous working version
2. Click "Restore" or redeploy from Git tag
3. Verify functionality in preview
4. Publish to production

### Database Rollback
1. Identify failed migration
2. Write reverse migration SQL
3. Apply in Supabase SQL editor
4. Verify data integrity
5. Document incident

### Emergency Procedures
- **Critical bug in production**:
  1. Immediately rollback frontend to previous version
  2. Notify users via in-app banner if necessary
  3. Fix bug in development
  4. Test thoroughly
  5. Redeploy

## Support Resources

### Documentation
- Lovable Docs: https://docs.lovable.dev
- Supabase Docs: https://supabase.com/docs
- Capacitor Docs: https://capacitorjs.com/docs
- Apple Developer: https://developer.apple.com
- Google Play: https://developer.android.com

### Community
- Lovable Discord/Support
- Supabase Discord
- Stack Overflow tags: react, supabase, capacitor

### Internal Docs
- `ARCHITECTURE.md` - Technical overview
- `DATA_MODEL.md` - Database schema
- `TESTING.md` - Testing procedures
- `MVP_SCOPE.md` - Feature prioritization
