# Publishing Expense Tracker to Google Play

## App identity (done in code)
- **Application ID:** `com.azminds.expensetracker` (permanent — never changes after first release)
- **App name:** Expense Tracker
- **Signing:** release builds are signed with the upload keystore via `android/key.properties`

## Your upload keystore — BACK THIS UP
- File: `android/app/upload-keystore.jks`
- Config: `android/key.properties` (alias `upload`)
- Both are **git-ignored** and must never be committed or shared.
- The password was shown once in the terminal when generated — store it in a
  password manager. **If you lose the keystore or password, you can never update
  the app on Play again.** Copy `upload-keystore.jks` + the password somewhere safe
  (password manager / encrypted backup).

### SHA fingerprints of the upload key (needed for Firebase)
```
SHA1:   5C:8A:CE:FD:1E:BD:26:3E:65:69:88:E1:ED:F4:AA:92:6A:50:BC:F4
SHA256: 9C:D5:D6:D9:59:F0:E0:FF:96:94:5B:21:8A:17:A4:CA:00:50:92:C1:E6:72:6E:40:9E:1D:3B:45:33:26:0F:8A
```
Re-print anytime with:
```
keytool -list -v -keystore android/app/upload-keystore.jks -alias upload
```

## ⚠️ Firebase: register the new package (do this or auth may break)
The app's package changed from `com.example.expense_tracker` to
`com.azminds.expensetracker`. Firebase was set up for the old package, so:

1. [Firebase console](https://console.firebase.google.com) → project `expense-84f73`
   → ⚙️ **Project settings** → **Your apps** → **Add app → Android**.
2. Package name: `com.azminds.expensetracker`.
3. Add the **SHA-1 and SHA-256** above.
4. After you first upload to Play and enable **Play App Signing**, Play shows an
   *app signing* SHA-1/SHA-256 too — add **those** to Firebase as well (needed so
   the production-signed app is trusted).
5. Regenerate the Firebase config so the app targets the new package:
   ```
   dart pub global activate flutterfire_cli
   flutterfire configure --project=expense-84f73
   ```
   This rewrites `lib/firebase_options.dart`. Rebuild afterward.

> If you skip this and email/password sign-in stops working under the new
> package, this is why. (It may keep working if the Firebase API key is
> unrestricted, but registering the package is the correct, safe path.)

## Build the release App Bundle
```
flutter build appbundle --release
# -> build/app/outputs/bundle/release/app-release.aab
```
Each new upload needs a higher `versionCode` (bump `version: 1.0.0+1` in
`pubspec.yaml`, e.g. `1.0.1+2`).

## Google Play Console
1. **Create a developer account** ($25 one-time) at play.google.com/console;
   complete identity verification.
2. **Create app** → fill name, default language, app/game, free/paid.
3. **App access:** the app requires login — provide a **test email + password**
   so reviewers can sign in, or they'll reject it.
4. **Data safety** form — declare: email, name, financial info (expenses),
   photos (receipts); encrypted in transit; used for app functionality.
5. **Content rating** questionnaire (Finance app).
6. **Privacy policy URL** (required) — must mention Firebase, stored data, email.
7. **Store listing:** short description (80 chars), full description (4000),
   app icon 512×512, feature graphic 1024×500, ≥2 phone screenshots, category
   Finance, contact email.
8. **Release:** upload the `.aab` to **Internal testing** first → test →
   promote to **Production**. Enable **Play App Signing** when prompted.

## Store listing copy (starter — edit freely)
**Short:** Track expenses & income by category with clean, interactive analytics.

**Full:** Expense Tracker helps you stay on top of your money. Organize spending
into books, log expenses and income by category (or create your own), attach
receipts, and understand where your money goes with interactive doughnut, radial,
and bar charts. Connect with people to share books, and export to CSV or PDF.

## Notes
- Target SDK is set by Flutter (`flutter.targetSdkVersion`) and meets Play's
  current requirement.
- Kotlin is 1.8.22; Flutter warns it will drop support — bump to 2.1.0+ in
  `android/settings.gradle` in a future update (not required to publish today).
- The email backend (server/) runs on Vercel free tier and cold-starts after
  idle — fine for this app; emails are best-effort and never block the app.
