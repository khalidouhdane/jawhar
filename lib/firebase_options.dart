// File generated manually from Firebase CLI output.
// Project: quran-app-e5e86

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.macOS:
        return ios;
      case TargetPlatform.linux:
        return web;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for '
          '${defaultTargetPlatform.name}',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD9d4HJfmx3fGPto0L0zbQT3GHGJ8ecy40',
    appId: '1:556087735735:android:b3d8266d65b5c7d5512432',
    messagingSenderId: '556087735735',
    projectId: 'quran-app-e5e86',
    storageBucket: 'quran-app-e5e86.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD9d4HJfmx3fGPto0L0zbQT3GHGJ8ecy40',
    appId: '1:556087735735:ios:0bdf1c97c5c7c739512432',
    messagingSenderId: '556087735735',
    projectId: 'quran-app-e5e86',
    storageBucket: 'quran-app-e5e86.firebasestorage.app',
    iosBundleId: 'com.memorize.quran.ai',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB63YyajLgGR7cttpCX0a0yVHN6sRdO7VA',
    appId: '1:556087735735:web:7d4343db91fa4bc9512432',
    messagingSenderId: '556087735735',
    projectId: 'quran-app-e5e86',
    authDomain: 'quran-app-e5e86.firebaseapp.com',
    storageBucket: 'quran-app-e5e86.firebasestorage.app',
    measurementId: 'G-Z4K6WLM711',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyB63YyajLgGR7cttpCX0a0yVHN6sRdO7VA',
    appId: '1:556087735735:web:0d65dbabe62b74cf512432',
    messagingSenderId: '556087735735',
    projectId: 'quran-app-e5e86',
    authDomain: 'quran-app-e5e86.firebaseapp.com',
    storageBucket: 'quran-app-e5e86.firebasestorage.app',
    measurementId: 'G-BMY10WY6K5',
  );
}
