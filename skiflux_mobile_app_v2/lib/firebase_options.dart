// Hand-written from the throwaway Firebase project configs
// (`android/app/google-services.json` + `ios/Runner/GoogleService-Info.plist`).
// `flutterfire configure` was not used (no interactive Firebase login in CI /
// agent environments). Swapping the real Firebase project later means:
// replace those two config files and regenerate / rewrite this file — nothing
// else in the FCM layer is project-specific.
//
// ignore_for_file: lines_longer_than_80_chars

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for the current platform.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
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

  /// Android — package `com.skiflux.skiflux_mobile_app_v2`
  /// (must match `applicationId` in android/app/build.gradle.kts).
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA3PdV7Pfd5cO_y7sr6sBLklwLvnqXAuNw',
    appId: '1:829997105528:android:de1834a1995601e4e7088d',
    messagingSenderId: '829997105528',
    projectId: 'skiflux-fcm-test',
    storageBucket: 'skiflux-fcm-test.firebasestorage.app',
  );

  /// iOS — bundle `com.skiflux.skifluxMobileAppV2`
  /// (must match PRODUCT_BUNDLE_IDENTIFIER in the Xcode project).
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAVKofwTuCtumEyF0guFfu6vQdR9NzVe3g',
    appId: '1:829997105528:ios:97688cca289b33f6e7088d',
    messagingSenderId: '829997105528',
    projectId: 'skiflux-fcm-test',
    storageBucket: 'skiflux-fcm-test.firebasestorage.app',
    iosBundleId: 'com.skiflux.skifluxMobileAppV2',
  );
}
