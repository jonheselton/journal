# TODO

## Remaining Manual Steps

- [ ] **Host privacy policy** at a public URL (GitHub Pages, static site, etc.)
- [ ] **Register Google Play Developer account** ($25 fee) at [play.google.com/console](https://play.google.com/console)
- [ ] **Build release AAB:** `flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info`
- [ ] **Submit to Play Console** — follow `store/developer_account_guide.md`
- [ ] **Complete Health Connect declaration** — follow `store/health_connect_declaration.md`
- [ ] Test on a real device with Health Connect installed

## Completed ✅

- [x] Health Connect integration (steps, heart rate, sleep)
- [x] Per-day storage with timezone tracking
- [x] Bubs wizard field
- [x] Signing config (release keystore support + ProGuard)
- [x] App ID changed to `io.gencan.dailyjournal`
- [x] App name "Daily Journal"
- [x] Privacy policy created
- [x] PIN fallback authentication
- [x] FLAG_SECURE (screenshot protection)
- [x] Re-lock on app resume
- [x] `allowBackup=false`
- [x] Dead code cleanup
- [x] Store listing text + images
- [x] Generate keystore (`upload-keystore.jks` exists)
- [x] Create `android/key.properties` from example
- [x] Update privacy policy email (google@gencan.io)
- [x] SQLCipher encrypted database (AES-256 + Android Keystore)
- [x] Data models: DayEntry, Metrics, DayMetrics, Tags
- [x] Database migration from flutter_secure_storage
- [x] Element metrics (Air, Earth, Wind, Fire) with sliders
- [x] Local NLP keyword extraction (RAKE algorithm)
- [x] Statistics screen with averages + tag cloud
- [x] Privacy policy updated for SQLCipher + NLP disclosure
