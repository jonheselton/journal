# Changelog — Daily Journal

All notable changes to this project are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/).

---

## [1.1.1] "Sprague" — 2026-05-01

### Security

- Rotated upload keystore password — old password was committed to git history
- Sanitized `DEV_STEPS.md` and `TODO.md` to remove hardcoded password references

---

## [1.1.0] "Fourvel" — 2026-05-01

### Epic 1 — PIN Brute-Force Protection

- **E1-T1 ✅ Add failed attempt counter to PinService**
  Added `pin_failed_count` and `pin_lockout_until` secure-storage keys with accessor methods (`getFailedCount`, `incrementFailedCount`, `getLockoutUntil`, `setLockoutUntil`, `resetFailedAttempts`). State persists across app restarts via `FlutterSecureStorage`.

- **E1-T2 ✅ Implement escalating lockout logic**
  Added `verifyPinWithRateLimit()` returning `PinVerifyResult(success, isLocked, remainingSeconds)`. Lockout tiers: 1–3 failures = none, 4–5 = 2s, 6–9 = 30s, 10+ = 300s. Counter resets on successful verification.

- **E1-T3 ✅ Update PinScreen UI for lockout feedback**
  `PinScreen` now uses `verifyPinWithRateLimit()`. During lockout: numpad disabled, "Locked out. Try again in Xs" countdown via periodic `Timer`. Re-enables automatically when lockout expires.

### Epic 2 — Rename `xanax` → `x`

- **E2-T1 ✅ Rename field in DayEntry model**
  Renamed `xanax` → `x` across class field, constructor, `copyWith`, `toJson`, `fromJson`, `toDatabaseMap`, `fromDatabaseMap`. Added `_mapLegacyXanax()` for backward-compatible deserialization of old values (`< 0.5` → `1`, `0.5 <= 1.0` → `2`, `1.0 <= 1.5` → `3`, `None` → `1`).

- **E2-T2 ✅ Schema migration v1 → v2 in DatabaseService**
  Bumped `_dbVersion` to 2. Added `_onUpgrade` handler. Migration: `ALTER TABLE` to add `x`, `UPDATE` with `CASE` mapping from old `xanax` values, then rebuild table without `xanax` column. Fresh installs create table with `x` column directly.

- **E2-T3 ✅ Update WizardScreen radio buttons and tooltip**
  Renamed `_xanax` → `_x` (default `'1'`). Title changed from "Xanax?" to "X". Radio options now `1`/`2`/`3`. Added info icon button that opens dialog: "1 = 0, 2 = < 1, 3 = > 1". Wizard result emits `'x'` key.

- **E2-T4 ✅ Update DayListScreen to pass `x` from wizard result**
  Changed `wizardResult['xanax']` to `wizardData['x'] ?? '1'`. Zero `xanax` references remain in this file.

- **E2-T5 ✅ Update DayEntryScreen display chip**
  Changed `_wizardTag('Xanax', entry.xanax)` → `_wizardTag('X', entry.x)`. Zero `xanax` references remain in this file.

### Epic 3 — Keyword Privacy

- **E3-T1 ✅ Add sensitive-term blacklist to KeywordExtractor**
  Added `_sensitiveTerms` set (medications, financial, relationship terms). `extract()` now accepts `filterSensitive` parameter (default `true`). Blacklisted terms are filtered by case-insensitive substring match.

- **E3-T2 ✅ Remove "Top Keywords" from StatisticsScreen**
  Removed `_topTags` state, `getTopTags()` call, `_buildSectionHeader('Top Keywords'...)` block, and `_buildTagCloud()` method. Statistics now shows only entry count, wizard averages, and metric averages.

- **E3-T3 ⏳ Verify keywords still display on DayEntryScreen** *(manual — needs device)*
  Code confirmed: `_buildTagsCard()` using `loadDayEntryTags()` is still present. Requires manual verification on device.

### Epic 4 — Questionnaire Trigger Rework

- **E4-T1 ✅ Add wizard completion tracking to DatabaseService**
  Added `hasCompletedWizardToday()` and `getWizardDataForToday()` methods. Checks for existing entry with non-default wizard values for the current date key.

- **E4-T2 ✅ Decouple wizard from entry creation in DayListScreen**
  Refactored new-entry flow: checks `hasCompletedWizardToday()` first, reuses existing wizard data for second+ entries of the day, only shows wizard if no check-in exists.

- **E4-T3 ✅ Add manual Check-In button to DayEntryScreen**
  Added `_launchCheckIn()` method triggered from an action button. Shows redo confirmation dialog if wizard already completed today. Updates `_currentEntry` wizard fields after completion.

- **E4-T4 ✅ Add flutter_local_notifications dependency**
  Added `flutter_local_notifications` to `pubspec.yaml`. Updated `AndroidManifest.xml` with `RECEIVE_BOOT_COMPLETED`, `SCHEDULE_EXACT_ALARM`, `POST_NOTIFICATIONS` permissions and notification channel config.

- **E4-T5 ✅ Create NotificationService for daily noon reminder**
  Created `lib/services/notification_service.dart` as singleton. Implements `init()`, `scheduleDailyNoonReminder()`, and `cancelReminder()`. Initializes `daily_checkin` channel. Called from `main.dart` on app startup.

- **E4-T6 ⏳ Handle notification tap → open wizard** *(manual — needs device)*
  `onNotificationTapped` callback is wired in `NotificationService`. Requires manual verification on device: notification → auth → wizard → entry saved.

### Epic 5 — Play Store Publishing

> All tasks in this epic require manual action.

- **E5-T1 ⏳ Host privacy policy** — `store/privacy_policy.html` ready, needs deploying
- **E5-T2 ⏳ Register Google Play Developer account** — $25 fee, identity verification
- **E5-T3 ⏳ Build release AAB** — blocked until code epics verified
- **E5-T4 ⏳ Submit to Play Console** — blocked on E5-T1, E5-T2, E5-T3
- **E5-T5 ⏳ Complete Health Connect declaration** — blocked on E5-T4
- **E5-T6 ⏳ Test on real device** — blocked on E5-T3

---

## [1.0.0] — 2026-04-17

### Initial Release

- Flutter UI with dark theme and 7-page health wizard (mood, sleep, xanax, workload, clouds, bubs, energy)
- Biometric + PIN authentication with screenshot blocking
- Encrypted SQLCipher database with Android Keystore key management
- Health Connect integration (steps, heart rate, sleep stages)
- NLP keyword extraction (RAKE algorithm) with auto-tagging
- Statistics dashboard with wizard & metric averages
- Markdown journal content with preview mode
- Custom metric tracking system
