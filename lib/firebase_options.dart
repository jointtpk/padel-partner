// Firebase project: padelpartner-74b7d
// Only Android is configured. iOS/web/macOS get an UnsupportedError until
// those platforms are registered in Firebase and we run `flutterfire configure`.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Firebase web options not configured. Add a Web app in Firebase '
        "console and run 'flutterfire configure' to regenerate this file.",
      );
    }
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
}
