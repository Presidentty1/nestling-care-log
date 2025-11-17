# Nestling 🍼

A comprehensive baby care logging app with local-first architecture. Track feedings, sleep, diapers, tummy time with intelligent predictions and offline support.

## ✨ Features

- 📱 **Complete Offline Support** - Works without internet
- 🎯 **Smart Nap Predictions** - Age-based wake windows
- ⏱️ **Flexible Logging** - Timer or manual entry
- 📊 **Visual Timeline** - See your day at a glance
- 📅 **History Tracking** - Navigate past days
- 👨‍👩‍👧‍👦 **Multiple Babies** - Manage care for siblings
- 📤 **Export Data** - CSV/PDF for doctor visits
- ♿ **Caregiver Mode** - Enhanced accessibility
- 🔒 **Privacy First** - All data stays local

## 🚀 Quick Start

```bash
npm install
npm run dev
```

Visit http://localhost:5173

## 📱 iOS Development

### Prerequisites
- macOS with Xcode 15+
- iOS 14+ device or simulator
- Valid Apple Developer account (for device testing)

### Setup
```bash
# Install dependencies
npm install

# Build web assets
npm run build

# Add iOS platform (first time only)
npx cap add ios

# Sync and open Xcode
npm run cap:ios
```

### Development Workflow
```bash
# Option 1: Hot reload from simulator
# Edit capacitor.config.ts, set server.url to your local IP
npm run dev
# In Xcode, run on simulator - changes reload instantly!

# Option 2: Full rebuild
npm run cap:run:ios
```

### Building for App Store
See `DEPLOYMENT.md` for complete guide.

## 🔧 Development in Cursor

This project is optimized for Cursor 2.0:
1. Clone the repository
2. Open in Cursor
3. Run `npm install`
4. Read `DEVELOPMENT.md` for full setup guide
5. AI rules are in `.cursorrules`

## 🚀 Deployment

See `DEPLOYMENT.md` for:
- Vercel/Netlify deployment
- Edge function deployment  
- iOS App Store submission
- Environment variable setup

## 📚 Documentation

- `DEVELOPMENT.md` - Complete local development guide
- `DEPLOYMENT.md` - Production deployment instructions
- `TESTING_CHECKLIST.md` - Pre-deployment testing steps
- `MIGRATION_CHECKLIST.md` - Lovable to Cursor migration guide
- `SECRETS.md` - Environment variables and secrets
- `supabase/functions/README.md` - Edge functions documentation

## Project Info

**URL**: https://lovable.dev/projects/3be850d6-430e-4062-887d-a465d2abf643

## How can I edit this code?

There are several ways of editing your application.

**Use Lovable**

Simply visit the [Lovable Project](https://lovable.dev/projects/3be850d6-430e-4062-887d-a465d2abf643) and start prompting.

Changes made via Lovable will be committed automatically to this repo.

**Use your preferred IDE**

If you want to work locally using your own IDE, you can clone this repo and push changes. Pushed changes will also be reflected in Lovable.

The only requirement is having Node.js & npm installed - [install with nvm](https://github.com/nvm-sh/nvm#installing-and-updating)

Follow these steps:

```sh
# Step 1: Clone the repository using the project's Git URL.
git clone <YOUR_GIT_URL>

# Step 2: Navigate to the project directory.
cd <YOUR_PROJECT_NAME>

# Step 3: Install the necessary dependencies.
npm i

# Step 4: Start the development server with auto-reloading and an instant preview.
npm run dev
```

**Edit a file directly in GitHub**

- Navigate to the desired file(s).
- Click the "Edit" button (pencil icon) at the top right of the file view.
- Make your changes and commit the changes.

**Use GitHub Codespaces**

- Navigate to the main page of your repository.
- Click on the "Code" button (green button) near the top right.
- Select the "Codespaces" tab.
- Click on "New codespace" to launch a new Codespace environment.
- Edit files directly within the Codespace and commit and push your changes once you're done.

## What technologies are used for this project?

This project is built with:

- Vite
- TypeScript
- React
- shadcn-ui
- Tailwind CSS

## How can I deploy this project?

Simply open [Lovable](https://lovable.dev/projects/3be850d6-430e-4062-887d-a465d2abf643) and click on Share -> Publish.

## Can I connect a custom domain to my Lovable project?

Yes, you can!

To connect a domain, navigate to Project > Settings > Domains and click Connect Domain.

Read more here: [Setting up a custom domain](https://docs.lovable.dev/features/custom-domain#custom-domain)
