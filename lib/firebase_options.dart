// ─────────────────────────────────────────────────────────────────────────────
// FIREBASE SETUP INSTRUCTIONS
// ─────────────────────────────────────────────────────────────────────────────
// 1. Go to https://console.firebase.google.com
// 2. Click "Add project" and connect your existing Google Cloud project
// 3. In your new Firebase project:
//    a. Add Android app → package name: com.padelpartner.app
//       Download google-services.json → place in android/app/
//    b. Add iOS app → bundle ID: com.padelpartner.app
//       Download GoogleService-Info.plist → place in ios/Runner/
// 4. Enable Authentication → Phone
// 5. Enable Firestore Database → Start in test mode
// 6. Enable Storage
// 7. Run: dart pub global activate flutterfire_cli
//         flutterfire configure --project=YOUR_PROJECT_ID
//    This regenerates this file with real values.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web not supported');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Platform not supported');
    }
  }

  // ⚠️  Replace these placeholder values after running `flutterfire configure`
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_WITH_YOUR_ANDROID_API_KEY',
    appId: 'REPLACE_WITH_YOUR_ANDROID_APP_ID',
    messagingSenderId: 'REPLACE_WITH_YOUR_SENDER_ID',
    projectId: 'REPLACE_WITH_YOUR_PROJECT_ID',
    storageBucket: 'REPLACE_WITH_YOUR_STORAGE_BUCKET',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_YOUR_IOS_API_KEY',
    appId: 'REPLACE_WITH_YOUR_IOS_APP_ID',
    messagingSenderId: 'REPLACE_WITH_YOUR_SENDER_ID',
    projectId: 'REPLACE_WITH_YOUR_PROJECT_ID',
    storageBucket: 'REPLACE_WITH_YOUR_STORAGE_BUCKET',
    iosBundleId: 'com.padelpartner.app',
  );
}
