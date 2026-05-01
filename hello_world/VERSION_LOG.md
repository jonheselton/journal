# Version Log — Daily Journal

## [1.2.0] — Planned (Publishing Phase)
**Goal:** Distribute the app to testers and the public via Google Play Store.

### Upcoming Changes
- **Dist:** Google Play Console app record creation.
- **Dist:** Internal testing track rollout.
- **Comp:** Health Connect Data Safety and Privacy declarations.
- **Build:** First official release bundle submission.

---

## [1.1.0] "Fourvel" — 2026-05-01 (Released)
**Goal:** Security hardening, privacy refinements, and architectural cleanup.

### Release Notes (Play Console)
- Biometric + PIN authentication with brute-force lockout protection
- Encrypted local database (SQLCipher) — your data never leaves your device
- Health Connect integration for automatic steps, sleep, and heart rate tracking
- NLP-powered keyword extraction and auto-tagging for journal entries
- Screenshot and task-switcher blocking for privacy
- Sensitive term filtering to prevent private data in tag clouds
- All storage AES-256 encrypted on-device

### Security & Privacy
- **Feature:** PIN brute-force protection (lockout timers up to 5 min).
- **Privacy:** NLP Sensitive-term blacklist to prevent private nouns from leaking into tag clouds.
- **Privacy:** Completely removed "Top Keywords" from Statistics dashboard.
- **Refactor:** Renamed `xanax` tracker to generic `x` metric across DB and UI.

### UX & Architecture
- **Feature:** Daily Noon reminders via local notifications.
- **UI:** Decoupled check-in wizard from entry creation (Manual "Add Details" button).
- **UI:** Added empty-state prompts to encourage manual check-ins.
- **Cleanup:** Dropped legacy `clouds` and `bubs` columns from the SQLCipher database.

---

## [1.0.0] — 2026-04-17 (Alpha)
**Goal:** Initial functional prototype.

### Core Features
- **Auth:** Biometric + PIN authentication.
- **Persistence:** SQLCipher encrypted local database.
- **Sync:** Health Connect integration (Steps, Sleep, Heart Rate).
- **Intelligence:** RAKE algorithm for automatic keyword extraction/tagging.
- **Editor:** Markdown-based journal editor.
- **Wizard:** 7-point health & mood questionnaire.
