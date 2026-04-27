# Padel Partner — Flutter Setup Guide

## Prerequisites
- Flutter SDK 3.3+ installed (https://flutter.dev/docs/get-started/install)
- Android Studio or Xcode (for device builds)

## Quick start

```bash
cd padel_partner
flutter pub get
flutter run
```

> Firebase is commented out in `main.dart` so the app runs immediately without credentials.

---

## Firebase setup (required for real OTP auth + Firestore)

1. Go to https://console.firebase.google.com → Add project → link your Google Cloud project
2. **Android**: Add app → package `com.padelpartner.app` → download `google-services.json` → place in `android/app/`
3. **iOS**: Add app → bundle ID `com.padelpartner.app` → download `GoogleService-Info.plist` → place in `ios/Runner/`
4. Enable **Authentication → Phone** in Firebase console
5. Enable **Firestore Database** (start in test mode)
6. Enable **Storage**
7. Install FlutterFire CLI and regenerate options:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --project=padelpartner-74b7d
   ```
8. In `lib/main.dart`, uncomment:
   ```dart
   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
   Get.put(AuthController(), permanent: true);
   ```
AdrTqXF8-CYYskrob-aM71_aHCoLs_Vgez4NYHhDBXuTsFoYIGXAHlDVPVFDNLNoKvCZM_IJmsBzJt_z_bz_Z3f4hqTscETEktkgnZWr39qo5eE0yQvNQpAcP3LxsOkX5-nhhTW3lyN-LRq8sQ7-aWkf
---

## Google Maps setup (host pin picker)

1. Enable **Maps SDK for Android** and **Maps SDK for iOS** in Google Cloud Console
2. Create an API key → restrict it to your app
3. **Android**: add to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR_KEY"/>
   ```
4. **iOS**: add to `ios/Runner/AppDelegate.swift`:
   ```swift
   GMSServices.provideAPIKey("YOUR_KEY")
   ```

---

## Android `build.gradle` requirements

`android/app/build.gradle`:
```gradle
android {
    compileSdkVersion 34
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

`android/build.gradle`:
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.2'
    }
}
```

`android/app/build.gradle` (bottom):
```gradle
apply plugin: 'com.google.gms.google-services'
```

---

## Screens built so far
- [x] Sign Up (4-step: info → OTP → profile → smart tags)
- [x] Home (next response)
- [x] Browse, Detail, Host, Requests, Join, Inbox, Chat, Friends, Profile, Subscription, Match Finished
