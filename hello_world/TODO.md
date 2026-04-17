# TODO

## Remaining Manual Steps

- [ ] **Generate keystore:** `keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
- [ ] **Create `android/key.properties`** from `key.properties.example` with your keystore credentials
- [ ] **Host privacy policy** at a public URL (GitHub Pages, static site, etc.)
- [ ] **Update privacy policy email** in `store/privacy_policy.html` (replace `[YOUR_EMAIL]`)
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
