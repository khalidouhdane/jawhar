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
    // App id for package com.alphafoundr.jawhar (android/app/google-services.json).
    appId: '1:556087735735:android:a1c43ec23234162a512432',
    messagingSenderId: '556087735735',
    projectId: 'quran-app-e5e86',
    storageBucket: 'quran-app-e5e86.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyACA_NHJ2n97-9tCU7Ak4AWurfOn8jXNkg',
    // App id for bundle com.alphafoundr.jawhar (ios/Runner/GoogleService-Info.plist).
    appId: '1:556087735735:ios:037b986fb8d026f1512432',
    messagingSenderId: '556087735735',
    projectId: 'quran-app-e5e86',
    storageBucket: 'quran-app-e5e86.firebasestorage.app',
    iosClientId:
        '556087735735-jq248nagiqu2deprh6hb7dm5k6hglo5a.apps.googleusercontent.com',
    iosBundleId: 'com.alphafoundr.jawhar',
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
