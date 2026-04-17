# Google Play Developer Account Setup

## Steps

1. **Go to** [Google Play Console](https://play.google.com/console/signup)
2. **Sign in** with your Google account
3. **Pay the one-time $25 registration fee**
4. **Complete identity verification:**
   - Personal account: government-issued ID
   - Organization account: D-U-N-S number + business documents
5. **Wait for verification** (typically 2-7 business days for personal, longer for organizations)

## After Verification

1. **Create your app** → "Create app" button in Play Console
2. **Fill in the app details:**
   - App name: Daily Journal
   - Default language: English
   - App or Game: App
   - Free or Paid: Free
3. **Complete all the store listing sections** (see `description.md`)
4. **Complete App Content sections:**
   - Privacy policy URL (host `privacy_policy.html`)
   - Health Connect declaration (see `health_connect_declaration.md`)
   - Data safety questionnaire
   - Content rating (IARC questionnaire)
   - Target audience
5. **Upload your app bundle:**
   ```bash
   flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
   ```
   Upload `build/app/outputs/bundle/release/app-release.aab`
6. **Create a release** in the Production track (or start with Internal Testing)
7. **Submit for review**

## Recommended: Start with Internal Testing

Before going to production, use the **Internal testing track** in Play Console:
- Up to 100 testers by email
- No review required
- Good for validating the build works on real devices via Play Store

## Timeline Expectations

| Step | Estimated Time |
|------|---------------|
| Account verification | 2-7 days |
| Internal testing setup | Same day |
| Production review (standard) | 3-7 days |
| Health Connect review | 1-4 weeks |
