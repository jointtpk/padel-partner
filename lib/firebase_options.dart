// Firebase project: padelpartner-74b7d
// Configured platforms: Android, Web. iOS/macOS get an UnsupportedError until
// those platforms are registered in Firebase and we run `flutterfire configure`.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'Firebase options for ${defaultTargetPlatform.name} not configured.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD08nrT7bqQR8hMeDu3VycoSgOc6W7J5V0',
    appId: '1:97454348674:android:6f8276b122bb6c2901979b',
    messagingSenderId: '97454348674',
    projectId: 'padelpartner-74b7d',
    storageBucket: 'padelpartner-74b7d.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDqpeIs8Hp3h_ZOsun8zMEBaRvFaBxRd8A',
    appId: '1:97454348674:web:234ebf47d0c34c3301979b',
    messagingSenderId: '97454348674',
    projectId: 'padelpartner-74b7d',
    authDomain: 'padelpartner-74b7d.firebaseapp.com',
    storageBucket: 'padelpartner-74b7d.firebasestorage.app',
    measurementId: 'G-BMSQQBTNKT',
  );
}
