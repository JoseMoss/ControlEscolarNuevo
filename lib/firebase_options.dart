// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, kIsWeb, defaultTargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Configuración directa de tu proyecto web extraída de Firebase
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC785aD1KCzMCb_HIeMfP_WeKo6a_SWYFI',
    appId: '1:964880821766:web:c27f37291ef992ae4a5d87',
    messagingSenderId: '964880821766',
    projectId: 'controlescolarcean',
    authDomain: 'controlescolarcean.firebaseapp.com',
    storageBucket: 'controlescolarcean.firebasestorage.app',
  );

  // Configuración de respaldo para Android por si compilas la app para celular después
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC785aD1KCzMCb_HIeMfP_WeKo6a_SWYFI',
    appId: '1:964880821766:web:c27f37291ef992ae4a5d87',
    messagingSenderId: '964880821766',
    projectId: 'controlescolarcean',
    storageBucket: 'controlescolarcean.firebasestorage.app',
  );
}
