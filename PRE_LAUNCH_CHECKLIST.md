# Pre-Launch Checklist - Nestling MVP

## 🚨 CRITICAL (MUST HAVE)

### Code Quality
- [ ] All E2E tests passing (0 failures)
- [ ] All unit tests passing (0 failures)
- [ ] TypeScript: 0 errors (`npx tsc --noEmit`)
- [ ] Linter: 0 errors (`npm run lint`)
- [ ] Production build succeeds (`npm run build`)
- [ ] No console errors in production build
- [ ] No console warnings in production build

### Security
- [ ] RLS policies enabled on all database tables
- [ ] Supabase linter shows 0 critical warnings
- [ ] No API keys exposed in client code
- [ ] Environment variables in .env (not committed)
- [ ] SECRETS.md documents all secrets
- [ ] Password breach protection enabled

### App Store Assets
- [ ] App icon created (1024×1024 PNG)
- [ ] 6+ screenshots captured (1290×2796 px)
- [ ] App Store metadata written (name, description, keywords)
- [ ] Privacy policy created and publicly accessible
- [ ] Support email set up
- [ ] Copyright statement prepared

### Legal & Compliance
- [ ] Privacy policy reviewed
- [ ] Medical disclaimer visible in app (Settings page)
- [ ] Terms of Service (if required)
- [ ] Age rating confirmed (4+)

### Testing
- [ ] Tested on iOS simulator (iPhone 15 Pro)
- [ ] Tested on physical iPhone device (if available)
- [ ] Tested in Chrome desktop
- [ ] All 6 critical user paths verified
- [ ] Offline mode works flawlessly
- [ ] Multi-device sync works

## ⚠️ IMPORTANT (SHOULD HAVE)

### Performance
- [ ] Lighthouse Performance score > 90
- [ ] Lighthouse Accessibility score > 95
- [ ] Lighthouse Best Practices score > 95
- [ ] Lighthouse SEO score > 90
- [ ] First Contentful Paint < 1.5s
- [ ] Largest Contentful Paint < 2.5s
- [ ] Cumulative Layout Shift < 0.1

### Accessibility
- [ ] WCAG AA compliance verified
- [ ] VoiceOver navigation tested (iOS)
- [ ] Keyboard navigation tested (desktop)
- [ ] Large Text support verified
- [ ] Color contrast meets 4.5:1 ratio
- [ ] Touch targets ≥ 44pt
- [ ] Focus indicators visible

### UI/UX Polish
- [ ] Loading states consistent across app
- [ ] Empty states friendly and helpful
- [ ] Error messages specific and actionable
- [ ] Success feedback via toasts + haptics
- [ ] Dark mode looks great
- [ ] Typography scales properly
- [ ] No text truncation at large sizes
- [ ] Animations smooth (60fps)

### Data Management
- [ ] CSV export works correctly
- [ ] Delete account/data works
- [ ] No orphaned records after deletion

## 🎨 NICE TO HAVE (OPTIONAL)

### Advanced Features
- [ ] Analytics configured
- [ ] Error monitoring set up (Sentry)
- [ ] Performance monitoring
- [ ] Feature flags system

### Content
- [ ] Onboarding tutorial/walkthrough
- [ ] Help documentation or FAQ page
- [ ] Video demo for App Store preview
- [ ] Blog post announcing launch
- [ ] Social media assets prepared

### Community
- [ ] Beta testing via TestFlight completed
- [ ] User feedback incorporated
- [ ] Support Discord or forum set up
- [ ] Email list for updates

## 📱 iOS-Specific Checklist

### Xcode Project
- [ ] Bundle ID configured
- [ ] Version number set (1.0.0)
- [ ] Build number set (1)
- [ ] Team/signing configured
- [ ] Capabilities enabled (Push Notifications, etc.)
- [ ] Info.plist permissions configured

### App Store Connect
- [ ] App listing created
- [ ] Screenshots uploaded (6.7" iPhone)
- [ ] App preview video uploaded (optional)
- [ ] Metadata entered (name, description, keywords)
- [ ] Privacy labels completed
- [ ] Build uploaded via Xcode
- [ ] Build submitted for review

## 🚀 Deployment Checklist

### Web Deployment
- [ ] Environment variables configured
- [ ] Custom domain connected (if applicable)
- [ ] SSL certificate active (HTTPS)
- [ ] Production build deployed
- [ ] Smoke test: test core features on production

### Post-Deployment
- [ ] Monitor error logs (first 24 hours)
- [ ] Monitor performance
- [ ] Check Supabase usage
- [ ] Verify emails/notifications sending
- [ ] Test on multiple devices
- [ ] Announce launch

## ✅ Final Sign-Off

**Tested by:** ___________________  
**Date:** ___________________  
**Ready for App Store submission:** [ ] YES / [ ] NO

**Notes:**
_______________________________________________________
_______________________________________________________

**Approved by:** ___________________  
**Date:** ___________________
