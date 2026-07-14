import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'FirebaseOptions are not configured for this platform. '
          'Configure Firebase using the FlutterFire CLI.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAMlZuf9q3QwZjjhk1mTyGP6B_8KvtbaQE',
    authDomain: 'expense-84f73.firebaseapp.com',
    projectId: 'expense-84f73',
    storageBucket: 'expense-84f73.firebasestorage.app',
    messagingSenderId: '895551835032',
    appId: '1:895551835032:web:42b54d16055c4ae7a639ed',
    measurementId: 'G-CC04L48VQL',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC8riw0pHUYdWFgjHRi8G0G-510Wcacufw',
    appId: '1:895551835032:android:42fb13a9d3658a5ea639ed',
    messagingSenderId: '895551835032',
    projectId: 'expense-84f73',
    storageBucket: 'expense-84f73.firebasestorage.app',
  );

  static FirebaseOptions get ios => throw UnsupportedError(
        'Firebase for iOS is not configured yet. '
        'On macOS, run the FlutterFire CLI (flutterfire configure) '
        'and add ios/Runner/GoogleService-Info.plist for your iOS bundle id.',
      );

  static FirebaseOptions get macos => throw UnsupportedError(
        'Firebase for macOS is not configured yet. '
        'Configure Firebase using the FlutterFire CLI (flutterfire configure).',
      );
}

