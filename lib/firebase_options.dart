import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBO_29MdZV7XPyGf1jaugezMS8klUvHkq8',
    authDomain: 'celron-pmr.firebaseapp.com',
    projectId: 'celron-pmr',
    storageBucket: 'celron-pmr.firebasestorage.app',
    messagingSenderId: '591771362863',
    appId: '1:591771362863:web:a66ff696e246c907e0c8da',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBO_29MdZV7XPyGf1jaugezMS8klUvHkq8',
    appId: '1:591771362863:android:YOUR_ANDROID_APP_ID', // User still needs to get this from google-services.json
    messagingSenderId: '591771362863',
    projectId: 'celron-pmr',
    storageBucket: 'celron-pmr.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBO_29MdZV7XPyGf1jaugezMS8klUvHkq8',
    appId: '1:591771362863:ios:YOUR_IOS_APP_ID', // User still needs to get this from GoogleService-Info.plist
    messagingSenderId: '591771362863',
    projectId: 'celron-pmr',
    storageBucket: 'celron-pmr.firebasestorage.app',
    iosBundleId: 'com.celron.pmr',
  );
}
