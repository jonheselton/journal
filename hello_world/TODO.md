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
- [x] NotificationService for daily noon reminder (E4-T5)
