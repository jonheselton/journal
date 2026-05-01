# Daily Journal TODO

## 🚀 Phase 1: Play Store Publishing (Action Required)

These steps must be completed in the [Google Play Console](https://play.google.com/console) via a web browser.

- [ ] **Create App Record**
  - Name: "Daily Journal"
  - Category: Health & Fitness
  - Type: App (Free)
- [ ] **Set up Internal Testing Track**
  - Allows up to 100 testers immediately without Google review.
- [ ] **Upload Release Bundle**
  - Path: `hello_world/build/app/outputs/bundle/release/app-release.aab`
- [ ] **Configure Store Listing**
  - Assets ready in `hello_world/store/` (Icon, Feature Graphic).
  - Copy description from `hello_world/store/description.md`.
- [ ] **Host & Link Privacy Policy**
  - Host `hello_world/store/privacy_policy.html` (e.g., GitHub Pages).
  - Link the public URL in the Play Console under "App Content".
- [ ] **Submit Health Connect Declaration**
  - Required for steps, heart rate, and sleep data.
  - Follow the template in `hello_world/store/health_connect_declaration.md`.

## 🛠️ Local Refinements & Maintenance

- [ ] **Automated Tests**
  - [ ] Add widget tests for the new `x` medication radio buttons.
  - [ ] Add unit tests for `PinService` lockout time calculations.
- [ ] **Security Hardware Tasks**
  - [ ] Change master keystore password (current: `DJournal2026Secure`) and store in a secure manager.

## 🧪 Manual Verification Checklist

- [ ] **E3-T3:** Verify auto-tags still display on `DayEntryScreen` after removing Top Keywords from Statistics.
- [ ] **E4-T6:** Verify notification tap → auth → 🧠 wizard → entry saved flow on a real device.
- [ ] **E1-T3:** Enter 4 wrong PINs and confirm 2s lockout message with disabled numpad.
- [ ] **E4-T2:** Create two entries in one day, confirm wizard only appears on first.

---

## ✅ Completed Tasks

- [x] **Security:** PIN brute-force protection with escalating lockout (v1.1.0).
- [x] **Privacy:** NLP Sensitive-term blacklist for keyword extraction (v1.1.0).
- [x] **Privacy:** Removed "Top Keywords" from Statistics dashboard (v1.1.0).
- [x] **Architecture:** Refactored `xanax` → `x` (generic metric) including DB migration (v1.1.0).
- [x] **UX:** Decoupled wizard from entry creation; added manual "Add Details" button.
- [x] **UX:** Added empty-state prompts in the editor.
- [x] **Engine:** Cleaned up legacy `clouds` and `bubs` columns from database.
- [x] **Notifications:** Integrated daily noon check-in reminders.
- [x] **Publishing:** Generated production-ready App Bundle (AAB).
- [x] **Publishing:** Prepared all store assets (icons, graphics, policy, declaration).

# TODO

## Remaining Manual Steps

- [x] **Host privacy policy** at a public URL (GitHub Pages, static site, etc.)
- [ ] **Register Google Play Developer account** ($25 fee) at [play.google.com/console](https://play.google.com/console)
- [x] **Build release AAB:** `flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info`
- [ ] **Submit to Play Console** — follow `store/developer_account_guide.md`
- [ ] **Complete Health Connect declaration** — follow `store/health_connect_declaration.md`
- [ ] Test on a real device with Health Connect installed
- [ ] **Change keystore password** (`DJournal2026Secure`) and store in password manager

## Manual Verification Needed

- [ ] Verify auto-tags still display on `DayEntryScreen` after removing Top Keywords from Statistics (E3-T3)
- [ ] Verify notification tap → auth → wizard → entry saved flow on device (E4-T6)
- [ ] Enter 4 wrong PINs and confirm 2s lockout message with disabled numpad (E1-T3)
- [ ] Create two entries in one day, confirm wizard only appears on first (E4-T2)

## Completed (see CHANGELOG.md for details)

- [x] PIN brute-force protection (E1-T1, E1-T2, E1-T3)
- [x] Rename `xanax` → `x` model, schema migration, UI (E2-T1 through E2-T5)
- [x] Sensitive-term blacklist in KeywordExtractor (E3-T1)
- [x] Remove Top Keywords from StatisticsScreen (E3-T2)
- [x] Wizard completion tracking in DatabaseService (E4-T1)
- [x] Decouple wizard from entry creation (E4-T2)
- [x] Manual Check-In button on DayEntryScreen (E4-T3)
- [x] flutter_local_notifications dependency + manifest (E4-T4)
- [x] NotificationService for daily noon remnder (E4-T5)