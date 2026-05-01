# Daily Journal TODO

> **Current Release:** v1.1.0 "Fourvel" (2026-05-01)

---

## 🚀 Play Store Publishing (In Progress)

- [x] **Register Google Play Developer account** — Done, Play Console accessible
- [x] **Host privacy policy** — Live at `https://storage.googleapis.com/lunawatch-93f3a-privacy-policy/index.html`
- [x] **Build release AAB** — `com.gencan.journal` v1.1.0+3
- [x] **Upload to Internal Testing track** — Fourvel release uploaded
- [ ] **Add testers & roll out** — Add email list, hit "Start rollout"
- [ ] **Configure Store Listing** — App name, description, icon, screenshots
- [ ] **Complete Health Connect declaration** — Required for steps, heart rate, sleep data
- [ ] **Complete Data Safety questionnaire** — Declare local-only storage, no data sharing
- [ ] **Content Rating questionnaire** — Get age rating
- [ ] **Target Audience declaration** — Age groups

## 🔐 Security Housekeeping

- [ ] **Change keystore password** — Current: `DJournal2026Secure` → store in a password manager

## 🧪 Manual Verification (Requires Device)

- [ ] Verify auto-tags display on `DayEntryScreen` after Top Keywords removal (E3-T3)
- [ ] Verify notification tap → auth → wizard → entry saved flow (E4-T6)
- [ ] Enter 4 wrong PINs, confirm 2s lockout with disabled numpad (E1-T3)
- [ ] Create two entries in one day, confirm wizard only appears on first (E4-T2)

## 🛠️ Future Improvements

- [ ] Add widget tests for `x` medication radio buttons
- [ ] Add unit tests for `PinService` lockout calculations
- [ ] Upgrade deprecated `flutter_markdown` → `flutter_markdown_plus`

---

## ✅ Completed

- [x] PIN brute-force protection with escalating lockout (E1)
- [x] Rename `xanax` → `x` generic metric + DB migration (E2)
- [x] Sensitive-term blacklist for keyword extraction (E3-T1)
- [x] Remove "Top Keywords" from Statistics dashboard (E3-T2)
- [x] Wizard completion tracking + decouple from entry creation (E4-T1, E4-T2)
- [x] Manual Check-In button on DayEntryScreen (E4-T3)
- [x] Daily noon reminder notifications (E4-T4, E4-T5)
- [x] Questionnaire cleanup — removed Clouds/Bubs (E6)
- [x] Database cleanup — dropped legacy columns (E7)
- [x] UX polish & logging fixes (E8)
- [x] Package rename `io.gencan.dailyjournal` → `com.gencan.journal`
- [x] Privacy policy deployed via Terraform on GCS