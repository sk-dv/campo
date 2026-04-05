import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('DefaultFirebaseOptions no está configurado para esta plataforma.');
    }
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAVeqOJJR0CnPmQPv7hgx-6_oE-rwtgWuo',
    appId: '1:29107205159:ios:b9b9ff9d86813d40a3ca02',
    messagingSenderId: '29107205159',
    projectId: 'campo-28b5b',
    storageBucket: 'campo-28b5b.firebasestorage.app',
    iosBundleId: 'io.campo',
  );
}
