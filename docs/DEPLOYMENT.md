# Deploying Padel Partner to Google Play & the App Store

The workflow `.github/workflows/release.yml` builds a **signed Android App Bundle** and a
**signed iOS IPA**, then uploads them to **Google Play (internal testing)** and
**TestFlight**. From there you promote/submit the build in each store console.

It runs when you push a tag like `v1.0.0`, or manually from
**GitHub → Actions → Release to stores → Run workflow** (choose `both` / `android` / `ios`).

You need a few one-time things configured first. Do the steps in order and tick them off.

> **Commands below**: shown for Git Bash / macOS / Linux. On Windows use **Git Bash**
> (comes with Git for Windows) — it includes `openssl` and `base64`.
> `keytool` ships with Android Studio's JDK (`C:\Program Files\Android\Android Studio\jbr\bin`).

---

## Part 0 — Accounts

### Step 1. Developer accounts
- [ ] **Google Play Console** — https://play.google.com/console (US$25 one-time).
- [ ] **Apple Developer Program** — https://developer.apple.com/programs (US$99/year).
  Enrol as an *Organization* if the app should be published under a company name (needs a D-U-N-S number).

> New **personal** Play accounts must run a *closed test with at least 12 testers for 14 days*
> before they can publish to production. Organization accounts are exempt.

---

## Part 1 — Android / Google Play

### Step 2. Create the upload keystore (once, keep it forever)
```bash
keytool -genkey -v -keystore upload-keystore.jks -storetype JKS \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
Write down the **keystore password**, the **key password** (can be the same) and the alias (`upload`).
Store the `.jks` and passwords in a password manager. **Do not commit it** (`*.jks` is git-ignored).
Avoid `\` in the passwords (it breaks `key.properties`).

*Optional, for local release builds:* create `android/key.properties`:
```properties
storeFile=/absolute/path/to/upload-keystore.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

### Step 3. Add the Android signing secrets to GitHub
GitHub repo → **Settings → Secrets and variables → Actions → New repository secret**

| Secret | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | output of `base64 -w0 upload-keystore.jks` (macOS: `base64 -i upload-keystore.jks`) |
| `ANDROID_KEYSTORE_PASSWORD` | keystore password |
| `ANDROID_KEY_ALIAS` | `upload` |
| `ANDROID_KEY_PASSWORD` | key password |

### Step 4. Create the app in Play Console
1. Play Console → **Create app** → name *Padel Partner*, App, Free/Paid, accept declarations.
2. Go through **Dashboard → Set up your app**: privacy policy URL, app access (give reviewers a
   test phone number + OTP — add one under Firebase → Authentication → Sign-in method → Phone →
   *Phone numbers for testing*), ads, content rating, target audience, **data safety**, government
   apps, financial features, health.
3. **Play App Signing** is on by default — keep it (Google holds the app signing key, your keystore is
   only the *upload* key).

### Step 5. Upload the very first build by hand
The Play API can't upload to an app that has never had a build, so the first one is manual:
1. GitHub → Actions → **Release to stores** → Run workflow → platform **android**.
   The *Upload to Google Play* step will fail this first time — that's expected.
