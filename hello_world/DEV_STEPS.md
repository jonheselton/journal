# DEV_STEPS — Play Store Publication Checklist

Follow these steps in order. Check off each one as you complete it.

---

## Step 1: Host the Privacy Policy
- [ ] Upload `store/privacy_policy.html` to a public URL
  - **GitHub Pages:** create a repo, push the file, enable Pages in Settings
  - **Firebase Hosting:** `firebase init hosting && firebase deploy`
  - Or any static host (Netlify, Vercel, etc.)
- [ ] Save the public URL — you need it for Step 3

## Step 2: Register Play Developer Account
- [ ] Go to: **https://play.google.com/console/signup**
- [ ] Sign in as `google@gencan.io`
- [ ] Choose **Personal** or **Organization**
- [ ] Pay the **$25 one-time fee**
- [ ] Complete identity verification (government ID for personal, D-U-N-S + business docs for org)
- [ ] Wait for approval (**2-7 business days**)

## Step 3: Upload to Play Console
- [ ] Click **"Create app"** in Play Console
  - App name: **Daily Journal**
  - Language: English
  - Type: App, Free
- [ ] **Store listing** — copy text from `store/description.md`
- [ ] Upload **app icon** from `store/app_icon.png`
- [ ] Upload **feature graphic** from `store/feature_graphic.png`
- [ ] Take **2-3 screenshots** from your device and upload
- [ ] **Privacy policy** — paste your hosted URL from Step 1
- [ ] **Ads** → No ads
- [ ] **Content rating** → complete IARC questionnaire
- [ ] **Target audience** → 18+
- [ ] **Data safety:**
  - Data collected: Health info (steps, HR, sleep)
  - Shared with third parties: No
  - Encrypted: Yes
  - Users can delete: Yes
- [ ] **Health Connect declaration** — use answers from `store/health_connect_declaration.md`
- [ ] **Upload AAB:** `build/app/outputs/bundle/release/app-release.aab`
- [ ] **Create release** → add release notes → Start rollout
- [ ] *(Recommended: start with Internal Testing track first)*

## Step 4: Test on Device
- [ ] Connect Android device via USB (USB debugging enabled)
- [ ] Install Health Connect from Play Store (if not built-in)
- [ ] Run: `flutter run --release`
- [ ] Verify: auth → wizard (7 pages) → health data → save/load → re-lock → screenshot blocked

---

## Important Reminders

> ⚠️ **Back up your keystore!**
> File: `android_scratch/upload-keystore.jks`
> Password: Stored in macOS Keychain / password manager (not committed to source control).
> If lost, you can NEVER update this app on the Play Store.

> ⏳ **Timeline**
> - Internal testing: immediate (no review)
> - Production review: 3-7 days
> - Health Connect review: 1-4 weeks