2. Open the run → **Artifacts** → download `android-aab-<n>` → unzip `app-release.aab`.
3. Play Console → **Testing → Internal testing → Create new release** → upload the `.aab` →
   save → roll out to internal testers (add your testers' emails under the *Testers* tab).

### Step 6. Give GitHub access to Play (service account)
1. https://console.cloud.google.com → select/create a project → **APIs & Services → Library** →
   enable **Google Play Android Developer API**.
2. **IAM & Admin → Service accounts → Create service account** (e.g. `github-play-upload`), no roles needed.
3. Open it → **Keys → Add key → Create new key → JSON** → a `.json` file downloads.
4. Play Console → **Users and permissions → Invite new users** → paste the service account's email
   (`...@...iam.gserviceaccount.com`) → **App permissions → Add app → Padel Partner** → tick
   *Release apps to testing tracks* (and *Release to production…* if you want CI to publish to
   production) → Invite.
5. Add GitHub secret `PLAY_SERVICE_ACCOUNT_JSON` = **entire contents** of the JSON file.

> Permissions can take up to ~24h to propagate. If uploads fail with *"The caller does not have
> permission"*, wait and retry.

### Step 7. Release status variable
GitHub → Settings → Secrets and variables → Actions → **Variables** tab:
- Leave `PLAY_RELEASE_STATUS` unset (= `draft`) while the app has never been published — Play only accepts
  draft releases for draft apps. You'll then click *Roll out* in Play Console.
- After your first release is reviewed and live, set `PLAY_RELEASE_STATUS` = `completed` so CI
  rolls out automatically.
- Optional: `PLAY_TRACK` (default `internal`).

✅ Android done. Re-run the workflow with platform `android` and check the build appears in Play Console.

---

## Part 2 — iOS / App Store

### Step 8. Add the iOS app to Firebase  *(the iOS app can't use Firebase without this)*
`lib/firebase_options.dart` currently only has Android + Web. On your machine:
```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=padelpartner-74b7d --platforms=android,ios,web \
  --ios-bundle-id=com.padelpartner.app
```
Commit the updated `lib/firebase_options.dart`.

For **phone auth on iOS** also:
- Firebase → Project settings → Cloud Messaging → upload an **APNs auth key** (Apple Developer →
  Keys → + → *Apple Push Notifications service*).
- Add the *Encoded App ID* from Firebase (iOS app settings, looks like `app-1-97454348674-ios-...`)
  as a URL scheme in `ios/Runner/Info.plist` under `CFBundleURLTypes` (reCAPTCHA fallback).

### Step 9. Google Maps key for iOS
`ios/Runner/AppDelegate.swift` still has `GMSServices.provideAPIKey("YOUR_API_KEY")`. Create a key
restricted to *Maps SDK for iOS* + bundle ID `com.padelpartner.app` in Google Cloud and paste it in.

### Step 10. Register the App ID
https://developer.apple.com/account → **Certificates, IDs & Profiles → Identifiers → +** →
App IDs → App → Description *Padel Partner*, **Bundle ID (Explicit)** `com.padelpartner.app`.
Enable capabilities: **Push Notifications** (phone auth), **In-App Purchase** (on by default),
**Associated Domains** if you later add universal links. Save.

Also note your **Team ID** (top-right of the developer portal, 10 characters) — you don't need it as a
secret, the workflow reads it from the provisioning profile.

### Step 11. Create the app in App Store Connect
https://appstoreconnect.apple.com → **Apps → + → New App** → iOS, name *Padel Partner*,
language, Bundle ID `com.padelpartner.app`, SKU (e.g. `padelpartner`), Full Access.

### Step 12. Create the Apple Distribution certificate (.p12)
No Mac needed — do it with `openssl` in Git Bash:
```bash
# 1. private key + certificate signing request
openssl genrsa -out dist.key 2048
openssl req -new -key dist.key -out dist.csr \
  -subj "/emailAddress=you@example.com/CN=Padel Partner/C=PK"
```
2. Developer portal → **Certificates → + → Apple Distribution** → upload `dist.csr` → download
   `distribution.cer`.
```bash
# 3. convert to .p12 (the -legacy algorithms are required for macOS keychains)
openssl x509 -in distribution.cer -inform DER -out dist.pem
openssl pkcs12 -export -legacy -inkey dist.key -in dist.pem -out dist.p12 -password pass:CHOOSE_A_PASSWORD
```
(If your openssl says `-legacy` is unknown, it's OpenSSL 1.x — just drop the flag.)
Keep `dist.key` / `dist.p12` safe; Apple allows only a few distribution certs per team.

*If you have a Mac:* Xcode → Settings → Accounts → Manage Certificates → + Apple Distribution, then
Keychain Access → right-click the cert → Export → `.p12`.

### Step 13. Create the App Store provisioning profile
Developer portal → **Profiles → + → Distribution → App Store Connect** → App ID
`com.padelpartner.app` → select the certificate from Step 12 → name it e.g.
*Padel Partner App Store* → download the `.mobileprovision`.

> When the certificate expires (1 year) or you add capabilities, regenerate the profile and
> update the secret.

### Step 14. Create an App Store Connect API key (for uploading)
App Store Connect → **Users and Access → Integrations → App Store Connect API → Team Keys → +** →
name `github-actions`, access **App Manager** → Generate.
- Download the `AuthKey_XXXXXXXXXX.p8` (**only downloadable once**).
- Note the **Key ID** and the **Issuer ID** (shown above the keys table).

### Step 15. Add the iOS secrets to GitHub

| Secret | Value |
|---|---|
| `IOS_DIST_CERT_P12_BASE64` | `base64 -w0 dist.p12` |
| `IOS_DIST_CERT_PASSWORD` | the password you used in Step 12 |
| `IOS_PROVISIONING_PROFILE_BASE64` | `base64 -w0 Padel_Partner_App_Store.mobileprovision` |
| `APP_STORE_CONNECT_KEY_ID` | Key ID from Step 14 |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID from Step 14 |
| `APP_STORE_CONNECT_KEY_P8_BASE64` | `base64 -w0 AuthKey_XXXXXXXXXX.p8` |

✅ iOS done. Run the workflow with platform `ios`. After ~10–30 min of processing the build appears in
App Store Connect → TestFlight.

---

## Part 3 — Shipping a release

### Step 16. Cut a release
1. Bump the version name in `pubspec.yaml` (`version: 1.0.1+1` — the `+1` part is ignored by CI;
   the build number comes from the workflow run number).
2. Commit, then:
   ```bash
   git tag v1.0.1
   git push origin v1.0.1
   ```
   …or run the workflow manually from the Actions tab.
3. **Android**: Play Console → Internal testing → check the release → **Promote release →
   Closed/Open testing or Production** → submit for review.
4. **iOS**: App Store Connect → your app → **+ Version** (same version name) → fill in screenshots,
   description, keywords, support URL, privacy policy, *App Privacy* questionnaire, **sign-in info for
   the reviewer** (test phone number + OTP) → select the TestFlight build → **Submit for Review**.
   Export-compliance is pre-answered (`ITSAppUsesNonExemptEncryption = false` in `Info.plist`).

### Build numbers
Both stores need an ever-increasing build number. The workflow uses the GitHub run number.
If you previously uploaded builds by hand with a higher number, set the repo **variable**
`BUILD_NUMBER_OFFSET` (e.g. `100`). If only one platform fails, use **Re-run failed jobs** (not
*Re-run all jobs*) so the successful store doesn't get a duplicate number.

---

## Store review checklist (common rejection reasons)
- [ ] **Account deletion** inside the app (required by both Apple and Google for apps with sign-up).
- [ ] Privacy policy URL (both stores) and the Data safety / App Privacy forms.
- [ ] Reviewer test login (Firebase test phone number).
- [ ] In-app subscriptions created in **both** Play Console (Monetize → Subscriptions) and App Store
      Connect (Subscriptions), with matching product IDs used by `in_app_purchase`.
- [ ] Screenshots: iPhone 6.9" (and iPad if the app supports iPad), Android phone; Play feature graphic 1024×500.
- [ ] Location / photo permission prompts explain *why* (strings are in `ios/Runner/Info.plist`).

## Secrets & variables summary

| Name | Type | Used for |
|---|---|---|
| `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` | secret | signing the AAB |
| `PLAY_SERVICE_ACCOUNT_JSON` | secret | uploading to Google Play |
| `IOS_DIST_CERT_P12_BASE64`, `IOS_DIST_CERT_PASSWORD`, `IOS_PROVISIONING_PROFILE_BASE64` | secret | signing the IPA |
| `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_KEY_P8_BASE64` | secret | uploading to TestFlight |
| `PLAY_RELEASE_STATUS` | variable | `draft` (default) → `completed` after first publish |
| `PLAY_TRACK` | variable | default Play track for tag builds (`internal`) |
| `BUILD_NUMBER_OFFSET` | variable | added to the run number |
